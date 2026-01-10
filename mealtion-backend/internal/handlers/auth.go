package handlers

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"errors"
	"net/http"
	"os"
	"time"

	"mealtion-backend/internal/middleware"
	"mealtion-backend/internal/models"

	"github.com/golang-jwt/jwt/v5"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"golang.org/x/crypto/bcrypt"
)

// Token expiration durations
const (
	AccessTokenExpiry  = 15 * time.Minute // 15 minutes
	RefreshTokenExpiry = 7 * 24 * time.Hour // 7 days
)

// AuthInput represents request body for register/login.
type AuthInput struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name,omitempty"`
}

// RefreshInput represents request body for token refresh.
type RefreshInput struct {
	RefreshToken string `json:"refreshToken"`
}

// generateAccessToken creates a short-lived JWT access token
func generateAccessToken(userID string) (string, error) {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		return "", errors.New("JWT_SECRET not configured")
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"userId": userID,
		"type":   "access",
		"exp":    time.Now().Add(AccessTokenExpiry).Unix(),
	})

	return token.SignedString([]byte(secret))
}

// generateRefreshToken creates a secure random refresh token
func generateRefreshToken() (string, error) {
	bytes := make([]byte, 32)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

// hashToken creates a SHA256 hash of the token for storage
func hashToken(token string) string {
	hash := sha256.Sum256([]byte(token))
	return hex.EncodeToString(hash[:])
}

// storeRefreshToken saves the refresh token hash to the database
func (s *Server) storeRefreshToken(ctx context.Context, userID primitive.ObjectID, tokenHash string) error {
	refreshToken := models.RefreshToken{
		UserID:    userID,
		TokenHash: tokenHash,
		ExpiresAt: time.Now().Add(RefreshTokenExpiry),
		CreatedAt: time.Now().UTC(),
		Revoked:   false,
	}
	_, err := s.RefreshTokensCol.InsertOne(ctx, refreshToken)
	return err
}

// generateTokenPair creates both access and refresh tokens
func (s *Server) generateTokenPair(ctx context.Context, userID primitive.ObjectID) (accessToken, refreshToken string, err error) {
	accessToken, err = generateAccessToken(userID.Hex())
	if err != nil {
		return "", "", err
	}

	refreshToken, err = generateRefreshToken()
	if err != nil {
		return "", "", err
	}

	tokenHash := hashToken(refreshToken)
	if err := s.storeRefreshToken(ctx, userID, tokenHash); err != nil {
		return "", "", err
	}

	return accessToken, refreshToken, nil
}

// Register creates a new user and returns JWT token + user info (auto login).
func (s *Server) Register(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var in AuthInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	if in.Email == "" || in.Password == "" || in.Name == "" {
		http.Error(w, "missing fields", http.StatusBadRequest)
		return
	}

	// Hash password before storing
	hash, err := bcrypt.GenerateFromPassword([]byte(in.Password), 10)
	if err != nil {
		http.Error(w, "failed to hash password", http.StatusInternalServerError)
		return
	}

	user := models.User{
		Email:        in.Email,
		PasswordHash: string(hash),
		Name:         in.Name,
		CreatedAt:    time.Now().UTC(),
	}

	res, err := s.UsersCol.InsertOne(r.Context(), user)
	if err != nil {
		// Mongo duplicate key error code = 11000
		var we mongo.WriteException
		if errors.As(err, &we) {
			for _, e := range we.WriteErrors {
				if e.Code == 11000 {
					http.Error(w, "email already exists", http.StatusBadRequest)
					return
				}
			}
		}
		http.Error(w, "failed to create user", http.StatusInternalServerError)
		return
	}

	userID := res.InsertedID.(primitive.ObjectID)

	// Generate access + refresh token pair
	accessToken, refreshToken, err := s.generateTokenPair(r.Context(), userID)
	if err != nil {
		http.Error(w, "failed to generate tokens", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"accessToken":  accessToken,
		"refreshToken": refreshToken,
		"user": map[string]any{
			"id":    userID.Hex(),
			"email": user.Email,
			"name":  user.Name,
		},
	})
}

// Login verifies credentials and returns JWT token + user info.
func (s *Server) Login(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var in AuthInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	var user models.User
	if err := s.UsersCol.FindOne(r.Context(), bson.M{"email": in.Email}).Decode(&user); err != nil {
		http.Error(w, "invalid email or password", http.StatusUnauthorized)
		return
	}

	// Compare password hash
	if err := bcrypt.CompareHashAndPassword(
		[]byte(user.PasswordHash),
		[]byte(in.Password),
	); err != nil {
		http.Error(w, "invalid email or password", http.StatusUnauthorized)
		return
	}

	// Generate access + refresh token pair
	accessToken, refreshToken, err := s.generateTokenPair(r.Context(), user.ID)
	if err != nil {
		http.Error(w, "failed to generate tokens", http.StatusInternalServerError)
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]any{
		"accessToken":  accessToken,
		"refreshToken": refreshToken,
		"user": map[string]any{
			"id":    user.ID.Hex(),
			"email": user.Email,
			"name":  user.Name,
		},
	})
}

// Me returns current user profile based on JWT token.
func (s *Server) Me(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	userIDHex, ok := middleware.GetUserID(r)
	if !ok {
		http.Error(w, "unauthorized", http.StatusUnauthorized)
		return
	}

	uid, err := primitive.ObjectIDFromHex(userIDHex)
	if err != nil {
		http.Error(w, "invalid user id", http.StatusUnauthorized)
		return
	}

	var user models.User
	if err := s.UsersCol.FindOne(r.Context(), bson.M{"_id": uid}).Decode(&user); err != nil {
		http.Error(w, "user not found", http.StatusUnauthorized)
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]any{
		"user": map[string]any{
			"id":    user.ID.Hex(),
			"email": user.Email,
			"name":  user.Name,
		},
	})
}

// Refresh validates refresh token and returns new access + refresh token pair (token rotation).
func (s *Server) Refresh(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var in RefreshInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	if in.RefreshToken == "" {
		http.Error(w, "missing refresh token", http.StatusBadRequest)
		return
	}

	// Hash the provided token and look it up
	tokenHash := hashToken(in.RefreshToken)

	var storedToken models.RefreshToken
	err := s.RefreshTokensCol.FindOne(r.Context(), bson.M{
		"tokenHash": tokenHash,
		"revoked":   false,
	}).Decode(&storedToken)

	if err != nil {
		http.Error(w, "invalid refresh token", http.StatusUnauthorized)
		return
	}

	// Check if token is expired
	if time.Now().After(storedToken.ExpiresAt) {
		// Revoke the expired token
		_, _ = s.RefreshTokensCol.UpdateOne(r.Context(),
			bson.M{"_id": storedToken.ID},
			bson.M{"$set": bson.M{"revoked": true}},
		)
		http.Error(w, "refresh token expired", http.StatusUnauthorized)
		return
	}

	// Revoke the old refresh token (token rotation)
	_, err = s.RefreshTokensCol.UpdateOne(r.Context(),
		bson.M{"_id": storedToken.ID},
		bson.M{"$set": bson.M{"revoked": true}},
	)
	if err != nil {
		http.Error(w, "failed to rotate token", http.StatusInternalServerError)
		return
	}

	// Generate new token pair
	accessToken, refreshToken, err := s.generateTokenPair(r.Context(), storedToken.UserID)
	if err != nil {
		http.Error(w, "failed to generate tokens", http.StatusInternalServerError)
		return
	}

	// Get user info to include in response
	var user models.User
	if err := s.UsersCol.FindOne(r.Context(), bson.M{"_id": storedToken.UserID}).Decode(&user); err != nil {
		http.Error(w, "user not found", http.StatusUnauthorized)
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]any{
		"accessToken":  accessToken,
		"refreshToken": refreshToken,
		"user": map[string]any{
			"id":    user.ID.Hex(),
			"email": user.Email,
			"name":  user.Name,
		},
	})
}

// Logout revokes the refresh token.
func (s *Server) Logout(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	var in RefreshInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "invalid json", http.StatusBadRequest)
		return
	}

	if in.RefreshToken == "" {
		// No token to revoke, just return success
		w.WriteHeader(http.StatusOK)
		_ = json.NewEncoder(w).Encode(map[string]any{"message": "logged out"})
		return
	}

	// Hash and revoke the token
	tokenHash := hashToken(in.RefreshToken)
	_, _ = s.RefreshTokensCol.UpdateOne(r.Context(),
		bson.M{"tokenHash": tokenHash},
		bson.M{"$set": bson.M{"revoked": true}},
	)

	w.WriteHeader(http.StatusOK)
	_ = json.NewEncoder(w).Encode(map[string]any{"message": "logged out"})
}

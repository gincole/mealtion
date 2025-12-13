package handlers

import (
	"encoding/json"
	"net/http"
	"os"
	"time"
	"errors"

	"mealtion-backend/internal/middleware"
	"mealtion-backend/internal/models"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
)

// AuthInput represents request body for register/login.
type AuthInput struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name,omitempty"`
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

	// Create JWT token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"userId": userID.Hex(),
		"exp":    time.Now().Add(7 * 24 * time.Hour).Unix(),
	})

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		http.Error(w, "server misconfigured", http.StatusInternalServerError)
		return
	}

	tokenStr, err := token.SignedString([]byte(secret))
	if err != nil {
		http.Error(w, "failed to sign token", http.StatusInternalServerError)
		return
	}

	w.WriteHeader(http.StatusCreated)
	_ = json.NewEncoder(w).Encode(map[string]any{
		"token": tokenStr,
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

	// Create JWT token
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"userId": user.ID.Hex(),
		"exp":    time.Now().Add(7 * 24 * time.Hour).Unix(),
	})

	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		http.Error(w, "server misconfigured", http.StatusInternalServerError)
		return
	}

	tokenStr, err := token.SignedString([]byte(secret))
	if err != nil {
		http.Error(w, "failed to sign token", http.StatusInternalServerError)
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]any{
		"token": tokenStr,
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

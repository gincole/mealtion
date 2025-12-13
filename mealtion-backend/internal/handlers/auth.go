package handlers

import (
	"encoding/json"
	"net/http"
	"os"
	"time"

	"mealtion-backend/internal/models"

	"github.com/golang-jwt/jwt/v5"
	"golang.org/x/crypto/bcrypt"
	"go.mongodb.org/mongo-driver/bson"
)

type AuthInput struct {
	Email    string `json:"email"`
	Password string `json:"password"`
	Name     string `json:"name,omitempty"`
}

func (s *Server) Register(w http.ResponseWriter, r *http.Request) {
	var in AuthInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "invalid json", 400)
		return
	}

	if in.Email == "" || in.Password == "" || in.Name == "" {
		http.Error(w, "missing fields", 400)
		return
	}

	hash, _ := bcrypt.GenerateFromPassword([]byte(in.Password), 10)

	user := models.User{
		Email:        in.Email,
		PasswordHash: string(hash),
		Name:         in.Name,
		CreatedAt:    time.Now(),
	}

	_, err := s.UsersCol.InsertOne(r.Context(), user)
	if err != nil {
		http.Error(w, "email already exists", 400)
		return
	}

	w.WriteHeader(http.StatusCreated)
}

func (s *Server) Login(w http.ResponseWriter, r *http.Request) {
	var in AuthInput
	if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
		http.Error(w, "invalid json", 400)
		return
	}

	var user models.User
	err := s.UsersCol.FindOne(r.Context(), bson.M{"email": in.Email}).Decode(&user)
	if err != nil {
		http.Error(w, "invalid email or password", 401)
		return
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(in.Password)); err != nil {
		http.Error(w, "invalid email or password", 401)
		return
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"userId": user.ID.Hex(),
		"exp":    time.Now().Add(7 * 24 * time.Hour).Unix(),
	})

	secret := os.Getenv("JWT_SECRET")
	tokenStr, _ := token.SignedString([]byte(secret))

	_ = json.NewEncoder(w).Encode(map[string]any{
		"token": tokenStr,
		"user": map[string]any{
			"id":    user.ID.Hex(),
			"email": user.Email,
			"name":  user.Name,
		},
	})
}

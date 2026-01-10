package middleware

import (
	"context"
	"net/http"
	"os"
	"strings"

	"github.com/golang-jwt/jwt/v5"
)

type ctxKey string

const userIDKey ctxKey = "userId"

// GetUserID extracts userId from request context (set by auth middleware).
func GetUserID(r *http.Request) (string, bool) {
	v := r.Context().Value(userIDKey)
	id, ok := v.(string)
	return id, ok
}

// WithAuth verifies JWT access token from Authorization: Bearer <token> and injects userId into context.
// Only accepts access tokens (type: "access"), rejects refresh tokens.
func WithAuth(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		auth := r.Header.Get("Authorization")
		if auth == "" || !strings.HasPrefix(auth, "Bearer ") {
			http.Error(w, "missing bearer token", http.StatusUnauthorized)
			return
		}

		tokenStr := strings.TrimPrefix(auth, "Bearer ")
		secret := os.Getenv("JWT_SECRET")
		if secret == "" {
			http.Error(w, "server misconfigured", http.StatusInternalServerError)
			return
		}

		token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (any, error) {
			// Ensure HS256 (prevents alg=none / confusion attacks)
			if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
				return nil, jwt.ErrSignatureInvalid
			}
			return []byte(secret), nil
		})
		if err != nil || !token.Valid {
			http.Error(w, "invalid token", http.StatusUnauthorized)
			return
		}

		claims, ok := token.Claims.(jwt.MapClaims)
		if !ok {
			http.Error(w, "invalid token claims", http.StatusUnauthorized)
			return
		}

		// Verify this is an access token, not a refresh token
		tokenType, _ := claims["type"].(string)
		if tokenType != "access" {
			http.Error(w, "invalid token type", http.StatusUnauthorized)
			return
		}

		userID, ok := claims["userId"].(string)
		if !ok || userID == "" {
			http.Error(w, "missing userId in token", http.StatusUnauthorized)
			return
		}

		ctx := context.WithValue(r.Context(), userIDKey, userID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

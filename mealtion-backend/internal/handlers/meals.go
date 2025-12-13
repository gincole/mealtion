package handlers

import (
	"encoding/json"
	"net/http"
	"time"

	"mealtion-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
	"mealtion-backend/internal/middleware"
    "go.mongodb.org/mongo-driver/bson/primitive"
)

func (s *Server) Meals(w http.ResponseWriter, r *http.Request) {
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

	switch r.Method {
	case http.MethodGet:
		cur, err := s.MealsCol.Find(
		r.Context(),
		bson.M{"userId": uid}, // only this user's meals
		options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}}).SetLimit(20),
		)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		defer cur.Close(r.Context())

		var items []models.Meal
		if err := cur.All(r.Context(), &items); err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"items": items})

	case http.MethodPost:
		var in models.Meal
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
			http.Error(w, "invalid json", 400)
			return
		}
		if in.Title == "" || in.Date == "" || in.Time == "" || in.Status == "" {
		http.Error(w, "missing required fields: title/date/time/status", 400)
		return
		}

		in.UserID = uid              // set owner from token
		in.CreatedAt = time.Now().UTC()

		res, err := s.MealsCol.InsertOne(r.Context(), in)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"id": res.InsertedID})

	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

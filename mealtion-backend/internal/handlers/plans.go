package handlers

import (
	"encoding/json"
	"net/http"

	"mealtion-backend/internal/models"

	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
	"mealtion-backend/internal/middleware"
  	"go.mongodb.org/mongo-driver/bson/primitive"
)

func (s *Server) Plans(w http.ResponseWriter, r *http.Request) {
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
		date := r.URL.Query().Get("date")
		filter := bson.M{"userId": uid}
		if date != "" {
		filter["date"] = date
		}

		cur, err := s.PlansCol.Find(r.Context(), filter, options.Find().
		SetSort(bson.D{{Key: "date", Value: 1}}),
		)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		defer cur.Close(r.Context())

		var items []models.Plan
		if err := cur.All(r.Context(), &items); err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"items": items})

	case http.MethodPost:
		var in models.Plan
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
			http.Error(w, "invalid json", 400)
			return
		}
		if in.Title == "" || in.Date == "" || in.MealTime == "" || in.Status == "" {
			http.Error(w, "missing required fields: title/date/mealTime/status", 400)
			return
		}

		in.UserID = uid // set owner from token

		res, err := s.PlansCol.InsertOne(r.Context(), in)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}
		_ = json.NewEncoder(w).Encode(map[string]any{"id": res.InsertedID})

	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

// DeletePlan handles DELETE /plans/{id}
func (s *Server) DeletePlan(w http.ResponseWriter, r *http.Request) {
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

	vars := mux.Vars(r)
	planIDHex := vars["id"]
	planID, err := primitive.ObjectIDFromHex(planIDHex)
	if err != nil {
		http.Error(w, "invalid plan id", http.StatusBadRequest)
		return
	}

	// Only delete if plan belongs to user
	result, err := s.PlansCol.DeleteOne(r.Context(), bson.M{"_id": planID, "userId": uid})
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}

	if result.DeletedCount == 0 {
		http.Error(w, "plan not found or not owned by user", http.StatusNotFound)
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]any{"deleted": true})
}

package handlers

import (
	"encoding/json"
	"net/http"

	"mealtion-backend/internal/models"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo/options"
)

func (s *Server) Plans(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")

	switch r.Method {
	case http.MethodGet:
		date := r.URL.Query().Get("date")
		filter := bson.M{}
		if date != "" {
			filter["date"] = date
		}

		cur, err := s.PlansCol.Find(
			r.Context(),
			filter,
			options.Find().SetSort(bson.D{{Key: "date", Value: 1}}),
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

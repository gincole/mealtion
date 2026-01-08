package handlers

import (
	"encoding/base64"
	"encoding/json"
	"net/http"
	"strconv"
	"time"

	"mealtion-backend/internal/middleware"
	"mealtion-backend/internal/models"

	"github.com/gorilla/mux"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo/options"
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
		// Parse pagination parameters
		limit := int64(50) // default limit
		offset := int64(0) // default offset
		
		if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
			if parsed, err := strconv.ParseInt(limitStr, 10, 64); err == nil && parsed > 0 && parsed <= 100 {
				limit = parsed
			}
		}
		
		if offsetStr := r.URL.Query().Get("offset"); offsetStr != "" {
			if parsed, err := strconv.ParseInt(offsetStr, 10, 64); err == nil && parsed >= 0 {
				offset = parsed
			}
		}
		
		cur, err := s.MealsCol.Find(
			r.Context(),
			bson.M{"userId": uid}, // only this user's meals
			options.Find().SetSort(bson.D{{Key: "createdAt", Value: -1}}).SetLimit(limit).SetSkip(offset),
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
		// Limit request body to 10MB for image uploads
		r.Body = http.MaxBytesReader(w, r.Body, 10<<20)

		var in models.MealInput
		if err := json.NewDecoder(r.Body).Decode(&in); err != nil {
			http.Error(w, "invalid json or request too large", 400)
			return
		}
		if in.Title == "" || in.Date == "" || in.Time == "" || in.Status == "" {
			http.Error(w, "missing required fields: title/date/time/status", 400)
			return
		}

		meal := models.Meal{
			UserID:    uid,
			Title:     in.Title,
			Status:    in.Status,
			Date:      in.Date,
			Time:      in.Time,
			Location:  in.Location,
			CreatedAt: time.Now().UTC(),
		}

		// Handle base64 image if provided
		if in.ImageBase64 != "" {
			imageData, err := base64.StdEncoding.DecodeString(in.ImageBase64)
			if err != nil {
				http.Error(w, "invalid base64 image data", 400)
				return
			}
			meal.ImageData = imageData
			meal.ImageContentType = in.ImageContentType
			meal.HasImage = true
		}

		res, err := s.MealsCol.InsertOne(r.Context(), meal)
		if err != nil {
			http.Error(w, err.Error(), 500)
			return
		}

		insertedID := res.InsertedID.(primitive.ObjectID)
		meal.ID = insertedID
		meal.ImageData = nil // Don't return image data in response

		_ = json.NewEncoder(w).Encode(map[string]any{"id": insertedID, "meal": meal})

	default:
		http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
	}
}

// MealImage serves the raw image bytes for a meal
func (s *Server) MealImage(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	mealID := vars["id"]

	oid, err := primitive.ObjectIDFromHex(mealID)
	if err != nil {
		http.Error(w, "invalid meal id", http.StatusBadRequest)
		return
	}

	var meal models.Meal
	err = s.MealsCol.FindOne(r.Context(), bson.M{"_id": oid}).Decode(&meal)
	if err != nil {
		http.Error(w, "meal not found", http.StatusNotFound)
		return
	}

	if !meal.HasImage || len(meal.ImageData) == 0 {
		http.Error(w, "no image for this meal", http.StatusNotFound)
		return
	}

	contentType := meal.ImageContentType
	if contentType == "" {
		contentType = "image/jpeg"
	}

	w.Header().Set("Content-Type", contentType)
	w.Header().Set("Cache-Control", "public, max-age=86400")
	w.Write(meal.ImageData)
}

// DeleteMeal handles DELETE /meals/{id}
func (s *Server) DeleteMeal(w http.ResponseWriter, r *http.Request) {
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
	mealID := vars["id"]

	oid, err := primitive.ObjectIDFromHex(mealID)
	if err != nil {
		http.Error(w, "invalid meal id", http.StatusBadRequest)
		return
	}

	// Delete only if owned by user
	res, err := s.MealsCol.DeleteOne(r.Context(), bson.M{"_id": oid, "userId": uid})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	if res.DeletedCount == 0 {
		http.Error(w, "meal not found or not owned by user", http.StatusNotFound)
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]any{"deleted": true})
}

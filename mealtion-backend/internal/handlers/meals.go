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

		// Parse optional month/year filters
		monthFilter := 0
		yearFilter := 0
		if monthStr := r.URL.Query().Get("month"); monthStr != "" {
			if parsed, err := strconv.Atoi(monthStr); err == nil && parsed >= 1 && parsed <= 12 {
				monthFilter = parsed
			}
		}
		if yearStr := r.URL.Query().Get("year"); yearStr != "" {
			if parsed, err := strconv.Atoi(yearStr); err == nil && parsed > 0 {
				yearFilter = parsed
			}
		}

		// Build filter
		filter := bson.M{"userId": uid}
		
		// If month and year are provided, filter by date pattern
		if monthFilter > 0 && yearFilter > 0 {
			monthShorts := []string{"", "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"}
			// Match dates like "3 Dec 2025", "13 Dec 2025"
			pattern := " " + monthShorts[monthFilter] + " " + strconv.Itoa(yearFilter)
			filter["date"] = bson.M{"$regex": pattern, "$options": "i"}
		}
		
		cur, err := s.MealsCol.Find(
			r.Context(),
			filter, // use filter instead of bson.M{"userId": uid}
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

// MealCalendarEntry is a lightweight struct for calendar dots
type MealCalendarEntry struct {
	Date   string `json:"date"`
	Status string `json:"status"`
}

// MonthEntry represents a month-year combination with meal count
type MonthEntry struct {
	Month     int    `json:"month"`     // 1-12
	Year      int    `json:"year"`      // e.g., 2026
	Label     string `json:"label"`     // e.g., "January 2026"
	MealCount int    `json:"mealCount"` // number of meals in this month
}

// MealsMonths returns all unique month-year combinations that have meals
// GET /meals/months - returns available months for filtering
func (s *Server) MealsMonths(w http.ResponseWriter, r *http.Request) {
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

	// Get all meal dates for this user
	projection := bson.M{"date": 1, "_id": 0}
	cur, err := s.MealsCol.Find(
		r.Context(),
		bson.M{"userId": uid},
		options.Find().SetProjection(projection),
	)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	defer cur.Close(r.Context())

	// Parse dates and count by month-year
	monthCounts := make(map[string]int)
	monthNames := []string{"", "January", "February", "March", "April", "May", "June",
		"July", "August", "September", "October", "November", "December"}

	for cur.Next(r.Context()) {
		var doc struct {
			Date string `bson:"date"`
		}
		if err := cur.Decode(&doc); err != nil {
			continue
		}

		// Parse date format "3 Dec 2025"
		parts := splitDate(doc.Date)
		if len(parts) == 3 {
			month := monthShortToNumber(parts[1])
			year, _ := strconv.Atoi(parts[2])
			if month > 0 && year > 0 {
				key := strconv.Itoa(year) + "-" + strconv.Itoa(month)
				monthCounts[key]++
			}
		}
	}

	// Convert to sorted list (newest first)
	var items []MonthEntry
	for key, count := range monthCounts {
		parts := splitKey(key)
		year, _ := strconv.Atoi(parts[0])
		month, _ := strconv.Atoi(parts[1])
		label := monthNames[month] + " " + strconv.Itoa(year)
		items = append(items, MonthEntry{
			Month:     month,
			Year:      year,
			Label:     label,
			MealCount: count,
		})
	}

	// Sort by year desc, then month desc
	sortMonthEntries(items)

	_ = json.NewEncoder(w).Encode(map[string]any{"items": items})
}

func splitDate(date string) []string {
	var parts []string
	current := ""
	for _, c := range date {
		if c == ' ' {
			if current != "" {
				parts = append(parts, current)
				current = ""
			}
		} else {
			current += string(c)
		}
	}
	if current != "" {
		parts = append(parts, current)
	}
	return parts
}

func splitKey(key string) []string {
	var parts []string
	current := ""
	for _, c := range key {
		if c == '-' {
			parts = append(parts, current)
			current = ""
		} else {
			current += string(c)
		}
	}
	if current != "" {
		parts = append(parts, current)
	}
	return parts
}

func monthShortToNumber(short string) int {
	months := map[string]int{
		"Jan": 1, "Feb": 2, "Mar": 3, "Apr": 4, "May": 5, "Jun": 6,
		"Jul": 7, "Aug": 8, "Sep": 9, "Oct": 10, "Nov": 11, "Dec": 12,
	}
	return months[short]
}

func sortMonthEntries(items []MonthEntry) {
	// Simple bubble sort for small data
	for i := 0; i < len(items); i++ {
		for j := i + 1; j < len(items); j++ {
			if items[j].Year > items[i].Year ||
				(items[j].Year == items[i].Year && items[j].Month > items[i].Month) {
				items[i], items[j] = items[j], items[i]
			}
		}
	}
}

// MealsCalendar returns all meal dates and statuses for calendar dots display
// GET /meals/calendar - returns all meals' date and status (lightweight, no pagination)
func (s *Server) MealsCalendar(w http.ResponseWriter, r *http.Request) {
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

	// Only project the fields we need: date and status
	projection := bson.M{
		"date":   1,
		"status": 1,
		"_id":    0,
	}

	cur, err := s.MealsCol.Find(
		r.Context(),
		bson.M{"userId": uid},
		options.Find().SetProjection(projection),
	)
	if err != nil {
		http.Error(w, err.Error(), 500)
		return
	}
	defer cur.Close(r.Context())

	var items []MealCalendarEntry
	if err := cur.All(r.Context(), &items); err != nil {
		http.Error(w, err.Error(), 500)
		return
	}

	_ = json.NewEncoder(w).Encode(map[string]any{"items": items})
}

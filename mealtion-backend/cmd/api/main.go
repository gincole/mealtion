package main

import (
	"log"
	"net/http"

	"github.com/gorilla/mux"

	"mealtion-backend/internal/config"
	"mealtion-backend/internal/db"
	"mealtion-backend/internal/handlers"
	"mealtion-backend/internal/middleware"
)

func main() {
	cfg := config.Load()

	client := db.MustConnectMongo(cfg.MongoURI)
	database := client.Database(cfg.MongoDB)

	if err := db.EnsureIndexes(database); err != nil {
		log.Fatal(err)
	}

	s := handlers.NewServer(database)

	r := mux.NewRouter()

	// Public
	r.HandleFunc("/health", s.Health).Methods(http.MethodGet)
	r.HandleFunc("/auth/register", s.Register).Methods(http.MethodPost)
	r.HandleFunc("/auth/login", s.Login).Methods(http.MethodPost)
	r.HandleFunc("/auth/me", s.Me).Methods(http.MethodGet) // will be protected below (better)

	// Protected (JWT required)
	r.Handle("/meals", middleware.WithAuth(http.HandlerFunc(s.Meals))).
		Methods(http.MethodGet, http.MethodPost, http.MethodOptions)

	r.Handle("/meals/calendar", middleware.WithAuth(http.HandlerFunc(s.MealsCalendar))).
		Methods(http.MethodGet, http.MethodOptions)

	r.Handle("/meals/{id}", middleware.WithAuth(http.HandlerFunc(s.DeleteMeal))).
		Methods(http.MethodDelete, http.MethodOptions)

	// Public image endpoint (meal images)
	r.HandleFunc("/meals/{id}/image", s.MealImage).Methods(http.MethodGet)

	r.Handle("/plans", middleware.WithAuth(http.HandlerFunc(s.Plans))).
		Methods(http.MethodGet, http.MethodPost, http.MethodOptions)

	r.Handle("/plans/{id}", middleware.WithAuth(http.HandlerFunc(s.DeletePlan))).
		Methods(http.MethodDelete, http.MethodOptions)

	r.Handle("/auth/me", middleware.WithAuth(http.HandlerFunc(s.Me))).
		Methods(http.MethodGet)

	log.Println("Go API running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", middleware.WithCORS(r)))
}

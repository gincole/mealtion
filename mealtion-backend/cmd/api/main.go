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

	r.Handle("/plans", middleware.WithAuth(http.HandlerFunc(s.Plans))).
		Methods(http.MethodGet, http.MethodPost, http.MethodOptions)

	r.Handle("/auth/me", middleware.WithAuth(http.HandlerFunc(s.Me))).
		Methods(http.MethodGet)

	log.Println("Go API running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", middleware.WithCORS(r)))
}

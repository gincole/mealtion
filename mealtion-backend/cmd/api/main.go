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

	s := handlers.NewServer(database)

	r := mux.NewRouter()
	r.HandleFunc("/health", s.Health).Methods(http.MethodGet)
	r.HandleFunc("/meals", s.Meals).Methods(http.MethodGet, http.MethodPost, http.MethodOptions)
	r.HandleFunc("/plans", s.Plans).Methods(http.MethodGet, http.MethodPost, http.MethodOptions)
	r.HandleFunc("/auth/register", s.Register).Methods("POST")
	r.HandleFunc("/auth/login", s.Login).Methods("POST")

	log.Println("Go API running at http://localhost:8080")
	log.Fatal(http.ListenAndServe(":8080", middleware.WithCORS(r)))
}

package handlers

import "go.mongodb.org/mongo-driver/mongo"

type Server struct {
	MealsCol *mongo.Collection
	PlansCol *mongo.Collection
	UsersCol *mongo.Collection
}

func NewServer(db *mongo.Database) *Server {
	return &Server{
		MealsCol: db.Collection("meals"),
		PlansCol: db.Collection("plans"),
		UsersCol: db.Collection("users"),
	}
}

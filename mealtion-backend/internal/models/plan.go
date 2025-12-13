package models

import "go.mongodb.org/mongo-driver/bson/primitive"

type Plan struct {
	ID       primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Title    string             `bson:"title" json:"title"`
	Date     string             `bson:"date" json:"date"`
	MealTime string             `bson:"mealTime" json:"mealTime"`
	Status   string             `bson:"status" json:"status"`
}

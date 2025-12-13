package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Meal struct {
	UserID    primitive.ObjectID `bson:"userId" json:"userId"`
	ID        primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Title     string             `bson:"title" json:"title"`
	ImageURL  string             `bson:"imageUrl" json:"imageUrl"`
	Status    string             `bson:"status" json:"status"`
	Date      string             `bson:"date" json:"date"`
	Time      string             `bson:"time" json:"time"`
	Location  string             `bson:"location" json:"location"`
	CreatedAt time.Time          `bson:"createdAt" json:"createdAt"`
}

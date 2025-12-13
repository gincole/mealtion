package models

import (
	"time"

	"go.mongodb.org/mongo-driver/bson/primitive"
)

type Meal struct {
	UserID           primitive.ObjectID `bson:"userId" json:"userId"`
	ID               primitive.ObjectID `bson:"_id,omitempty" json:"id"`
	Title            string             `bson:"title" json:"title"`
	ImageURL         string             `bson:"imageUrl,omitempty" json:"imageUrl,omitempty"`
	ImageData        []byte             `bson:"imageData,omitempty" json:"-"`
	ImageContentType string             `bson:"imageContentType,omitempty" json:"-"`
	HasImage         bool               `bson:"hasImage" json:"hasImage"`
	Status           string             `bson:"status" json:"status"`
	Date             string             `bson:"date" json:"date"`
	Time             string             `bson:"time" json:"time"`
	Location         string             `bson:"location" json:"location"`
	CreatedAt        time.Time          `bson:"createdAt" json:"createdAt"`
}

// MealInput is used for POST requests with base64 image data
type MealInput struct {
	Title            string `json:"title"`
	ImageBase64      string `json:"imageBase64,omitempty"`
	ImageContentType string `json:"imageContentType,omitempty"`
	Status           string `json:"status"`
	Date             string `json:"date"`
	Time             string `json:"time"`
	Location         string `json:"location"`
}

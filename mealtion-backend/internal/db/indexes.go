package db

import (
	"context"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// EnsureIndexes creates required DB indexes (idempotent).
func EnsureIndexes(database *mongo.Database) error {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	// Users collection indexes
	users := database.Collection("users")
	_, err := users.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys:    bson.D{{Key: "email", Value: 1}},
		Options: options.Index().SetUnique(true),
	})
	if err != nil {
		return err
	}

	// Refresh tokens collection indexes
	refreshTokens := database.Collection("refresh_tokens")

	// Index for token lookup by hash
	_, err = refreshTokens.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{{Key: "tokenHash", Value: 1}},
	})
	if err != nil {
		return err
	}

	// Index for finding tokens by user ID
	_, err = refreshTokens.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys: bson.D{{Key: "userId", Value: 1}},
	})
	if err != nil {
		return err
	}

	// TTL index to automatically delete expired tokens after 30 days
	_, err = refreshTokens.Indexes().CreateOne(ctx, mongo.IndexModel{
		Keys:    bson.D{{Key: "expiresAt", Value: 1}},
		Options: options.Index().SetExpireAfterSeconds(30 * 24 * 60 * 60), // 30 days after expiry
	})

	return err
}

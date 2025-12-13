package config

import (
	"log"
	"os"

	"github.com/joho/godotenv"
)

type Config struct {
	MongoURI string
	MongoDB  string
}

func Load() Config {
	_ = godotenv.Load()

	uri := os.Getenv("MONGODB_URI")
	db := os.Getenv("MONGODB_DB")
	if uri == "" || db == "" {
		log.Fatal("Missing MONGODB_URI or MONGODB_DB in .env")
	}
	return Config{MongoURI: uri, MongoDB: db}
}

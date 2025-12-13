# Stage 1: Build the application
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Copy dependency files first to utilize Docker cache
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code
COPY . .

# Build the binary (pointing to your main.go)
RUN go build -o main ./cmd/api/main.go

# Stage 2: Create a small image for execution
FROM alpine:latest

WORKDIR /root/

# Copy the built binary from the builder stage
COPY --from=builder /app/main .

# Expose port 8080 (Matches your main.go configuration)
EXPOSE 8080

# Run the application
CMD ["./main"]
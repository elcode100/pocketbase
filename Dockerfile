# ─────────────────────────────────────────────────────────────
# Stage 1: Build the Admin UI (Svelte)
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS ui-builder

WORKDIR /build/ui

# Copy only UI source
COPY ui/package.json ui/package-lock.json ./
RUN npm ci

COPY ui/ ./
RUN npm run build

# ─────────────────────────────────────────────────────────────
# Stage 2: Build PocketBase Go binary
# ─────────────────────────────────────────────────────────────
FROM golang:1.24-alpine AS go-builder

WORKDIR /build

# Copy go modules first for cache
COPY go.mod go.sum ./
RUN go mod download

# Copy all source
COPY . .

# Copy the custom-built UI into the embedded directory
COPY --from=ui-builder /build/ui/dist ./ui/dist

# Build the PocketBase binary
RUN CGO_ENABLED=0 go build -o /app/pocketbase ./examples/base

# ─────────────────────────────────────────────────────────────
# Stage 3: Final minimal image
# ─────────────────────────────────────────────────────────────
FROM alpine:3.20

RUN apk add --no-cache ca-certificates

WORKDIR /app

# Copy PocketBase binary
COPY --from=go-builder /app/pocketbase /app/pocketbase

# Copy the custom UI to pb_public (PB serves this instead of embedded UI)
COPY --from=ui-builder /build/ui/dist /app/pb_public

# Copy the entrypoint script
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Data directory
VOLUME /app/pb_data
VOLUME /app/pb_hooks

EXPOSE 8080

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/app/pocketbase", "serve", "--http=0.0.0.0:8080"]

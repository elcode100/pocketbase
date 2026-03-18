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
FROM golang:1.25-alpine AS go-builder

WORKDIR /build

# Copy go modules first for cache
COPY go.mod go.sum ./
RUN go mod download

# Copy all source
COPY . .

# Copy the custom-built UI into the embedded directory
# (Go's embed directive bundles this into the binary)
COPY --from=ui-builder /build/ui/dist ./ui/dist

# Build the PocketBase binary
RUN CGO_ENABLED=0 go build -o /app/pocketbase ./examples/base

# ─────────────────────────────────────────────────────────────
# Stage 3: Final minimal image
# ─────────────────────────────────────────────────────────────
FROM alpine:3.20

RUN apk add --no-cache ca-certificates curl

WORKDIR /app

# Copy PocketBase binary (admin UI is embedded inside)
COPY --from=go-builder /app/pocketbase /app/pocketbase

# Copy the entrypoint script (writes PBCONSOLE_URL hook to pb_hooks at runtime)
COPY entrypoint.sh /app/entrypoint.sh
RUN chmod +x /app/entrypoint.sh

# Data directory
VOLUME /app/pb_data
VOLUME /app/pb_hooks

EXPOSE 8080

# Health check — matches original Coolify PocketBase image behavior
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
    CMD curl -sf http://localhost:8080/api/health || exit 1

ENTRYPOINT ["/app/entrypoint.sh"]
CMD ["/app/pocketbase", "serve", "--http=0.0.0.0:8080"]

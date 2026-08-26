# ==============================================================================
# Stage 1: Build Flutter Web Client
# ==============================================================================
FROM ghcr.io/cirruslabs/flutter:stable AS flutter-builder

WORKDIR /app

# Copy Flutter dependencies definitions
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy Flutter source code and build for Web
COPY lib ./lib
COPY web ./web
RUN flutter build web --release

# ==============================================================================
# Stage 2: Build JioSaavn Open-Source API Engine
# ==============================================================================
FROM node:20-alpine AS api-builder

WORKDIR /app/jiosaavn-api

COPY jiosaavn-api/package*.json ./
RUN npm ci

COPY jiosaavn-api/ ./
RUN npm run build

# ==============================================================================
# Stage 3: Production Runtime
# ==============================================================================
FROM node:20-alpine AS runner

WORKDIR /app

ENV NODE_ENV=production
ENV PORT=5000

# 1. Install Backend Dependencies
COPY backend/package*.json ./backend/
RUN cd backend && npm ci --only=production

# 2. Copy JioSaavn API built artifacts & node-server.js
COPY --from=api-builder /app/jiosaavn-api/dist ./jiosaavn-api/dist
COPY --from=api-builder /app/jiosaavn-api/node_modules ./jiosaavn-api/node_modules
COPY --from=api-builder /app/jiosaavn-api/package.json ./jiosaavn-api/package.json
COPY jiosaavn-api/node-server.js ./jiosaavn-api/

# 3. Copy Backend Source Code & Orchestrator
COPY backend/src ./backend/src
COPY backend/server.js ./backend/
COPY backend/start-production.js ./backend/

# 4. Copy Flutter Web Compiled UI
COPY --from=flutter-builder /app/build/web ./build/web

# Expose HTTP Port
EXPOSE 5000

# Health check
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:5000/api/health || exit 1

# Start Unified Production Server
CMD ["node", "backend/start-production.js"]

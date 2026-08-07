# ─── Stage 1: Build & test ───────────────────────────────────────────────────
FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies first (layer cache optimisation)
COPY app/package*.json ./
RUN npm ci --only=production

# Copy source
COPY app/ .

# Run tests in build stage
FROM node:20-alpine AS tester

WORKDIR /app

COPY app/package*.json ./

RUN npm ci

COPY app/ .

CMD ["npm","test"]

# ─── Stage 2: Production image ───────────────────────────────────────────────
FROM node:20-alpine AS production

# Security: run as non-root user
RUN addgroup -g 1001 -S nodejs && adduser -S appuser -u 1001

WORKDIR /app

# Copy only prod dependencies and source from builder
COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules
COPY --from=builder --chown=appuser:nodejs /app/server.js ./
COPY --from=builder --chown=appuser:nodejs /app/package.json ./

USER appuser

EXPOSE 3000

# Healthcheck for Docker / K8s
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

ENV NODE_ENV=production

CMD ["node", "server.js"]

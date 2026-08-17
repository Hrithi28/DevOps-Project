# ─────────────────────────────────────────────────────────────────────────────
# Stage 1: Production dependencies
# ─────────────────────────────────────────────────────────────────────────────
FROM node:20-alpine3.23 AS builder

WORKDIR /app

COPY app/package*.json ./

# Install only production dependencies
RUN npm ci --omit=dev

# Copy application source
COPY app/ .


# ─────────────────────────────────────────────────────────────────────────────
# Stage 2: Test
# ─────────────────────────────────────────────────────────────────────────────
FROM node:20-alpine3.23 AS tester

WORKDIR /app

COPY app/package*.json ./

# Install all dependencies required for testing
RUN npm ci

COPY app/ .

CMD ["npm", "test", "--", "--forceExit"]


# ─────────────────────────────────────────────────────────────────────────────
# Stage 3: Production
# ─────────────────────────────────────────────────────────────────────────────
FROM node:20-alpine3.23 AS production

# Create non-root user
RUN addgroup -g 1001 -S nodejs && \
    adduser -S appuser -u 1001

WORKDIR /app

# Copy only production dependencies
COPY --from=builder --chown=appuser:nodejs /app/node_modules ./node_modules

# Copy application files
COPY --from=builder --chown=appuser:nodejs /app/server.js ./
COPY --from=builder --chown=appuser:nodejs /app/package.json ./

# Run as non-root
USER appuser

ENV NODE_ENV=production

EXPOSE 3000

# Container healthcheck
HEALTHCHECK --interval=30s \
            --timeout=5s \
            --start-period=10s \
            --retries=3 \
            CMD wget --no-verbose \
                     --tries=1 \
                     --spider \
                     http://localhost:3000/health || exit 1

CMD ["node", "server.js"]

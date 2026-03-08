# -------- Stage 1: Build --------
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./

RUN npm ci --only=production
# -------- Stage 2: Runtime --------
FROM node:20-alpine AS production

WORKDIR /app

RUN apk add nano
RUN apk add --no-cache curl

RUN addgroup -S nodegroup && adduser -S nodeuser -G nodegroup

COPY --from=builder /app/node_modules ./node_modules

COPY package*.json ./
COPY server.js .

RUN chown -R nodeuser:nodegroup /app

USER nodeuser

ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000

CMD ["node", "server.js"]

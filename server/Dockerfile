# ---- Build stage ----
FROM node:20-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production


# ---- Production stage ----
FROM node:20-alpine AS production

WORKDIR /app

COPY --from=build /app/node_modules ./node_modules
COPY . .

EXPOSE 3009

CMD ["node", "index.js"]

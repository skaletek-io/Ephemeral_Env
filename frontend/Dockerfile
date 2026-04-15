FROM node:20-alpine AS builder
WORKDIR /app
ARG NEXT_PUBLIC_ENV_NAME=local
ENV NEXT_PUBLIC_ENV_NAME=$NEXT_PUBLIC_ENV_NAME
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

FROM node:20-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
EXPOSE 3000
ENV PORT=3000 HOSTNAME=0.0.0.0
CMD ["node", "server.js"]

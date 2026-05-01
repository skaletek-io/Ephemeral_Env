FROM caddy:2.9-builder-alpine AS builder
RUN xcaddy build \
    --with github.com/caddy-dns/route53

FROM caddy:2.9-alpine
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

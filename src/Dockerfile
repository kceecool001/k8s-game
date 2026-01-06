# Stage 1: Prepare files
FROM alpine:latest AS builder
WORKDIR /app
COPY . .

# Stage 2: Production image
FROM nginx:alpine
COPY --from=builder /app /usr/share/nginx/html

# Configure nginx to listen on port 3000
RUN echo 'server { \
    listen 3000; \
    server_name localhost; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

# Set permissions and switch to non-root user
RUN chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d /var/run
USER nginx

EXPOSE 3000

CMD ["nginx", "-g", "daemon off;"]


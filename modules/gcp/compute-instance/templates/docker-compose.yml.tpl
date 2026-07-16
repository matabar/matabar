services:
  app:
    image: traefik/whoami:v1.10.1
    restart: unless-stopped
    ports:
      - "127.0.0.1:${app_port}:80"

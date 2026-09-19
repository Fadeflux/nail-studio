# Serveur statique Caddy pour l'appli Nail Art (déploiement Railway)
FROM caddy:2-alpine

WORKDIR /srv
COPY index.html /srv/index.html
COPY supabase /srv/supabase
COPY Caddyfile /etc/caddy/Caddyfile

# Caddy lit le port via $PORT (fourni par Railway)
CMD ["caddy", "run", "--config", "/etc/caddy/Caddyfile", "--adapter", "caddyfile"]

# syntax=docker/dockerfile:1.7

FROM cloudron/base:5.0.0@sha256:04fd70dbd8ad6149c19de39e35718e024417c3e01dc9c6637eaf4a41ec4e596c

ARG UPSTREAM_VERSION=0.5.75

RUN apt-get update && apt-get install -y --no-install-recommends git python3 python3-venv make g++ && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /app/code /app/data /opt/headroom \
    && python3 -m venv /opt/headroom \
    && /opt/headroom/bin/pip install --no-cache-dir "headroom-ai[proxy]" \
    && git clone --branch "v${UPSTREAM_VERSION}" --depth 1 https://github.com/decolua/9router.git /tmp/9router

WORKDIR /app/code
RUN cp /tmp/9router/package.json ./
RUN npm install

RUN cp -r /tmp/9router/. ./
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm run build

# Remove source code and build tools, keep runtime deps
RUN rm -rf upstream src docs tests cli .git \
    eslint.config.mjs jsconfig.json postcss.config.mjs next.config.mjs \
    docker-compose.yml Dockerfile captain-definition CLAUDE.md DOCKER.md LICENSE \
    gitbook i18n

# Move standalone output to code root where custom-server.js expects it
RUN cp -r .next/standalone/* . && rm -rf .next/standalone .next/cache .next/trace

ENV NODE_ENV=production
ENV PORT=20128
ENV HOSTNAME=0.0.0.0
ENV DATA_DIR=/app/data
ENV INITIAL_PASSWORD=123456
ENV MITM_PORT=8443
ENV HEADROOM_URL=http://127.0.0.1:8787
ENV HEADROOM_CONFIG_DIR=/app/data/headroom
ENV HEADROOM_BEACON=off

COPY start.sh ./
COPY CloudronManifest.json ./
RUN chmod +x start.sh

EXPOSE 20128

CMD ["/app/code/start.sh"]

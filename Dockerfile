# syntax=docker/dockerfile:1.7

FROM --platform=linux/amd64 node:22.23.4-bookworm-slim@sha256:aaa4b5baf1ecff3b283486bb1f90405cdda225a3e6f79660d2c559fa510a7292 AS base

FROM base AS builder
ARG UPSTREAM_VERSION=0.5.116
ARG UPSTREAM_COMMIT=1339107e624d1ab150c6a0c2c2ee22caa7e9db2f

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates git python3 python3-venv make g++ \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/headroom \
    && /opt/headroom/bin/pip install --no-cache-dir "headroom-ai[proxy,code]" \
    && git init /app/code \
    && git -C /app/code remote add origin https://github.com/decolua/9router.git \
    && git -C /app/code fetch --depth 1 origin "${UPSTREAM_COMMIT}" \
    && git -C /app/code checkout --detach FETCH_HEAD \
    && test "$(git -C /app/code rev-parse HEAD)" = "${UPSTREAM_COMMIT}" \
    && test "$(node -p 'require("/app/code/package.json").version')" = "${UPSTREAM_VERSION}"

WORKDIR /app/code
ENV NEXT_TELEMETRY_DISABLED=1
RUN npm install && npm run build

# Next tracing omits these lazy createRequire dependencies (upstream issue #5245).
RUN mkdir -p /opt/lazy-runtime && cd /opt/lazy-runtime \
    && npm init -y >/dev/null \
    && npm install --no-save "wreq-js@$(node -p 'require("/app/code/package.json").devDependencies["wreq-js"]')" \
        "playwright-core@$(node -p 'require("/app/code/package.json").devDependencies["playwright-core"]')"

FROM base AS runtime
RUN test "$(node --version)" = "v22.23.4" \
    && apt-get update && apt-get install -y --no-install-recommends \
    bash ca-certificates gosu python3 ffmpeg libstdc++6 libgomp1 \
    && rm -rf /var/lib/apt/lists/* \
    && groupmod --new-name cloudron node \
    && usermod --login cloudron --home /app/data/headroom node \
    && test "$(id -u cloudron):$(id -g cloudron)" = "1000:1000" \
    && mkdir -p /app/data \
    && rm -rf /usr/local/lib/node_modules /opt/yarn-* \
    && rm -f /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack /usr/local/bin/yarn /usr/local/bin/yarnpkg

WORKDIR /app/code
# Keep the venv at the same absolute path and on the same Debian/Python base.
COPY --from=builder /opt/headroom /opt/headroom
COPY --from=builder /app/code/.next/standalone ./
COPY --from=builder /app/code/.next/static ./.next/static
COPY --from=builder /app/code/public ./public
COPY --from=builder /app/code/custom-server.js ./custom-server.js
COPY --from=builder /app/code/open-sse ./open-sse
# MITM runs as a child process; standalone tracing omits its source and deps.
COPY --from=builder /app/code/src/mitm ./src/mitm
COPY --from=builder /app/code/node_modules/node-forge ./node_modules/node-forge
COPY --from=builder /app/code/node_modules/next ./node_modules/next
COPY --from=builder /app/code/node_modules/sql.js ./node_modules/sql.js
COPY --from=builder /app/code/node_modules/node-machine-id ./node_modules/node-machine-id
COPY --from=builder /opt/lazy-runtime/node_modules/. ./node_modules/

ENV NODE_ENV=production
ENV NEXT_TELEMETRY_DISABLED=1
ENV PORT=20128
ENV HOSTNAME=0.0.0.0
ENV DATA_DIR=/app/data
ENV INITIAL_PASSWORD=123456
ENV MITM_PORT=8443
ENV HEADROOM_URL=http://127.0.0.1:8787
ENV HEADROOM_CONFIG_DIR=/app/data/headroom
ENV HOME=/app/data/headroom
ENV PATH=/opt/headroom/bin:$PATH
ENV HEADROOM_BEACON=off

COPY start.sh ./
COPY CloudronManifest.json ./
RUN chmod +x start.sh

EXPOSE 20128

CMD ["/app/code/start.sh"]

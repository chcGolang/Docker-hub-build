ARG NETEASE_VERSION=latest
FROM node:24-alpine

ARG NETEASE_VERSION

RUN apk add --no-cache ca-certificates tzdata \
    && npm install -g --no-fund --no-audit "NeteaseCloudMusicApi@${NETEASE_VERSION}" \
    && npm cache clean --force

ENV TZ=Asia/Shanghai \
    NODE_ENV=production \
    HOST=0.0.0.0 \
    PORT=3000

WORKDIR /app

EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
  CMD wget -qO- "http://127.0.0.1:${PORT}/inner/version" >/dev/null || exit 1

CMD ["NeteaseCloudMusicApi"]

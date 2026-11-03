ARG WORKBUDDY_VERSION=latest

FROM alpine:3.22 AS fetch

ARG WORKBUDDY_VERSION
ARG TARGETARCH

RUN apk add --no-cache ca-certificates curl

RUN set -eux; \
    arch="${TARGETARCH:-$(uname -m)}"; \
    case "${arch}" in \
        amd64 | x86_64) asset="workbuddy-gateway-linux-amd64" ;; \
        arm64 | aarch64) asset="workbuddy-gateway-linux-arm64" ;; \
        *) echo "unsupported architecture: ${arch}" >&2; exit 1 ;; \
    esac; \
    if [ "${WORKBUDDY_VERSION}" = "latest" ]; then \
        base="https://github.com/CangShui/workbuddy-gateway/releases/latest/download"; \
    else \
        base="https://github.com/CangShui/workbuddy-gateway/releases/download/v${WORKBUDDY_VERSION}"; \
    fi; \
    mkdir -p /out; \
    curl -fsSL "${base}/${asset}" -o "/out/${asset}"; \
    curl -fsSL "${base}/SHA256SUMS" -o /tmp/SHA256SUMS; \
    grep " ${asset}\$" /tmp/SHA256SUMS > /tmp/checksum; \
    test -s /tmp/checksum; \
    cd /out && sha256sum -c /tmp/checksum; \
    mv "/out/${asset}" /out/workbuddy-gateway; \
    chmod 0755 /out/workbuddy-gateway

FROM alpine:3.22

RUN apk add --no-cache ca-certificates tzdata

ENV TZ=Asia/Shanghai

COPY --from=fetch /out/workbuddy-gateway /usr/local/bin/workbuddy-gateway

WORKDIR /data

EXPOSE 8317 8316

ENTRYPOINT ["workbuddy-gateway"]
CMD ["serve", "-addr", "0.0.0.0", "-webui"]

FROM debian:trixie-slim

ARG OPENCODE_VERSION=latest

RUN apt-get update && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        tar \
    && rm -rf /var/lib/apt/lists/*

RUN if [ "$OPENCODE_VERSION" = "latest" ]; then \
        curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path; \
    else \
        curl -fsSL https://opencode.ai/install | bash -s -- --no-modify-path --version "$OPENCODE_VERSION"; \
    fi

RUN sed -i 's|deb.debian.org|mirrors.tuna.tsinghua.edu.cn|g; s|security.debian.org|mirrors.tuna.tsinghua.edu.cn|g' \
        /etc/apt/sources.list.d/debian.sources \
    && apt-get update

ENV PATH="/root/.opencode/bin:${PATH}"

EXPOSE 4096

WORKDIR /workspace
CMD ["opencode", "web", "--hostname", "0.0.0.0", "--port", "4096"]

#!/usr/bin/env bash
set -euo pipefail

version="$(
    curl -fsSL https://api.github.com/repos/CangShui/workbuddy-gateway/releases/latest \
        | sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"v\{0,1\}\([^"]*\)".*/\1/p'
)"

if [ -z "$version" ]; then
    echo "failed to resolve workbuddy-gateway version" >&2
    exit 1
fi

case "$version" in
    [0-9]*.[0-9]*.[0-9]*) ;;
    *)
        echo "unexpected workbuddy-gateway version: $version" >&2
        exit 1
        ;;
esac

printf '%s\n' "$version"

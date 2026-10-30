#!/usr/bin/env bash
set -euo pipefail

# 官方 V2 安装脚本（https://opencode.ai/v2/install）使用的版本源
version="$(
    curl -fsSL https://opencode.ai/update/api/latest/cli/npm \
        | sed -n 's/.*"version":"\([^"]*\)".*/\1/p'
)"

[ -n "$version" ] || {
    echo "failed to resolve opencode version" >&2
    exit 1
}

case "$version" in
    2.*) ;;
    *)
        echo "unexpected opencode version: $version (expected 2.x)" >&2
        exit 1
        ;;
esac

printf '%s\n' "$version"

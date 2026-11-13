#!/usr/bin/env bash
set -euo pipefail

version="$(
    curl -fsSL https://registry.npmjs.org/-/package/NeteaseCloudMusicApi/dist-tags \
        | sed -n 's/.*"latest":"\([^"]*\)".*/\1/p'
)"

if [ -z "$version" ]; then
    echo "failed to resolve NeteaseCloudMusicApi version" >&2
    exit 1
fi

case "$version" in
    [0-9]*.[0-9]*.[0-9]*) ;;
    *)
        echo "unexpected NeteaseCloudMusicApi version: $version" >&2
        exit 1
        ;;
esac

printf '%s\n' "$version"

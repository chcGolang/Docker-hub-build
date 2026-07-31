#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://api.github.com/repos/anomalyco/opencode/releases/latest \
    | grep -Po '"tag_name":\s*"v\K[^"]+'

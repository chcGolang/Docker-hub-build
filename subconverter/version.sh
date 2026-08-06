#!/usr/bin/env bash
set -euo pipefail

curl -fsSL https://api.github.com/repos/tindy2013/subconverter/releases/latest \
    | grep -Po '"tag_name":\s*"v\K[^"]+'

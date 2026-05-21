#!/bin/bash
set -euo pipefail

mkdir -p var bin

if [ ! -x bin/rr ] && [ -f vendor/bin/rr ]; then
    echo "RoadRunner binary not found, downloading..."
    vendor/bin/rr get --location bin/ -n
fi

exec "$@"

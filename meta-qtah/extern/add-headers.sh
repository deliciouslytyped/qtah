#! /usr/bin/env bash
set -euo pipefail

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

pushd -- "$DIR"
nix-build default.nix -A headers --out-link shiboken2-dev/headers
popd

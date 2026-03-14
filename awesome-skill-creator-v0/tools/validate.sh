#!/usr/bin/env bash
# tools/validate.sh — shim; actual implementation in tools/gate/validate.sh
exec "$(dirname "$0")/gate/validate.sh" "$@"

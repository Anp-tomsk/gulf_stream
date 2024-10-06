#!/bin/sh
set -eu

cd -P -- "$(dirname -- "$0")"
exec ./gulf_stream start
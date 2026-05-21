#!/bin/sh
set -eu

cd /app/backend
dotnet JobFairPortal.dll &
backend_pid="$!"

trap 'kill "$backend_pid" 2>/dev/null || true' INT TERM

nginx -g 'daemon off;' &
nginx_pid="$!"

wait "$backend_pid"
backend_exit="$?"
kill "$nginx_pid" 2>/dev/null || true
wait "$nginx_pid" 2>/dev/null || true
exit "$backend_exit"
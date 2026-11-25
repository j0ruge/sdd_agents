# shellcheck shell=bash
# Shared transport for the app-probe assertions. On the host, keep real TCP and HTTP.
# In the offline Codex sandbox, supply those replies below the runner's probe: its
# URL parser, verdict, gates, and escalation still execute with the same assertions.

PAGE_PID=""
PAGE_PORT=""
APP_FIXTURE_SAVED_PATH=""

app_fixture_begin() {
  local stub="$1" rc=0
  python3 - <<'PY' || rc=$?
import socket
import sys

try:
    with socket.socket() as listener:
        listener.bind(("127.0.0.1", 0))
except PermissionError:
    sys.exit(77)
PY
  case "$rc" in
    0) return 0 ;;
    77) ;;
    *) return "$rc" ;;
  esac

  APP_FIXTURE_TIMEOUT="$(type -P timeout)" || return 1
  mkdir -p "$stub" || return 1
  cat > "$stub/timeout" <<'SH' || return 1
#!/usr/bin/env bash
if [ "$#" -eq 6 ] && [ "$3" = -c ] && [ "$4" = 'exec 3<>"/dev/tcp/$0/$1"' ]; then
  case "$5" in
    127.0.0.1|::1)
      if [ "$5" = 127.0.0.1 ] && [ "$6" = "${APP_FIXTURE_PAGE_PORT:-}" ]; then exit 0; fi
      printf 'connect: Connection refused\n' >&2
      exit 1
      ;;
  esac
fi
exec "$APP_FIXTURE_TIMEOUT" "$@"
SH
  cat > "$stub/curl" <<'SH' || return 1
#!/usr/bin/env bash
base="http://127.0.0.1:${APP_FIXTURE_PAGE_PORT:?}"
url="${!#}"
case "$url" in
  "$base"/*) path="${url#"$base"/}" ;;
  *) exit 7 ;;
esac
file="$APP_FIXTURE_PAGE_DIR/$path"
if [ -d "$file" ] && [ -n "$path" ] && [[ "$path" != */ ]]; then
  printf '\n301'
elif [ -d "$file" ] && [ -f "$file/index.html" ]; then
  cat "$file/index.html"
  printf '\n200'
else
  printf '\n404'
fi
SH
  chmod +x "$stub/timeout" "$stub/curl" || return 1
  export APP_FIXTURE_TIMEOUT
  APP_FIXTURE_SAVED_PATH="$PATH"
  PATH="$stub:$PATH"
  printf '  info  app fixtures use simulated TCP and HTTP replies (loopback is restricted)\n'
}

port_is_free() {
  local reply
  # Match refusal specifically. A sandbox denying sockets is a different transport.
  if [ -n "$APP_FIXTURE_SAVED_PATH" ]; then
    reply="$(timeout 3 bash -c 'exec 3<>"/dev/tcp/$0/$1"' 127.0.0.1 "$1" 2>&1)" || :
  else
    reply="$(LC_ALL=C timeout 3 bash -c 'exec 3<>"/dev/tcp/127.0.0.1/$0"' "$1" 2>&1)" || :
  fi
  [[ "$reply" == *'Connection refused'* ]]
}

start_page_server() {
  local port=$(( 30000 + $$ % 2000 )) tries=0 waited
  PAGE_PID=""; PAGE_PORT=""
  if [ -n "$APP_FIXTURE_SAVED_PATH" ]; then
    PAGE_PORT="$port"
    export APP_FIXTURE_PAGE_PORT="$PAGE_PORT" APP_FIXTURE_PAGE_DIR="$1"
    return 0
  fi
  # Verify the listening process is still ours before using the port.
  while [ "$tries" -lt 10 ]; do
    tries=$(( tries + 1 )); port=$(( port + 1 ))
    port_is_free "$port" || continue
    timeout 900 python3 -m http.server "$port" --bind 127.0.0.1 --directory "$1" >/dev/null 2>&1 &
    PAGE_PID=$!
    waited=0
    while port_is_free "$port" && [ "$waited" -lt 50 ]; do sleep 0.1; waited=$(( waited + 1 )); done
    if LANG=C timeout 3 bash -c 'exec 3<>"/dev/tcp/127.0.0.1/$0"' "$port" 2>/dev/null \
       && kill -0 "$PAGE_PID" 2>/dev/null; then
      PAGE_PORT="$port"
      return 0
    fi
    kill "$PAGE_PID" 2>/dev/null; wait "$PAGE_PID" 2>/dev/null || true; PAGE_PID=""
  done
}

stop_page_server() {
  if [ -n "$PAGE_PID" ]; then kill "$PAGE_PID" 2>/dev/null; wait "$PAGE_PID" 2>/dev/null || true; fi
  PAGE_PID=""; PAGE_PORT=""
  unset APP_FIXTURE_PAGE_PORT APP_FIXTURE_PAGE_DIR
}

app_fixture_end() {
  stop_page_server
  if [ -n "$APP_FIXTURE_SAVED_PATH" ]; then PATH="$APP_FIXTURE_SAVED_PATH"; fi
  APP_FIXTURE_SAVED_PATH=""
  unset APP_FIXTURE_TIMEOUT
}

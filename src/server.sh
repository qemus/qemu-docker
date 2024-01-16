#!/usr/bin/env bash
set -eu

TMP_FILE=$(mktemp -q /tmp/server.XXXXXX)

stop() {
  trap - SIGINT EXIT
  { pkill -f socat || true; } 2>/dev/null
  [ -f "$TMP_FILE" ] && rm -f "$TMP_FILE"
}

trap 'stop' EXIT SIGINT SIGTERM SIGHUP

html()
{
    local h="<!DOCTYPE html><HTML><HEAD><TITLE>$2</TITLE>"
    h="$h<STYLE>body { color: white; background-color: #125bdb; font-family: Verdana,"
    h="$h Arial,sans-serif; } a, a:hover, a:active, a:visited { color: white; }</STYLE></HEAD>"
    h="$h<BODY><BR><BR><H1><CENTER>$1</CENTER></H1></BODY></HTML>"

    echo "$h"
}

BODY="$1<script>setTimeout(() => { document.location.reload(); }, 4999);</script>"

HTML=$(html "$BODY" "$2")
printf '%b' "HTTP/1.1 200 OK\nContent-Length: ${#HTML}\nConnection: close\n\n$HTML" > "$TMP_FILE"

socat TCP4-LISTEN:80,reuseaddr,fork,crlf SYSTEM:"cat $TMP_FILE" 2> /dev/null &
socat TCP4-LISTEN:8006,reuseaddr,fork,crlf SYSTEM:"cat $TMP_FILE" 2> /dev/null & wait $!

exit

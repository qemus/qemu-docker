#!/usr/bin/env bash
set -eu

page="/dev/shm/index.html"
template="/var/www/index.html"

stop() {
  trap - SIGINT EXIT
  { pkill -f socat || true; } 2>/dev/null
}

trap 'stop' EXIT SIGINT SIGTERM SIGHUP

html()
{
    local timeout="$3"
    [ -z "$timeout" ] && timeout="4999"

    local title="$1"
    local body="$2<script>setTimeout(() => { document.location.reload(); }, $timeout);</script>"

    local HTML
    HTML=$(<"$template")
    HTML="${HTML/[1]/$title}"
    HTML="${HTML/[2]/$body}"

    printf '%b' "HTTP/1.1 200 OK\nContent-Length: ${#HTML}\nConnection: close\n\n$HTML" > "$page"
    return 0
}

html "$1" "$2" "$3"

socat TCP4-LISTEN:80,reuseaddr,fork,crlf SYSTEM:"cat $page" 2> /dev/null &
socat TCP4-LISTEN:8006,reuseaddr,fork,crlf SYSTEM:"cat $page" 2> /dev/null & wait $!

exit

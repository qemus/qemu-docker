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
    local HTML
    HTML=$(<"$template")
    HTML="${HTML/[1]/$1}"
    HTML="${HTML/[2]/$2}"

    printf '%b' "HTTP/1.1 200 OK\nContent-Length: ${#HTML}\nConnection: close\n\n$HTML" > "$page"
    return 0
}

html "$1" "$2<script>setTimeout(() => { document.location.reload(); }, $3);</script>"

socat TCP4-LISTEN:80,reuseaddr,fork,crlf SYSTEM:"cat $page" 2> /dev/null &
socat TCP4-LISTEN:8006,reuseaddr,fork,crlf SYSTEM:"cat $page" 2> /dev/null & wait $!

exit

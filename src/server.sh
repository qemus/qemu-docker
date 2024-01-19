#!/usr/bin/env bash
set -eu

stop() {
  trap - SIGINT EXIT
  { pkill -f socat || true; } 2>/dev/null
}

trap 'stop' EXIT SIGINT SIGTERM SIGHUP

page="/dev/shm/index.html"
socat TCP4-LISTEN:80,reuseaddr,fork,crlf SYSTEM:"cat $page" 2> /dev/null &
socat TCP4-LISTEN:8006,reuseaddr,fork,crlf SYSTEM:"cat $page" 2> /dev/null & wait $!

exit

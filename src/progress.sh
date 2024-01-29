#!/usr/bin/env bash
set -Eeuo pipefail

info="/run/shm/msg.html"

escape () {
    local s
    s=${1//&/\&amp;}
    s=${s//</\&lt;}
    s=${s//>/\&gt;}
    s=${s//'"'/\&quot;}
    printf -- %s "$s"
    return 0
}

file="$1"
body=$(escape "$2")

if [[ "$body" == *"..." ]]; then
  body="<p class=\"loading\">${body/.../}</p>"
fi

while true
do
	mb=$(ls -s --block-size=1048576 "$file" | cut -d' ' -f1)
  out="${body//[P]/$mb;}"
  echo "$out" > "$info"
	sleep 1
done

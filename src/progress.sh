#!/usr/bin/env bash
set -Eeuo pipefail

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
info="/run/shm/msg.html"

if [[ "$body" == *"..." ]]; then
  body="<p class=\"loading\">${body/.../}</p>"
fi

while true
do
  if [ -f "$file" ]; then
    size=$(stat -c '%s' "$file" | numfmt --to=si --suffix=B  | sed -r 's/([A-Z])/ \1/')
    echo "${body//(\[P\])/($size)}"> "$info"
  fi
  sleep 1
done

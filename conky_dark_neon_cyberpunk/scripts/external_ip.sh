#!/bin/bash

set -u

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/conky/conky_dark_neon_cyberpunk"
CACHE_FILE="$CACHE_DIR/external_ip.txt"
CACHE_MAX_AGE_SEC=3600

mkdir -p "$CACHE_DIR" 2>/dev/null || true
now="$(/usr/bin/date +%s 2>/dev/null || date +%s)"

cache_print() {
  if [[ -f "$CACHE_FILE" ]]; then
    cached_ip="$(/usr/bin/awk 'NR==1{print $2}' "$CACHE_FILE" 2>/dev/null)"
    [[ -n "$cached_ip" ]] && { echo "$cached_ip (cached)"; exit 0; }
  fi
  echo "offline"
  exit 0
}

ip="$(
  for url in \
    "https://api.ipify.org" \
    "https://ifconfig.me/ip" \
    "https://icanhazip.com"
  do
    out="$(/usr/bin/curl -4 -fsS --connect-timeout 1 --max-time 2 "$url" 2>/dev/null)"
    printf '%s\n' "$out"
  done | /usr/bin/tr -d '\r' | /usr/bin/awk 'NF{print; exit}'
)"

# validate IPv4
if [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  printf '%s %s\n' "$now" "$ip" > "$CACHE_FILE"
  echo "$ip"
  exit 0
fi

cache_print

#!/usr/bin/env bash
DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$DIR"
clear
./bin/geoffrey setup
echo
echo "Geoffrey setup finished."
read -r -p "Press Return to close this window..."


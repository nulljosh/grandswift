#!/bin/sh
# needs: libgtk-3-dev libwebkit2gtk-4.1-dev
set -e
cd "$(dirname "$0")"
cc -O2 main.c $(pkg-config --cflags --libs gtk+-3.0 webkit2gtk-4.1) -o vancouver-vice

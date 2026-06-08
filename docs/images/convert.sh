#!/usr/bin/env bash
set -euo pipefail

gap=40
output="nautilus-permanent-delete-extension.png"

rm -f top.png "$output"

convert \
  -background none \
  screenshot1.png \
  \( -size "${gap}x1" xc:none \) \
  screenshot2.png \
  +append \
  png32:top.png

top_w=$(identify -format "%w" top.png)
top_h=$(identify -format "%h" top.png)
bottom_w=$(identify -format "%w" screenshot3.png)
bottom_h=$(identify -format "%h" screenshot3.png)

x=$(( (top_w - bottom_w) / 2 ))
y=$(( top_h + gap ))
canvas_h=$(( top_h + gap + bottom_h ))

convert \
  -size "${top_w}x${canvas_h}" xc:none \
  top.png -geometry +0+0 -composite \
  screenshot3.png -geometry +"${x}"+"${y}" -composite \
  png32:"$output"

rm -f top.png
echo "Created $output"
convert png32:"$output" -resize 50% png32:"$output"
#!/usr/bin/env bash
#
# generate-icons.sh — Generate PWA icons for Braccia Capital Mobile CRM
#
# Generates 192x192 and 512x512 PNG icons from an inline SVG.
# Uses the Braccia Capital charcoal/gold branding.
#
# Requirements: One of the following must be installed:
#   - rsvg-convert (librsvg2-bin)  — preferred
#   - inkscape
#   - imagemagick (convert)
#
# Usage: bash scripts/generate-icons.sh
#

set -euo pipefail

ICONS_DIR="$(cd "$(dirname "$0")/../public/icons" && pwd)"
mkdir -p "$ICONS_DIR"

# Braccia Capital branded SVG — charcoal background, gold "B" monogram
SVG_CONTENT='<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512">
  <rect width="512" height="512" rx="96" fill="#1a1a1a"/>
  <rect x="24" y="24" width="464" height="464" rx="80" fill="none" stroke="#c9a84c" stroke-width="4" opacity="0.3"/>
  <text x="256" y="310" font-family="Georgia, serif" font-size="280" font-weight="bold" fill="#c9a84c" text-anchor="middle" dominant-baseline="central">B</text>
  <text x="256" y="430" font-family="Arial, sans-serif" font-size="42" font-weight="600" fill="#c9a84c" text-anchor="middle" letter-spacing="12" opacity="0.7">CAPITAL</text>
</svg>'

TMPSVG=$(mktemp /tmp/braccia-icon-XXXXXX.svg)
echo "$SVG_CONTENT" > "$TMPSVG"

generate_with_rsvg() {
  echo "[icons] Using rsvg-convert..."
  rsvg-convert -w 192 -h 192 "$TMPSVG" -o "$ICONS_DIR/icon-192.png"
  rsvg-convert -w 512 -h 512 "$TMPSVG" -o "$ICONS_DIR/icon-512.png"
}

generate_with_inkscape() {
  echo "[icons] Using inkscape..."
  inkscape "$TMPSVG" -w 192 -h 192 -o "$ICONS_DIR/icon-192.png" 2>/dev/null
  inkscape "$TMPSVG" -w 512 -h 512 -o "$ICONS_DIR/icon-512.png" 2>/dev/null
}

generate_with_imagemagick() {
  echo "[icons] Using imagemagick convert..."
  convert -background none -density 300 -resize 192x192 "$TMPSVG" "$ICONS_DIR/icon-192.png"
  convert -background none -density 300 -resize 512x512 "$TMPSVG" "$ICONS_DIR/icon-512.png"
}

# Try each tool in order of preference
if command -v rsvg-convert &>/dev/null; then
  generate_with_rsvg
elif command -v inkscape &>/dev/null; then
  generate_with_inkscape
elif command -v convert &>/dev/null; then
  generate_with_imagemagick
else
  echo "[icons] ERROR: No SVG-to-PNG tool found."
  echo ""
  echo "Install one of these:"
  echo "  apt install librsvg2-bin    # recommended (rsvg-convert)"
  echo "  apt install inkscape"
  echo "  apt install imagemagick"
  echo ""
  echo "Alternatively, manually place 192x192 and 512x512 PNG files at:"
  echo "  $ICONS_DIR/icon-192.png"
  echo "  $ICONS_DIR/icon-512.png"
  echo ""
  # Save the SVG so the user can convert it manually
  cp "$TMPSVG" "$ICONS_DIR/icon-source.svg"
  echo "SVG source saved to: $ICONS_DIR/icon-source.svg"
  rm -f "$TMPSVG"
  exit 1
fi

rm -f "$TMPSVG"

echo "[icons] Generated:"
echo "  $ICONS_DIR/icon-192.png (192x192)"
echo "  $ICONS_DIR/icon-512.png (512x512)"
echo "[icons] Done."

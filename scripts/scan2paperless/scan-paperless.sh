#!/bin/bash

set -u

SCANNER="epson2:net:192.168.178.79"
DEST="/mnt/paperless-scan"
TMPDIR="/tmp"

FILENAME="$(date '+%Y-%m-%d_%H-%M-%S').pdf"
TMPFILE="$TMPDIR/$FILENAME"
REBUILDFILE="$TMPDIR/rebuild-$FILENAME"
OCRFILE="$TMPDIR/ocr-$FILENAME"
WORKDIR="$TMPDIR/scan-rebuild-${FILENAME%.pdf}"
FINALFILE="$DEST/$FILENAME"

cleanup() {
    rm -f "$TMPFILE" "$REBUILDFILE" "$OCRFILE"
    rm -rf "$WORKDIR"
}

trap cleanup EXIT

echo "======================================"
echo " Epson XP-452 → Paperless"
echo "======================================"
echo

# Abhängigkeiten prüfen
for CMD in scanimage pdfimages img2pdf ocrmypdf tesseract mountpoint; do
    if ! command -v "$CMD" >/dev/null 2>&1; then
        echo "Fehler: '$CMD' wurde nicht gefunden."
        exit 1
    fi
done

# Deutsches Tesseract-Sprachpaket prüfen
if ! tesseract --list-langs 2>/dev/null | grep -qx "deu"; then
    echo "Fehler: Tesseract-Sprachpaket 'deu' fehlt."
    echo
    echo "Installieren mit:"
    echo "  sudo pacman -S tesseract-data-deu"
    exit 1
fi

# Paperless-Share prüfen
if ! mountpoint -q "$DEST"; then
    echo "Fehler: $DEST ist nicht gemountet!"
    exit 1
fi

# Scanner prüfen
if ! scanimage -L 2>/dev/null | grep -q "$SCANNER"; then
    echo "Fehler: Epson XP-452 wurde nicht gefunden."
    echo
    echo "Gefundene Scanner:"
    scanimage -L
    exit 1
fi

echo "Auflösung: 300 DPI"
echo "Modus:     Farbe"
echo "Format:    A4"
echo
echo "Enter = Seite scannen"
echo "Ctrl+D = Scan beenden"
echo

# --------------------------------------------------
# 1. SCAN
# --------------------------------------------------

scanimage \
    -d "$SCANNER" \
    --resolution 300 \
    --mode Color \
    --format=pdf \
    --batch="$TMPFILE" \
    --batch-prompt \
    -l 0 \
    -t 0 \
    -x 205 \
    -y 297

RESULT=$?

echo

if [ $RESULT -ne 0 ] || [ ! -s "$TMPFILE" ]; then
    echo "Scan fehlgeschlagen!"
    rm -f "$TMPFILE"
    exit 1
fi

echo "Scan abgeschlossen."
echo

# --------------------------------------------------
# 2. JPEGs AUS SANE-PDF EXTRAHIEREN
# --------------------------------------------------

echo "Extrahiere Scanbilder aus der PDF..."

mkdir -p "$WORKDIR"

if ! pdfimages -j "$TMPFILE" "$WORKDIR/page"; then
    echo "Fehler: Scanbilder konnten nicht extrahiert werden."
    exit 1
fi

IMAGE_COUNT=$(find "$WORKDIR" -type f -name 'page-*.jpg' | wc -l)

if [ "$IMAGE_COUNT" -eq 0 ]; then
    echo "Fehler: Keine JPEG-Scanbilder gefunden."
    exit 1
fi

echo "Gefundene Seiten: $IMAGE_COUNT"
echo

# --------------------------------------------------
# 3. SAUBERE PDF AUS JPEGs ERZEUGEN
# --------------------------------------------------

echo "Erzeuge saubere PDF..."

if ! img2pdf \
    "$WORKDIR"/page-*.jpg \
    -o "$REBUILDFILE"; then
    echo "Fehler: Saubere PDF konnte nicht erzeugt werden."
    exit 1
fi

if [ ! -s "$REBUILDFILE" ]; then
    echo "Fehler: Erzeugte PDF ist leer."
    exit 1
fi

echo "PDF erfolgreich neu aufgebaut."
echo

# --------------------------------------------------
# 4. OCR
# --------------------------------------------------

echo "OCR wird durchgeführt..."
echo "Sprache: Deutsch"
echo

if ! ocrmypdf \
    --language deu \
    --output-type pdf \
    "$REBUILDFILE" \
    "$OCRFILE"; then

    echo
    echo "OCR fehlgeschlagen!"
    echo
    echo "Der ursprüngliche Scan bleibt erhalten:"
    echo "$TMPFILE"
    echo
    echo "Arbeitsverzeichnis:"
    echo "$WORKDIR"

    # Cleanup temporär deaktivieren, damit Fehleranalyse möglich bleibt
    trap - EXIT
    exit 1
fi

if [ ! -s "$OCRFILE" ]; then
    echo "Fehler: OCR-PDF ist leer."
    exit 1
fi

echo "OCR erfolgreich."
echo

# --------------------------------------------------
# 5. NACH PAPERLESS
# --------------------------------------------------

echo "Übertrage fertige PDF zu Paperless..."

if mv "$OCRFILE" "$FINALFILE"; then
    rm -f "$TMPFILE" "$REBUILDFILE"
    rm -rf "$WORKDIR"

    echo
    echo "======================================"
    echo " Scan erfolgreich!"
    echo "======================================"
    echo
    echo "PDF:"
    echo "$FINALFILE"
    echo
    echo "Paperless verarbeitet das Dokument jetzt."
else
    echo "Fehler beim Verschieben der PDF!"
    echo
    echo "OCR-PDF bleibt erhalten:"
    echo "$OCRFILE"
    exit 1
fi

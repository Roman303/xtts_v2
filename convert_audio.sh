#!/bin/bash
set -e

# Arbeitsverzeichnis setzen
INPUT_DIR="/xtts_v2/workspace/ready/speaker3"
OUTPUT_DIR="/xtts_v2/workspace/ready/speaker3/converted_files"

echo "🎵 Starte Audio-Konvertierung für XTTS Training..."
echo "Eingabe-Verzeichnis: $INPUT_DIR"
echo "Ausgabe-Verzeichnis: $OUTPUT_DIR"

# Zielverzeichnis erstellen
mkdir -p "$OUTPUT_DIR"

# In das Eingabeverzeichnis wechseln
cd "$INPUT_DIR"

# Alle WAV-Dateien konvertieren
for f in *.wav; do
    if [ -f "$f" ]; then
        echo "Konvertiere: $f"
        ffmpeg -i "$f" \
            -acodec pcm_s16le \
            -ac 1 \
            -ar 24000 \
            "$OUTPUT_DIR/${f%.wav}.wav"
    else
        echo "⚠️  Keine WAV-Dateien gefunden in: $INPUT_DIR"
        break
    fi
done

echo "✅ Konvertierung abgeschlossen!"
echo "Konvertierte Dateien in: $OUTPUT_DIR"
#!/bin/bash
set -e

echo "🚀 XTTS v2 Voice Cloning Setup für Vast.ai RTX 4090"

# Arbeitsverzeichnis festlegen
WORKSPACE="/workspace"
PROJECT_DIR="${WORKSPACE}/xtts_v2"

# 1) System-Pakete installieren
echo "📦 Installiere System-Dependencies..."
apt-get update -qq && apt-get install -y \
  git wget ffmpeg sox libsox-dev libsox-fmt-all \
  python3.10 python3.10-venv python3.10-dev \
  && rm -rf /var/lib/apt/lists/*

# 2) Projekt klonen
cd ${WORKSPACE}
if [ ! -d "xtts_v2" ]; then
  echo "📥 Klone dein Repository..."
  git clone https://github.com/Roman303/xtts_v2.git
fi
cd ${PROJECT_DIR}

# 3) Virtuelle Umgebung erstellen
if [ ! -d "venv" ]; then
  echo "🐍 Erstelle Python Virtual Environment..."
  python3.10 -m venv venv
fi
source venv/bin/activate

# 4) Pip upgraden
pip install --upgrade pip setuptools wheel

# 5) PyTorch mit CUDA 12.1 installieren
echo "🔥 Installiere PyTorch für RTX 4090..."
pip install torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121

# 6) Coqui TTS Repository klonen
cd ${WORKSPACE}
if [ ! -d "TTS" ]; then
  echo "📚 Klone Coqui TTS Repository..."
  git clone https://github.com/coqui-ai/TTS.git
  cd TTS
  git checkout v0.22.0
else
  cd TTS
  git pull
fi

# 7) TTS installieren (ohne coqui-tts aus requirements)
pip install -e .

# 8) Zusätzliche Requirements installieren (ohne coqui-tts)
cd ${PROJECT_DIR}
grep -v "coqui-tts" requirements_all.txt > requirements_filtered.txt
pip install -r requirements_filtered.txt

# 9) Verzeichnisstruktur prüfen/erstellen
echo "📁 Erstelle Verzeichnisstruktur..."
mkdir -p ${PROJECT_DIR}/data/speaker3
mkdir -p ${PROJECT_DIR}/configs
mkdir -p ${PROJECT_DIR}/outputs/checkpoints
mkdir -p ${PROJECT_DIR}/outputs/audio
mkdir -p ${PROJECT_DIR}/outputs/logs

# 10) XTTS v2 Basismodell herunterladen
echo "⬇️ Lade XTTS v2 Basismodell..."
python -c "
from TTS.api import TTS
import torch
print('Prüfe CUDA Verfügbarkeit:', torch.cuda.is_available())
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
print('Lade XTTS v2 Modell...')
tts = TTS('tts_models/multilingual/multi-dataset/xtts_v2')
print('✅ XTTS v2 erfolgreich geladen!')
"

# 11) Datenvalidierung
echo "🔍 Prüfe Trainingsdaten..."
if [ -f "${PROJECT_DIR}/data/speakers_all.csv" ]; then
  echo "✅ speakers_all.csv gefunden"
  head -5 ${PROJECT_DIR}/data/speakers_all.csv
else
  echo "⚠️ speakers_all.csv fehlt! Erstelle Beispiel..."
  cat > ${PROJECT_DIR}/data/speakers_all.csv <<EOL
audio_file|text|speaker_name
speaker3/audio_001.wav|Dies ist der erste Testsatz.|speaker3
speaker3/audio_002.wav|Noch ein Beispielsatz zum Testen.|speaker3
EOL
fi

# WAV-Dateien zählen
WAV_COUNT=$(find ${PROJECT_DIR}/data/speaker3 -name "*.wav" 2>/dev/null | wc -l)
echo "📊 Gefundene WAV-Dateien in speaker3: ${WAV_COUNT}"

echo "
✨ Setup abgeschlossen!
━━━━━━━━━━━━━━━━━━━━━
Aktiviere Environment: source ${PROJECT_DIR}/venv/bin/activate
Starte Training: bash train_xtts.sh
"

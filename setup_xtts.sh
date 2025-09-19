#!/bin/bash
set -e

echo "🚀 XTTS v2 Voice Cloning Setup für Vast.ai RTX 4090"

# Arbeitsverzeichnis festlegen
WORKSPACE="/workspace"
PROJECT_DIR="${WORKSPACE}/xtts_v2"

# 1) System-Pakete installieren (mit deadsnakes PPA für Python 3.10)
echo "📦 Installiere System-Dependencies..."
sudo add-apt-repository ppa:deadsnakes/ppa -y
sudo apt-get update -qq && sudo apt-get install -y \
  git wget ffmpeg sox libsox-dev libsox-fmt-all \
  python3.10 python3.10-venv python3.10-dev \
  && rm -rf /var/lib/apt/lists/*

# 2) Projektverzeichnis erstellen
cd ${WORKSPACE}
mkdir -p ${PROJECT_DIR}
cd ${PROJECT_DIR}

# 3) Virtuelle Umgebung erstellen (Python 3.10)
echo "🐍 Erstelle Python 3.10 Virtual Environment..."
if [ ! -d "venv" ]; then
  python3.10 -m venv venv
fi
source venv/bin/activate

# 4) Pip upgraden
pip install --upgrade pip setuptools wheel

# 5) PyTorch mit CUDA 12.1 installieren (für RTX 4090 optimiert) :cite[9]
echo "🔥 Installiere PyTorch für RTX 4090..."
pip install torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121

# 6) Coqui TTS Repository klonen (Community Fork) :cite[1]
cd ${WORKSPACE}
if [ ! -d "TTS" ]; then
  echo "📚 Klone Coqui TTS Repository..."
  git clone https://github.com/idiap/coqui-ai-TTS.git TTS
  cd TTS
  git checkout main  # Verwende main branch für aktuelle Version
else
  cd TTS
  git pull origin main
fi

# 7) TTS installieren (ohne coqui-tts aus requirements) :cite[2]
echo "🔧 Installiere Coqui TTS..."
pip install -e .[all]

# 8) Gefilterte Requirements installieren (ohne coqui-tts und mit korrigiertem numpy)
cd ${PROJECT_DIR}
# Erstelle korrigierte requirements ohne coqui-tts und mit numpy<1.25
grep -v "coqui-tts" requirements_all.txt | sed 's/numpy==1.26.4/numpy<1.25/' > requirements_filtered.txt
pip install -r requirements_filtered.txt

# 9) Verzeichnisstruktur erstellen
echo "📁 Erstelle Verzeichnisstruktur..."
mkdir -p ${PROJECT_DIR}/data/speaker3
mkdir -p ${PROJECT_DIR}/configs
mkdir -p ${PROJECT_DIR}/outputs/checkpoints
mkdir -p ${PROJECT_DIR}/outputs/audio
mkdir -p ${PROJECT_DIR}/outputs/logs

# 10) XTTS v2 Modell testen :cite[6]
echo "⬇️ Teste XTTS v2 Modellladung..."
python -c "
from TTS.api import TTS
import torch
print('✅ CUDA verfügbar:', torch.cuda.is_available())
if torch.cuda.is_available():
    print(f'✅ GPU: {torch.cuda.get_device_name(0)}')
try:
    tts = TTS('tts_models/multilingual/multi-dataset/xtts_v2')
    print('✅ XTTS v2 erfolgreich geladen!')
except Exception as e:
    print(f'❌ Fehler: {e}')
"

echo "
✨ Setup abgeschlossen!
━━━━━━━━━━━━━━━━━━━━━
Aktiviere Environment: source ${PROJECT_DIR}/venv/bin/activate
Trainingsdaten vorbereiten: ${PROJECT_DIR}/data/speaker3/
Starte Training: python train_xtts.py
"

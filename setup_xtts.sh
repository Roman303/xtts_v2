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

# 2) Projektverzeichnis prüfen
cd ${WORKSPACE}
if [ ! -d "xtts_v2" ]; then
  echo "❌ Projektverzeichnis ${PROJECT_DIR} nicht gefunden! Bitte zuerst git clone https://github.com/Roman303/xtts_v2.git ausführen."
  exit 1
fi
cd ${PROJECT_DIR}

# 3) Virtuelle Umgebung erstellen (Python 3.10)
echo "🐍 Erstelle Python 3.10 Virtual Environment..."
if [ ! -d "venv" ]; then
  python3.10 -m venv venv
fi
source venv/bin/activate

# 4) Pip upgraden
pip install --upgrade pip setuptools wheel

# 5) PyTorch mit CUDA 12.1 installieren (für RTX 4090 optimiert)
echo "🔥 Installiere PyTorch für RTX 4090..."
pip install torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121

# 6) Transformers Version installieren (kompatibel mit PyTorch 2.1.1)
echo "🔄 Installiere kompatible Transformers Version..."
pip install transformers==4.35.2

# 7) Coqui TTS Repository klonen (Community Fork)
cd ${WORKSPACE}
if [ ! -d "TTS" ]; then
  echo "📚 Klone Coqui TTS Repository..."
  git clone https://github.com/idiap/coqui-ai-TTS.git TTS
  cd TTS
  git checkout main
else
  cd TTS
  git pull origin main
fi

# 8) TTS installieren
echo "🔧 Installiere Coqui TTS..."
pip install -e .[all]

# 9) Gefilterte Requirements installieren
cd ${PROJECT_DIR}
# Korrigiere numpy Version für numba Kompatibilität und füge zusätzliche Deps hinzu
if [ -f "requirements_all.txt" ]; then
  grep -v "coqui-tts" requirements_all.txt | sed 's/numpy==1.26.4/numpy==1.24.4/' > requirements_filtered.txt
  echo "tensorboard>=2.11.0" >> requirements_filtered.txt  # Für Logging
  echo "deepspeed>=0.10.0" >> requirements_filtered.txt   # Für optionale Beschleunigung
  pip install -r requirements_filtered.txt
else
  echo "❌ requirements_all.txt nicht gefunden! Bitte sicherstellen, dass es im ${PROJECT_DIR} liegt."
  exit 1
fi

# 10) Verzeichnisstruktur erstellen
echo "📁 Erstelle Verzeichnisstruktur..."
mkdir -p ${PROJECT_DIR}/data/speaker3
mkdir -p ${PROJECT_DIR}/configs
mkdir -p ${PROJECT_DIR}/outputs/checkpoints
mkdir -p ${PROJECT_DIR}/outputs/audio
mkdir -p ${PROJECT_DIR}/outputs/logs
mkdir -p ${PROJECT_DIR}/scripts  # Für zukünftige Automationsskripte

# 11) XTTS v2 Modell testen
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
    print(f'❌ Fehler beim Laden: {e}')
    print('ℹ️  Dies kann am ersten Versuch normal sein, das Modell wird heruntergeladen...')
"

echo "
✨ Setup abgeschlossen!
━━━━━━━━━━━━━━━━━━━━━
Aktiviere Environment: source ${PROJECT_DIR}/venv/bin/activate
Trainingsdaten vorbereiten: ${PROJECT_DIR}/data/speaker3/
Starte Training: bash train_xtts.sh
"

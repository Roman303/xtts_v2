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

# 4) Pip upgraden und kritische Pakete installieren
echo "📦 Installiere Basis-Pakete..."
pip install --upgrade pip setuptools wheel
pip install setuptools<81  // Neu: Pin gegen pkg_resources-Warnung
pip install "numpy>=1.25.2,<2.0"
pip install numba>=0.59.0
pip install transformers==4.35.2 tokenizers==0.15.0

# 5) PyTorch mit CUDA 12.1 installieren
echo "🔥 Installiere PyTorch für RTX 4090..."
pip install torch==2.2.1 torchvision==0.17.1 torchaudio==2.2.1 --index-url https://download.pytorch.org/whl/cu121

# 6) Coqui TTS installieren
echo "🔧 Installiere Coqui TTS..."
pip install coqui-tts==0.26.0

# 7) Gefilterte Requirements installieren
cd ${PROJECT_DIR}
if [ -f "requirements_all.txt" ]; then
  echo "📋 Installiere restliche Requirements..."
  grep -v "numpy\|coqui-tts\|numba" requirements_all.txt > requirements_filtered.txt
  echo "tensorboard>=2.11.0" >> requirements_filtered.txt
  echo "deepspeed>=0.10.0" >> requirements_filtered.txt
  pip install -r requirements_filtered.txt
else
  echo "❌ requirements_all.txt nicht gefunden!"
  exit 1
fi

# 8) Verzeichnisstruktur erstellen
echo "📁 Erstelle Verzeichnisstruktur..."
mkdir -p ${PROJECT_DIR}/data/speaker3
mkdir -p ${PROJECT_DIR}/configs
mkdir -p ${PROJECT_DIR}/outputs/checkpoints
mkdir -p ${PROJECT_DIR}/outputs/audio
mkdir -p ${PROJECT_DIR}/outputs/logs
mkdir -p ${PROJECT_DIR}/scripts  # Für zukünftige Automationsskripte

# 9) XTTS v2 Modell testen
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

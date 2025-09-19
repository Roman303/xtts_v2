#!/bin/bash
set -e

echo "🔹 Starte Setup für XTTS v2 Voice Cloning..."

# 1) System-Pakete installieren (falls nicht vorhanden)
sudo apt-get update -qq && sudo apt-get install -y \
  git wget ffmpeg sox libsox-dev libsox-fmt-all \
  python3.11 python3.11-venv python3.11-dev \
  && rm -rf /var/lib/apt/lists/*

# 2) Virtuelle Umgebung erstellen (falls nicht vorhanden)
cd /workspace
if [ ! -d "tts-env" ]; then
  python3.11 -m venv tts-env
fi
source tts-env/bin/activate

# 3) Pip upgraden
pip install --upgrade pip setuptools wheel

# 4) PyTorch mit CUDA 12.1 installieren (vor TTS!)
pip install torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121

# 5) Coqui-TTS (idiap Fork, main Branch)
if [ ! -d "TTS" ]; then
  git clone https://github.com/idiap/coqui-ai-TTS.git TTS
fi
cd TTS
git checkout main
git pull
pip install -e .[all]

# 6) Kompatible Versionen von numpy & numba fixieren
pip install --upgrade numpy==1.26.4 numba==0.58.1 transformers==4.33.3

# 7) Zusätzliche Anforderungen aus deinem Repo
cd /workspace/my-voice-project
if [ -f "requirements_all.txt" ]; then
  pip install -r requirements_all.txt
fi

# 8) Daten und Configs ins Workspace kopieren
if [ -d "data" ]; then
  mkdir -p /workspace/data
  cp -r data/* /workspace/data/
fi

if [ -d "configs" ]; then
  mkdir -p /workspace/configs
  cp -r configs/* /workspace/configs/
fi

# 9) Lizenz automatisch akzeptieren
export COQUI_TOS_AGREED=1

# 🔟 Testlauf
python - <<'EOF'
import torch
from TTS.api import TTS
print("✅ PyTorch:", torch.__version__, "CUDA:", torch.cuda.is_available())
print("✅ TTS Version:", __import__('TTS').__version__)
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)
print("✅ XTTS v2 geladen und Lizenz akzeptiert!")
EOF

echo "🎉 Setup abgeschlossen! Aktiviere die venv mit:"
echo "source /workspace/tts-env/bin/activate"

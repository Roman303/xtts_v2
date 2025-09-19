#!/bin/bash
set -e

echo "🔹 Starte Setup für XTTS v2 Voice Cloning..."

# 1) System-Pakete (falls nicht schon vorhanden)
sudo apt-get update -qq && sudo apt-get install -y \
  git wget ffmpeg sox libsox-dev libsox-fmt-all \
  python3.11 python3.11-venv python3.11-dev \
  && rm -rf /var/lib/apt/lists/*

# 2) Virtuelle Umgebung erstellen
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

# 6) Zusätzliche Anforderungen aus requirements.txt
cd /workspace
pip install -r requirements.txt

# 7) Datenverzeichnisse für Sprecher
mkdir -p /workspace/data/speaker1
mkdir -p /workspace/data/speaker2
mkdir -p /workspace/data/speaker3

# 8) Testlauf
python - <<'EOF'
import torch
from TTS.api import TTS
print("✅ TTS importiert")
print("PyTorch Version:", torch.__version__)
print("CUDA verfügbar:", torch.cuda.is_available())
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)
print("✅ XTTS v2 geladen!")
EOF

echo "🎉 Setup abgeschlossen! Aktiviere die venv mit:"
echo "source /workspace/tts-env/bin/activate"

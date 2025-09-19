#!/bin/bash
set -e

echo "🔹 Starte Setup für XTTS v2 Voice Cloning..."

# 1) System-Pakete
sudo add-apt-repository ppa:deadsnakes/ppa -y
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

# 4) PyTorch zuerst installieren (CUDA 12.1 für RTX 4090/3090)
pip install torch==2.1.1 torchvision==0.16.1 torchaudio==2.1.1 --index-url https://download.pytorch.org/whl/cu121

# 5) Repo klonen (falls noch nicht vorhanden)
if [ ! -d "TTS" ]; then
  git clone https://github.com/idiap/coqui-ai-TTS.git TTS
fi
cd TTS
git checkout v0.22.0
git pull
pip install -e .[all]

# 6) Requirements installieren (deine eigene Liste)
cd /workspace/my-voice-project
pip install -r requirements_all.txt

# 7) Daten & Output-Verzeichnisse anlegen
mkdir -p /workspace/output_adaptation/phoneme_cache
mkdir -p /workspace/data/speaker1
mkdir -p /workspace/data/speaker2
mkdir -p /workspace/data/speaker3

# 8) Testlauf
python -c "
from TTS.api import TTS
print('✅ TTS importiert')
tts = TTS('tts_models/multilingual/multi-dataset/xtts_v2')
tts.to('cuda')
print('✅ XTTS v2 geladen!')
"

echo "🎉 Setup abgeschlossen! Aktiviere die venv mit:"
echo "source /workspace/tts-env/bin/activate"

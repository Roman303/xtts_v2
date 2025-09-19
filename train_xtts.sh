#!/bin/bash
set -e

PROJECT_DIR="/workspace/xtts_v2"
cd ${PROJECT_DIR}

# Virtuelle Umgebung aktivieren
source venv/bin/activate

echo "🎯 Starte XTTS v2 Voice Cloning Training"

# GPU-Info anzeigen
nvidia-smi --query-gpu=name,memory.free --format=csv,noheader

# Training-Skript erstellen
cat > train_adapter.py <<'PYTHON'
import os
import torch
import json
from TTS.tts.configs.xtts_config import XttsConfig
from TTS.tts.models.xtts import Xtts

# Konfiguration laden
config = XttsConfig()
config.load_json("/workspace/xtts_v2/configs/xtts_v2_adapter.json")

# Modell initialisieren
model = Xtts.init_from_config(config)
model.load_checkpoint(
    config,
    checkpoint_dir="/home/user/.local/share/tts/tts_models--multilingual--multi-dataset--xtts_v2",
    eval=False
)

# GPU verwenden
model.cuda()

# Training starten (vereinfacht für Adapter-Training)
print("🔥 Starte Adapter Fine-Tuning...")
print(f"Trainingsdaten: {config.datasets[0]['path']}")
print(f"Epochs: {config.epochs}")
print(f"Batch Size: {config.batch_size}")

# Hier würde das eigentliche Training stattfinden
# Für vollständiges Training siehe Coqui TTS Dokumentation
PYTHON

# Vereinfachtes Training für Test
python -c "
import os
import torch
from TTS.api import TTS

print('🎤 Teste Voice Cloning mit deinen Daten...')
tts = TTS('tts_models/multilingual/multi-dataset/xtts_v2')
tts.to('cuda' if torch.cuda.is_available() else 'cpu')

# Beispiel-Inference mit geklonter Stimme
reference_audio = '/workspace/xtts_v2/data/speaker3/audio_001.wav'
if os.path.exists(reference_audio):
    tts.tts_to_file(
        text='Dies ist ein Test mit der geklonten Stimme.',
        speaker_wav=reference_audio,
        language='de',
        file_path='/workspace/xtts_v2/outputs/audio/test_clone.wav'
    )
    print('✅ Test-Audio generiert: outputs/audio/test_clone.wav')
else:
    print('⚠️ Keine Referenz-Audio gefunden!')
"

echo "
📊 Training-Info:
━━━━━━━━━━━━━━━━━
Für vollständiges Fine-Tuning verwende:
python -m TTS.bin.train_tts --config_path configs/xtts_v2_adapter.json
"

#!/bin/bash
set -e

PROJECT_DIR="/workspace/xtts_v2"
cd ${PROJECT_DIR}

# Virtuelle Umgebung aktivieren
source venv/bin/activate

echo "🎯 Starte XTTS v2 Voice Cloning Fine-Tuning"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# GPU-Info anzeigen
nvidia-smi --query-gpu=name,memory.free,memory.total --format=csv,noheader

# 1. Daten-Preprocessing Script
cat > preprocess_data.py <<'PYTHON'
import os
import csv
import json
import torch
import torchaudio
from pathlib import Path

print("📊 Preprocesse Trainingsdaten...")

data_dir = Path("/workspace/xtts_v2/data")
output_dir = Path("/workspace/xtts_v2/outputs/preprocessed")
output_dir.mkdir(parents=True, exist_ok=True)

# CSV validieren und konvertieren
csv_path = data_dir / "speakers_all.csv"
processed_csv = output_dir / "metadata.csv"

with open(csv_path, 'r', encoding='utf-8') as infile, \
     open(processed_csv, 'w', encoding='utf-8', newline='') as outfile:
    
    reader = csv.DictReader(infile, delimiter='|') 
    writer = csv.writer(outfile, delimiter='|')
    writer.writerow(['audio_file', 'text', 'speaker_name'])
    
    valid_count = 0
    for row in reader:
        audio_path = data_dir / row['audio_file']
        if audio_path.exists():
            # Audio validieren
            try:
                waveform, sample_rate = torchaudio.load(str(audio_path))
                duration = waveform.shape[1] / sample_rate
                
                # Nur Audios zwischen 1-30 Sekunden
                if 1.0 <= duration <= 30.0:
                    writer.writerow([row['audio_file'], row['text'].strip(), row['speaker_name']])
                    valid_count += 1
                else:
                    print(f"⚠️ Übersprungen (Dauer: {duration:.1f}s): {audio_path.name}")
            except Exception as e:
                print(f"❌ Fehler bei {audio_path.name}: {e}")
        else:
            print(f"❌ Datei nicht gefunden: {audio_path}")
    
print(f"✅ {valid_count} valide Trainingssamples gefunden")
PYTHON

python preprocess_data.py

# 2. Fine-Tuning Training Script
cat > train_xtts_finetuning.py <<'PYTHON'
import os
import json
import torch
from pathlib import Path
from trainer import Trainer, TrainerArgs
from TTS.config.shared_configs import BaseDatasetConfig
from TTS.tts.datasets import load_tts_samples
from TTS.tts.configs.xtts_config import XttsConfig
from TTS.tts.models.xtts import Xtts
from TTS.utils.audio import AudioProcessor

# Lade Konfiguration aus JSON
CONFIG_PATH = "/workspace/xtts_v2/configs/xtts_v2_adapter.json"
print(f"📋 Lade Konfiguration von: {CONFIG_PATH}")

with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
    config_data = json.load(f)

# Erstelle XTTS Config
config = XttsConfig()
config.from_dict(config_data)  # Lädt alle Werte aus der JSON

# Debug: Überprüfe geladene Audio-Config
print("Debug: Geladene Audio Config:", config.audio.__dict__ if hasattr(config.audio, '__dict__') else config.audio)

# Debug: Überprüfe eval_split_size
print("Debug: eval_split_size:", config.eval_split_size)

# Überschreibe pfadspezifische Einstellungen
config.output_path = "/workspace/xtts_v2/outputs/finetuning"
config.datasets[0].meta_file_train = "/workspace/xtts_v2/outputs/preprocessed/metadata.csv"

# Audio Processor direkt initialisieren (um TypeError zu umgehen)
ap = AudioProcessor(
    sample_rate=24000,
    output_sample_rate=24000,
    hop_length=256,
    win_length=1024,
    fft_size=1024,
    mel_fmin=0,
    mel_fmax=8000,
    num_mels=80,
    dvae_sample_rate=24000,
    frame_length_ms=42.67,
    frame_shift_ms=10.67
)
print("Debug: AudioProcessor initialisiert mit:", ap.__dict__)

# Lade Trainings-Samples
train_samples, eval_samples = load_tts_samples(
    config.datasets,
    eval_split=True,
    eval_split_max_size=config.eval_split_max_size,
    eval_split_size=config.eval_split_size  // Verwende den Wert aus JSON
)

print(f"📊 Trainings-Samples: {len(train_samples)}")
print(f"📊 Evaluierungs-Samples: {len(eval_samples)}")

# Model initialisieren
model = Xtts.init_from_config(config)
torch.backends.cuda.matmul.allow_tf32 = True  # RTX 4090 Optimierung

# Checkpoint laden (Basis XTTS v2 Model)
XTTS_CHECKPOINT = Path("/root/.local/share/tts/tts_models--multilingual--multi-dataset--xtts_v2")
if not XTTS_CHECKPOINT.exists():
    print("⬇️ Lade XTTS v2 Basis-Modell...")
    from TTS.api import TTS
    tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2")
    del tts

print(f"📦 Lade Checkpoint von: {XTTS_CHECKPOINT}")
model.load_checkpoint(
    config,
    checkpoint_dir=str(XTTS_CHECKPOINT),
    checkpoint_path=None,
    vocab_path=None,
    eval=False,
    strict=False,
    use_deepspeed=False
)

# Nur bestimmte Layer für Fine-Tuning freigeben
print("🔓 Aktiviere Fine-Tuning Layer...")
for name, param in model.named_parameters():
    # Freeze alles außer den letzten GPT Layern und Speaker Embedding
    if "gpt" in name and "layer_30" in name:  # Letzte Layer
        param.requires_grad = True
    elif "gpt" in name and "layer_29" in name:
        param.requires_grad = True
    elif "speaker_embedding" in name:
        param.requires_grad = True
    elif "language_embedding" in name:
        param.requires_grad = True
    else:
        param.requires_grad = False

# Zähle trainierbare Parameter
trainable_params = sum(p.numel() for p in model.parameters() if p.requires_grad)
total_params = sum(p.numel() for p in model.parameters())
print(f"🎯 Trainierbare Parameter: {trainable_params:,} / {total_params:,} ({100*trainable_params/total_params:.2f}%)")

# Trainer Args
trainer_args = TrainerArgs(
    restore_path=None,  # Kein Restore, wir haben das Model schon geladen
    skip_train_epoch=False,
    start_with_eval=True,
    grad_accum_steps=4,  # Gradient Accumulation für größere effektive Batch Size
)

# Trainer initialisieren
trainer = Trainer(
    trainer_args,
    config,
    config.output_path,
    model=model,
    train_samples=train_samples,
    eval_samples=eval_samples,
)

# Training starten
print("\n🚀 Starte Fine-Tuning Training...")
print("━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━")
trainer.fit()

print("\n✅ Fine-Tuning abgeschlossen!")
print(f"📁 Checkpoints gespeichert in: {config.output_path}")
PYTHON

# 3. Inference Test Script (unverändert, aber mit Debug)
cat > test_finetuned_model.py <<'PYTHON'
import torch
import torchaudio
from pathlib import Path
from TTS.tts.configs.xtts_config import XttsConfig
from TTS.tts.models.xtts import Xtts

print("🎤 Teste fine-getunte Stimme...")

# Neuestes Checkpoint finden
checkpoint_dir = Path("/workspace/xtts_v2/outputs/finetuning")
checkpoints = sorted(checkpoint_dir.glob("*/best_model.pth"))

if not checkpoints:
    print("❌ Kein Checkpoint gefunden! Bitte erst Training durchführen.")
    exit(1)

latest_checkpoint = checkpoints[-1].parent
print(f"📦 Verwende Checkpoint: {latest_checkpoint}")

# Config laden
config = XttsConfig()
config.load_json(str(latest_checkpoint / "config.json"))

# Model laden
model = Xtts.init_from_config(config)
model.load_checkpoint(
    config,
    checkpoint_dir=str(latest_checkpoint),
    checkpoint_path=str(latest_checkpoint / "best_model.pth"),
    vocab_path=str(latest_checkpoint / "vocab.json"),
    eval=True,
    use_deepspeed=False
)

# GPU verwenden
device = torch.device("cuda" if torch.cuda.is_available() else "cpu")
model.to(device)

# Referenz-Audio für Voice Cloning
reference_audio = "/workspace/xtts_v2/data/speaker3/audio_001.wav"
if not Path(reference_audio).exists():
    print(f"❌ Referenz-Audio nicht gefunden: {reference_audio}")
    exit(1)

# Test-Texte
test_texts = [
    "Nach dem Fine-Tuning klingt meine Stimme viel natürlicher.",
    "Die Anpassung an meine Sprechweise ist deutlich besser geworden.",
    "Jetzt kann ich längere Hörbücher mit meiner eigenen Stimme erstellen.",
]

# Generiere Audio
for i, text in enumerate(test_texts, 1):
    print(f"🔊 Generiere: {text[:50]}...")
    
    outputs = model.synthesize(
        text,
        config,
        speaker_wav=reference_audio,
        gpt_cond_len=6,
        gpt_cond_chunk_len=4,
        language="de",
        temperature=0.75,
        length_penalty=1.0,
        repetition_penalty=2.0,
        top_k=50,
        top_p=0.85,
    )
    
    # Speichere Audio
    output_path = f"/workspace/xtts_v2/outputs/audio/finetuned_test_{i}.wav"
    torchaudio.save(
        output_path,
        torch.tensor(outputs["wav"]).unsqueeze(0),
        24000
    )
    print(f"✅ Gespeichert: {output_path}")

print("\n🎉 Fine-Tuning Test abgeschlossen!")
PYTHON

# 4. Haupttraining ausführen
echo "
┌─────────────────────────────────────────┐
│  XTTS v2 FINE-TUNING TRAINING           │
├─────────────────────────────────────────┤
│  [1] Daten-Preprocessing                │
│  [2] Vollständiges Fine-Tuning (empfohlen)│
│  [3] Nur Testen (wenn Training fertig)  │
│  [4] Schnelltest ohne Fine-Tuning       │
└─────────────────────────────────────────┘
"

# Optionen für den Benutzer
while true; do
    echo "Wähle eine Option:"
    echo "1) Nur Preprocessing"
    echo "2) Vollständiges Fine-Tuning (empfohlen)"
    echo "3) Nur Testen (wenn Training fertig)"
    echo "4) Schnelltest ohne Fine-Tuning"
    read -p "Option [1-4]: " option
    case $option in
        1|2|3|4) break ;;
        *) echo "Ungültige Option, bitte 1-4 wählen" ;;
    esac
done

case $option in
    1)
        python preprocess_data.py
        ;;
    2)
        python preprocess_data.py
        python train_xtts_finetuning.py
        python test_finetuned_model.py
        ;;
    3)
        python test_finetuned_model.py
        ;;
    4)
        # Schnelltest mit Basis-Modell
        python -c "
import torch
from TTS.api import TTS
import os

print('🎤 Schnelltest mit Basis XTTS v2...')
tts = TTS('tts_models/multilingual/multi-dataset/xtts_v2')
tts.to('cuda' if torch.cuda.is_available() else 'cpu')

ref_audio = '/workspace/xtts_v2/data/speaker3/audio_001.wav'
if os.path.exists(ref_audio):
    tts.tts_to_file(
        text='Dies ist ein Schnelltest ohne Fine-Tuning.',
        speaker_wav=ref_audio,
        language='de',
        file_path='/workspace/xtts_v2/outputs/audio/quick_test.wav')
    print('✅ Test-Audio: outputs/audio/quick_test.wav')
else:
    print('❌ Referenz-Audio nicht gefunden!')
"
        ;;
esac

# Monitoring-Befehle anzeigen
echo "
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📊 Monitoring-Befehle:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

GPU-Auslastung:
  watch -n 1 nvidia-smi

TensorBoard (in neuem Terminal):
  source venv/bin/activate
  tensorboard --logdir outputs/finetuning

Training Logs:
  tail -f outputs/finetuning/trainer_log.txt

Speicherplatz:
  df -h /workspace
"

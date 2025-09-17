from TTS.api import TTS
import os

# Modell laden (XTTS-v2, Multilingual)
# Falls beim ersten Mal der Download zu lange dauert:
# -> Modell vorher mit wget von HuggingFace holen und in /workspace/models speichern
print("🔄 Lade Modell XTTS-v2 ...")
tts = TTS("tts_models/multilingual/multi-dataset/xtts_v2", gpu=True)

# Pfade
speaker_wav = "/workspace/data/speaker1/voice.wav"
output_path = "/workspace/output.wav"

# Check ob Speaker-WAV existiert
if not os.path.isfile(speaker_wav):
    raise FileNotFoundError(f"⚠️ Speaker-Datei fehlt: {speaker_wav}")

# Text (deutsch)
text = "Hallo, dies ist ein Test mit meiner geklonten Stimme. Willkommen bei meinem Hörbuch-Projekt."

print(f"🎤 Erzeuge Sprache mit Stimme aus: {speaker_wav}")
tts.tts_to_file(
    text=text,
    file_path=output_path,
    speaker_wav=speaker_wav,
    language="de"
)

print(f"✅ Fertig! Datei gespeichert unter: {output_path}")

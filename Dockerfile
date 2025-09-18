# VERWENDE DIESE VERSION - Korrigiertes Dockerfile
# NVIDIA PyTorch Image mit Python 3.10 und CUDA (Dieses Image hat bereits alles)
FROM nvcr.io/nvidia/pytorch:24.01-py3

# Systempakete installieren (NUR was nicht schon im Image ist)
RUN apt-get update && apt-get install -y \
    git wget ffmpeg sox libsox-dev libsox-fmt-all && \
    rm -rf /var/lib/apt/lists/*

# Arbeitsverzeichnis setzen
WORKDIR /workspace

# --- Coqui-TTS klonen und installieren (XTTS-v2 Unterstützung) ---
# Nutze den speziellen Branch/Tag für XTTS-v2, nicht main!
RUN git clone https://github.com/coqui-ai/TTS.git && \
    cd TTS && git checkout v0.22.0 && pip install -e .[all]

# --- Requirements für XTTS, Mistral, Stable Diffusion ---
# Kopiere die Requirements und installiere sie
COPY requirements_all.txt /workspace/requirements_all.txt
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r /workspace/requirements_all.txt

# --- Configs vorbereiten ---
RUN mkdir -p /workspace/configs && \
    wget https://raw.githubusercontent.com/coqui-ai/TTS/v0.22.0/TTS/configs/xtts_v2_adapter.json \
    -O /workspace/configs/xtts_v2_adapter.json

# --- Datenstruktur für Sprecher ---
RUN mkdir -p /workspace/data/speaker1 \
    && mkdir -p /workspace/data/speaker2 \
    && mkdir -p /workspace/data/speaker3

# Standard-Startbefehl
CMD ["/bin/bash"]

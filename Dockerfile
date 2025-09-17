# NVIDIA PyTorch Image mit Python 3.10 und CUDA
FROM nvcr.io/nvidia/pytorch:24.01-py3

# Systempakete installieren
RUN apt-get update && apt-get install -y \
    git wget ffmpeg sox libsox-dev libsox-fmt-all python3.10 python3.10-venv python3.10-dev && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    rm -rf /var/lib/apt/lists/*

# Arbeitsverzeichnis setzen
WORKDIR /workspace

# --- Coqui-TTS klonen und installieren (XTTS-v2 Unterstützung) ---
RUN git clone https://github.com/coqui-ai/TTS.git && \
    cd TTS && pip install -e .

# --- Requirements für XTTS, Mistral, Stable Diffusion ---
COPY requirements_all.txt /workspace/requirements_all.txt
RUN pip install --upgrade pip setuptools wheel && \
    pip install -r /workspace/requirements_all.txt

# --- Configs vorbereiten ---
RUN mkdir -p /workspace/configs && \
    wget https://raw.githubusercontent.com/coqui-ai/TTS/main/TTS/configs/xtts_v2_adapter.json \
    -O /workspace/configs/xtts_v2_adapter.json

# --- Datenstruktur für Sprecher ---
RUN mkdir -p /workspace/data/speaker1 \
    && mkdir -p /workspace/data/speaker2 \
    && mkdir -p /workspace/data/speaker3

# Falls du eigene Daten ins Image packen willst
# COPY data/ /workspace/data/

# Standard-Startbefehl
CMD ["/bin/bash"]

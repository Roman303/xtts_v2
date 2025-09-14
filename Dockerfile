# Basis: offizielles PyTorch mit CUDA 12.8 (enthält torch & torchaudio kompatibel)
FROM pytorch/pytorch:2.5.1-cuda12.1-cudnn9-runtime

# Meta
LABEL maintainer="deinname <dein.email@example.com>"

# Arbeitsverzeichnis
WORKDIR /workspace

# Coqui-TTS klonen und installieren
RUN git clone --depth 1 https://github.com/coqui-ai/TTS.git /workspace/TTS
WORKDIR /workspace/TTS
RUN pip install -e .

# Systemtools
RUN apt-get update && apt-get install -y \
    git ffmpeg sox libsndfile1 build-essential wget ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Pip Upgrade und Fixes
RUN pip install --upgrade pip setuptools wheel

# Cython Version (Coqui TTS braucht 0.29.x)
RUN pip install cython==0.29.36

# Coqui-TTS klonen und installieren
RUN git clone --depth 1 https://github.com/coqui-ai/TTS.git /workspace/TTS
WORKDIR /workspace/TTS
# Installiere TTS (nutzt bereits im Image vorhandene torch/torchaudio)
RUN pip install -e .

# Zusätzliche Python-Pakete nützlich für Audio/Preproc
RUN pip install soundfile librosa fsspec

# Erstelle Standardordner
RUN mkdir -p /workspace/data /workspace/configs /workspace/output_adaptation /workspace/samples

# Kopiere die Config in das Image (falls vorhanden im Repo)
# Wenn du die Config in GitHub liegen hast, wird COPY sie übernehmen.
COPY configs/xtts_v2_adapter.json /workspace/configs/xtts_v2_adapter.json

# Optional: kleines Entrypoint-Skript (führt bash als default)
WORKDIR /workspace
CMD [ "/bin/bash" ]



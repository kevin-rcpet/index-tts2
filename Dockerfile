# Use NVIDIA CUDA base image with Ubuntu 22.04 (devel variant includes nvcc and CUDA dev tools)
FROM nvidia/cuda:12.8.0-devel-ubuntu22.04

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    UV_SYSTEM_PYTHON=1 \
    PATH="/root/.local/bin:$PATH"

# Install system dependencies
RUN apt-get update && apt-get install -y \
    software-properties-common \
    git \
    git-lfs \
    ffmpeg \
    libsndfile1 \
    curl \
    wget \
    ca-certificates \
    && add-apt-repository ppa:deadsnakes/ppa -y \
    && apt-get update \
    && apt-get install -y \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    && rm -rf /var/lib/apt/lists/*

# Install uv package manager
RUN curl -LsSf https://astral.sh/uv/install.sh | sh

# Set working directory
WORKDIR /app

# Copy project files
COPY pyproject.toml uv.lock README.md ./
COPY indextts ./indextts
COPY tools ./tools
COPY examples ./examples
COPY webui.py ./
COPY .python-version ./

# Create necessary directories
RUN mkdir -p checkpoints outputs prompts

# Install Python dependencies
RUN uv sync --all-extras --frozen

# Expose port for web UI
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# Default command
CMD ["uv", "run", "webui.py", "--host", "0.0.0.0", "--port", "7860"]

# Minimal Ubuntu 26.04 runtime image matching the host's glibc and Mesa Intel Arc
# Vulkan driver so the compiled Qwen3-ASR ggml-vulkan library runs natively in k3s.
FROM ubuntu:26.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    libvulkan1 \
    mesa-vulkan-drivers \
    && rm -rf /var/lib/apt/lists/*

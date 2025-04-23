#!/bin/bash

set -e

DEFAULT_NUMA_FLAG=False

NUMA_FLAG=${1:-$DEFAULT_NUMA_FLAG}


echo "ktrans speed test start!"
if [ "$NUMA_FLAG" = "True" ] || [ "$NUMA_FLAG" = "true" ]; then
    bash DeepSeek-R1-GGML-FP8-Hybrid.sh
    bash DeepSeek-R1-GGUF-Q4_K_M-amx.sh
    bash DeepSeek-V3-GGML-FP8-Hybrid.sh
    bash DeepSeek-V3-Q4_K_M-amx.sh
else 
    bash DeepSeek-R1-GGUF-Q4_K_M.sh
    bash DeepSeek-V3-Q4_K_M.sh
fi

echo "ktrans speed test finished!"
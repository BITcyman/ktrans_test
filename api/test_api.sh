DEFAULT_NUMA_FLAG=False

NUMA_FLAG=${1:-$DEFAULT_NUMA_FLAG}

echo "ktrans api test start!"
if [ "$NUMA_FLAG" = "True" ] || [ "$NUMA_FLAG" = "true" ]; then
    bash DeepSeek-R1-GGUF-Q4_K_M-amx.sh
else 
    bash DeepSeek-R1-GGUF-Q4_K_M.sh
fi
echo "ktrans api test finished!"
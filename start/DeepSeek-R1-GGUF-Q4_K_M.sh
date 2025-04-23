# /bin/bash
eval "$(conda shell.bash hook)"

mkdir -p  output
cd output

mkdir -p DeepSeek-R1-GGUF-Q4_K_M
cd DeepSeek-R1-GGUF-Q4_K_M

conda activate ktransformers 
python -m ktransformers.server.main \
    --host 0.0.0.0 --port 36666 \
    --backend_type balance_serve \
    --model_name DeepSeek-R1-GGUF-Q4_K_M \
    --model_path /mnt/data/models/DeepSeek-R1-GGUF-Q4_K_M/config \
    --gguf_path /mnt/data/models/DeepSeek-R1-GGUF-Q4_K_M \
    --cache_len 131072 \
    --max_new_tokens 8192 \
    --force_think \
    --optimize_config_path /app/ktransformers/ktransformers/optimize/optimize_rules/DeepSeek-V3-Chat-serve.yaml \
    > ktrans.log 2>&1 &

pid1=$!  # 获取第一个后台进程的 PID

# 定义一个函数，在脚本退出时调用
cleanup() {
    kill $pid1  # 杀死第一个脚本
    wait $pid1  # 等待第一个脚本真正退出
}

python ../../ktrans_start_test.py \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    > testpy.log 2>&1 & 

pid2=$!  
trap 'cleanup' SIGTERM SIGINT

wait $pid2
cleanup

cd ../../
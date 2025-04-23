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


for concurrent in 1 2 4 8; do
    for prompt_lens in 1024 2048; do
        for max_tokens in 128 512; do \
            python ../../test_speed.py \
                --concurrent $concurrent \
                --prompt_lens $prompt_lens \
                --port 36666 \
                --max_tokens $max_tokens \
                >> "testpy.log" 2>&1
            
            echo "运行完成：concurrent=${concurrent}, prompt_lens=${prompt_lens}, max_tokens=${max_tokens}"
        done
    done
done

cleanup

cd ../../
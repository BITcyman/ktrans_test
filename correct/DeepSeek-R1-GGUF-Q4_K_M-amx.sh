# /bin/bash
eval "$(conda shell.bash hook)"

mkdir -p  output
cd output

mkdir -p DeepSeek-R1-GGUF-Q4_K_M
cd DeepSeek-R1-GGUF-Q4_K_M

mamba activate ktransformers 
python -m ktransformers.server.main \
    --host 0.0.0.0 --port 36666 \
    --backend_type balance_serve \
    --model_name DeepSeek-R1-GGUF-Q4_K_M \
    --model_path /mnt/data/models/DeepSeek-R1-GGUF-Q4_K_M/config \
    --gguf_path /mnt/data/models/DeepSeek-R1-GGUF-Q4_K_M \
    --cache_len 131072 \
    --max_new_tokens 8192 \
    --force_think \
    --optimize_config_path /app/ktransformers/ktransformers/optimize/optimize_rules/DeepSeek-V3-Chat-amx-serve.yaml \
    > ktrans.log 2>&1 &

pid1=$!  # 获取第一个后台进程的 PID


# 定义一个函数，在脚本退出时调用
cleanup() {
    kill $pid1  # 杀死第一个脚本
    wait $pid1  # 等待第一个脚本真正退出
}

sleep 1800

export HF_ENDPOINT=https://hf-mirror.com

# human_eval 测试
mkdir -p human_eval
cd human_eval

# 单并发测试
python ../../../humaneval.py \
    --api_url http://localhost:36666/v1/chat/completions \
    --model_name DeepSeek-R1-GGUF-Q4_K_M \
    --out_path eval.jsonl

# 多并发测试
python ../../../humaneval.py \
    --api_url http://localhost:36666/v1/chat/completions \
    --model_name DeepSeek-R1-GGUF-Q4_K_M \
    --out_path eval_concu.jsonl

echo "human_eval 测试结束，开始 aime 测试"

# 获取最终的分数
evaluate_functional_correctness results/api/eval.jsonl > eval.log
evaluate_functional_correctness results/api/eval_concu.jsonl > eval_concu.log

cd ..

# mmlu 测试
mkdir -p mmlu
cd mmlu

# 单并发测试
python ../../../mmlu.py \
    --api_url http://localhost:36666/v1/chat/completions \
    --result ./mmlu.jsonl \
    --log ./mmlu.log \
    --model DeepSeek-R1-GGUF-Q4_K_M 

# 多并发测试
python ../../../mmlu_concu.py \
    --api_url http://localhost:36666/v1/chat/completions \
    --result ./mmlu_concu.jsonl \
    --log ./mmlu_concu.log \
    --model DeepSeek-R1-GGUF-Q4_K_M 


cleanup
cd ../../
# /bin/bash
eval "$(conda shell.bash hook)"

mkdir -p  output
cd output

mkdir -p DeepSeek-V3-GGML-FP8-Hybrid
cd DeepSeek-V3-GGML-FP8-Hybrid

conda activate ktransformers 
python -m ktransformers.server.main \
    --host 0.0.0.0 --port 36666 \
    --backend_type balance_serve \
    --model_name DeepSeek-V3-GGML-FP8-Hybrid \
    --model_path /mnt/data/models/DeepSeek-V3-GGML-FP8-Hybrid/config \
    --gguf_path /mnt/data/models/DeepSeek-V3-GGML-FP8-Hybrid \
    --cache_len 131072 \
    --max_new_tokens 8192 \
    --optimize_config_path /app/ktransformers/ktransformers/optimize/optimize_rules/DeepSeek-V3-Chat-serve.yaml \
    > ktrans.log 2>&1 &

pid1=$!  # 获取第一个后台进程的 PID

# 定义一个函数，在脚本退出时调用
cleanup() {
    kill $pid1  # 杀死第一个脚本
    wait $pid1  # 等待第一个脚本真正退出
}

export HF_ENDPOINT=https://hf-mirror.com

# human_eval 测试
mkdir -p human_eval
cd human_eval

# 单并发测试
python ../../../humaneval.py \
    --port 36666 \
    --model_name DeepSeek-V3-GGML-FP8-Hybrid \
    --out_path ./eval.jsonl

# 多并发测试
python ../../../humaneval_concu.py \
    --port 36666 \
    --model_name DeepSeek-V3-GGML-FP8-Hybrid \
    --out_path ./eval_concu.jsonl

echo "human_eval 测试结束，开始 aime 测试"

# 获取最终的分数
evaluate_functional_correctness ./eval.jsonl > ./eval.log
evaluate_functional_correctness ./eval_concu.jsonl > ./eval_concu.log

cd ..

# mmlu 测试
mkdir -p mmlu
cd mmlu

# 单并发测试
python ../../../mmlu.py \
    --port 36666 \
    --result ./mmlu.jsonl \
    --log ./mmlu.log \
    --model DeepSeek-V3-GGML-FP8-Hybrid 

# 多并发测试
python ../../../mmlu_concu.py \
    --port 36666 \
    --result ./mmlu_concu.jsonl \
    --log ./mmlu_concu.log \
    --model DeepSeek-V3-GGML-FP8-Hybrid 


cleanup
cd ../../
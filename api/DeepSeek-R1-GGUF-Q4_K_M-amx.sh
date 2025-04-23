# /bin/bash
eval "$(conda shell.bash hook)"

mkdir -p  output
cd output

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
    --optimize_config_path /app/ktransformers/ktransformers/optimize/optimize_rules/DeepSeek-V3-Chat-amx-serve.yaml \
    > ktrans.log 2>&1 &

pid1=$!  # 获取第一个后台进程的 PID


# 定义一个函数，在脚本退出时调用
cleanup() {
    kill $pid1  # 杀死第一个脚本
    wait $pid1  # 等待第一个脚本真正退出
}

echo "ktrans api test" > api.log

# 测试 stream 是否有效
echo "=====================" >> api.log
echo "stream == false " >> api.log
python ../test_api.py \
    --question_id 0 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream false \
    --max_tokens 512 \
    --temperature 1.0 \
    --top_p 1 \
    >> api.log 2>&1

# 测试 max_tokens 是否有效
echo "=====================" >> api.log
echo "max_token = 10 " >> api.log
python ../test_api.py \
    --question_id 1 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 10 \
    --temperature 1.0 \
    --top_p 1 \
    >> api.log 2>&1

# 测试 max_tokens = 1 时是否正常
echo "=====================" >> api.log
echo "max_token = 1 " >> api.log
python ../test_api.py \
    --question_id 1 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 1 \
    --temperature 1.0 \
    --top_p 1 \
    >> api.log 2>&1

# 测试 非法 max_token 为 -1 是否报错
echo "=====================" >> api.log
echo "max_token = -1 " >> api.log
python ../test_api.py \
    --question_id 3 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens -1 \
    --temperature 1.0 \
    --top_p 1 \
    >> api.log 2>&1

# 测试 非法 max_token 为 浮点数 是否报错
echo "=====================" >> api.log
echo "max_token = 5.0 " >> api.log
python ../test_api.py \
    --question_id 0 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 5.0 \
    --temperature 1.0 \
    --top_p 1 \
    >> api.log 2>&1

# 测试不提供 tempartue 和 top_p 是否报错
echo "=====================" >> api.log
echo "no tempartue and no top_p" >> api.log
python ../test_api.py \
    --question_id 2 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 512 \
    >> api.log 2>&1

# 测试 非法 temperature 是否报错
echo "=====================" >> api.log
echo "temperature = -1 " >> api.log
python ../test_api.py \
    --question_id 3 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 512 \
    --temperature -1 \
    --top_p 1 \
    >> api.log 2>&1

# 测试 临界 temperature 是否报错
echo "=====================" >> api.log
echo "temperature = 2.0 " >> api.log
python ../test_api.py \
    --question_id 3 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 512 \
    --temperature 2.0 \
    --top_p 1 \
    >> api.log 2>&1

# 测试 临界 temperature 是否报错
echo "=====================" >> api.log
echo "temperature = 0 " >> api.log
python ../test_api.py \
    --question_id 3 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 512 \
    --temperature 0 \
    --top_p 1 \
    >> api.log 2>&1


# 测试 临界 top_p 是否报错
echo "=====================" >> api.log
echo "top_p = 0 " >> api.log
python ../test_api.py \
    --question_id 3 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 512 \
    --temperature 1.0 \
    --top_p 0 \
    >> api.log 2>&1


# 测试 非法 top_p 是否报错
echo "=====================" >> api.log
echo "top_p = -0.5 " >> api.log
python ../test_api.py \
    --question_id 3 \
    --port 36666 \
    --model DeepSeek-R1-GGUF-Q4_K_M \
    --stream true \
    --max_tokens 512 \
    --temperature 1.0 \
    --top_p -0.5 \
    >> api.log 2>&1


# 测试多并发 
echo "=====================" >> api_concu.log
echo "concurrent=4, prompt_lens=1024, max_tokens=128 " >> api_concu.log
python ../test_concurrent.py \
    --concurrent 4 \
    --prompt_lens 1024 \
    --port 36666 \
    --max_tokens 128 \
    >> api_concu.log 2>&1


# 测试多并发 
echo "=====================" >> api_concu.log
echo "concurrent=4, prompt_lens=8192, max_tokens=128 " >> api_concu.log
python ../test_concurrent.py \
    --concurrent 4 \
    --prompt_lens 8192 \
    --port 36666 \
    --max_tokens 128 \
    >> api_concu.log 2>&1


# 测试多并发 
echo "=====================" >> api_concu.log
echo "concurrent=128, prompt_lens=1024, max_tokens=128 " >> api_concu.log
python ../test_concurrent.py \
    --concurrent 128 \
    --prompt_lens 1024 \
    --port 36666 \
    --max_tokens 128 \
    >> api_concu.log 2>&1




cleanup
cd ../
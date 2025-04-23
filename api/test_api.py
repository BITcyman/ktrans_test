import asyncio
import json
import sys
import aiohttp
import argparse
import socket
import time

def is_port_open(host: str, port: int, timeout: float = 1.0) -> bool:
    """检查端口是否开放"""
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
        s.settimeout(timeout)
        try:
            s.connect((host, port))
            return True
        except (ConnectionRefusedError, socket.timeout):
            return False

def wait_for_port(host: str, port: int, check_interval: float = 1.0, max_wait: float = 30.0):
    """忙等直到端口开放，超时抛出 TimeoutError"""
    print(f"Waiting for {host}:{port} to open (timeout={max_wait}s)...")
    start_time = time.time()

    while True:
        if is_port_open(host, port):
            print(f"{host}:{port} is now open!")
            return
        if time.time() - start_time > max_wait:
            raise TimeoutError(f"Timeout: {host}:{port} did not open within {max_wait} seconds")
        time.sleep(check_interval)



prompt_list = [
    'Please elaborate on modern world history.',
    'Please introduce Harry Potter.',
    'I want to learn Python. Please give me some advice.',
    'Please tell me a joke '
]


async def fetch_event_stream(session, payload, request_id, stream):
    try:
        headers = {
            'accept': 'application/json',
            'Content-Type': 'application/json'
        }

        async with session.post(SERVER_URL, json=payload, headers=headers, timeout=50000) as response:
            print(f"Request {request_id}: Connected, status {response.status}")

            if response.status != 200:
                print(f"Request {request_id}: Error, status {response.status}")
                return

            output_text = ""

            if stream:
                async for line in response.content:
                    try:
                        decoded_line = line.decode("utf-8").strip()
                        if not decoded_line or not decoded_line.startswith("data: "):
                            continue

                        decoded_line = decoded_line[6:].strip()
                        if not decoded_line:
                            continue

                        response_data = json.loads(decoded_line)
                        choices = response_data.get("choices", [])
                        if not choices:
                            continue

                        delta = choices[0].get("delta", {})
                        token = delta.get("content", "")

                        if token:
                            output_text += token
                            sys.stdout.write(token)
                            sys.stdout.flush()
                        
                        if "usage" in response_data:
                            usage_info = response_data["usage"]

                            if usage_info:
                                print(f"[Request {request_id}] Usage:")
                                for key, value in usage_info.items():
                                    print(f"  {key}: {value}")

                        finish_reason = choices[0].get("finish_reason", None)
                        if finish_reason:
                            break

                    except json.JSONDecodeError as e:
                        print(f"\nRequest {request_id}: JSON Decode Error - {e}")
                    except IndexError:
                        print(f"\nRequest {request_id}: List Index Error - choices is empty")
                    except Exception as e:
                        print(f"\nRequest {request_id}: Error parsing stream - {e}")
            else:
                # 非 stream 模式下，一次性接收完整 json
                response_data = await response.json()
                choices = response_data.get("choices", [])
                if choices:
                    content = choices[0].get("message", {}).get("content", "")
                    print(f"Request {request_id} Output:\n{content}")
                    output_text += content
                
                if "usage" in response_data:
                    usage_info = response_data["usage"]

                    if usage_info:
                        print(f"[Request {request_id}] Usage:")
                        for key, value in usage_info.items():
                            print(f"  {key}: {value}")

    except Exception as e:
        print(f"\nRequest {request_id}: Exception - {e}")

async def main(prompt_id, model, stream, max_tokens, temperature, top_p):
    async with aiohttp.ClientSession() as session:
        payload = {
            "messages": [
                {"role": "system", "content": ""},
                {"role": "user", "content": prompt_list[prompt_id]}
            ],
            "model": model,
        }
        if stream:
            payload["stream"] = stream
        if max_tokens:
            payload["max_tokens"] = max_tokens
        if temperature:
            payload["temperature"] = temperature
        if top_p:
            payload["top_p"] = top_p
        
        tasks = [fetch_event_stream(session, payload, prompt_id, stream)]
        await asyncio.gather(*tasks)


def str2bool(v):
    if isinstance(v, bool):
        return v
    if v.lower() in ("yes", "true", "t", "y", "1"):
        return True
    elif v.lower() in ("no", "false", "f", "n", "0"):
        return False
    else:
        raise argparse.ArgumentTypeError("Boolean value expected.")

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Event Stream Request Tester")
    parser.add_argument("--question_id", type=int, default=0)
    parser.add_argument("--model", type=str, required=True)
    parser.add_argument("--stream", type=str2bool, choices=[True, False], default=None)  
    parser.add_argument("--max_tokens", type=int, default=None)
    parser.add_argument("--temperature", type=float, default=None)
    parser.add_argument("--top_p", type=float, default=None)
    parser.add_argument("--port", type=int, default=36666, help="API port")

    args = parser.parse_args()

    port = args.port
    SERVER_URL = f"http://localhost:{port}/v1/chat/completions"
    
    wait_for_port("127.0.0.1", port, 10, 30*60)

    asyncio.run(main(args.question_id, args.model, args.stream, args.max_tokens, args.temperature, args.top_p))
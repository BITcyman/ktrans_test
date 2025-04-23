import argparse
from time import sleep
from openai import OpenAI
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


def main():
    parser = argparse.ArgumentParser(description="接收命令行中的 port 参数")
    
    parser.add_argument("--port", type=int, required=True, help="指定端口号")
    parser.add_argument("--model", type=str, required=True, help="模型名称")
    
    args = parser.parse_args()
    
    port = args.port
    model = args.model
    
    client = OpenAI(base_url= f"http://127.0.0.1:{port}/v1/", api_key="placeholder")
    
    wait_for_port("127.0.0.1", port, 10, 30*60)

    try: 
        response = client.chat.completions.create(
            model=model,
            messages=[
                {'role': 'user', 'content': "你好！请问你是谁，你有什么作用"}
            ],
            stream=True,
            temperature=0.6
        )
        re = ""
        for event in response:
            print(event)
            if len(event.choices) > 0:
                token = event.choices[0].delta.content
                if token:
                    re = re + event.choices[0].delta.content
        print(re)
    except Exception as e:
        print(f"Ktrans start test error: {e}")

if __name__ == "__main__":
    main()
import argparse
from time import sleep
from openai import OpenAI


def main():
    parser = argparse.ArgumentParser(description="接收命令行中的 port 参数")
    
    parser.add_argument("--port", type=int, required=True, help="指定端口号")
    parser.add_argument("--model", type=str, required=True, help="模型名称")
    
    args = parser.parse_args()
    
    port = args.port
    model = args.model
    
    client = OpenAI(base_url= f"http://127.0.0.1:{port}/v1/", api_key="placeholder")
    
    sleep(30*60)

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
                re = re + event.choices[0].delta.content
        print(re)
    except Exception as e:
        print(f"Ktrans start test error: {e}")

if __name__ == "__main__":
    main()
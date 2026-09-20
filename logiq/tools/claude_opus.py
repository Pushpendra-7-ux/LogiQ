#!/usr/bin/env python3
"""
Claude Opus 4.6 integration client for LOGIQ.
Streams responses from free/claude-opus-4.6 on Apinex.
"""

import sys
import os
import json
import requests

API_KEY = os.environ.get("DEEPSEEK_API_KEY") or "sk-apx9dcea6d210fb28a0a3f634e6471a4c5359e8050f65773cb"
BASE_URL = os.environ.get("DEEPSEEK_BASE_URL") or "https://api.apinex.bond/v1"
MODEL = os.environ.get("DEEPSEEK_MODEL") or "free/claude-opus-4.6"

def call_claude_opus(prompt: str, system_prompt: str = "") -> str:
    messages = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.append({"role": "user", "content": prompt})

    headers = {
        "Authorization": f"Bearer {API_KEY}",
        "Content-Type": "application/json"
    }
    payload = {
        "model": MODEL,
        "messages": messages,
        "stream": True,
        "temperature": 0.2
    }

    try:
        response = requests.post(
            f"{BASE_URL}/chat/completions",
            headers=headers,
            json=payload,
            stream=True,
            timeout=120
        )
        response.raise_for_status()

        full_content = []
        for line in response.iter_lines(decode_unicode=True):
            if not line:
                continue
            if line.startswith("data: "):
                data_str = line[6:].strip()
                if data_str == "[DONE]":
                    break
                try:
                    data = json.loads(data_str)
                    choices = data.get("choices", [])
                    if choices:
                        delta = choices[0].get("delta", {})
                        chunk = delta.get("content", "")
                        if chunk:
                            full_content.append(chunk)
                except Exception:
                    pass
        return "".join(full_content)
    except Exception as e:
        return f"Claude Opus Error: {e}"

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: claude_opus.py <prompt> [system_prompt]")
        sys.exit(1)
    prompt = sys.argv[1]
    system = sys.argv[2] if len(sys.argv) > 2 else ""
    result = call_claude_opus(prompt, system)
    print(result)

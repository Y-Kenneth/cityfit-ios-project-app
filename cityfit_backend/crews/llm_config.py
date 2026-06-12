"""Shared DeepSeek LLM configuration for all crews."""

import json
import os
import re

from crewai import LLM

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
DEEPSEEK_BASE_URL = "https://api.deepseek.com"

# DeepSeek-V4-Flash: cheap, fast, strong — used by all 3 crews
deepseek_llm = LLM(
    model="openai/DeepSeek-V4-Flash",   # CrewAI uses openai/ prefix for OpenAI-compatible APIs
    api_key=DEEPSEEK_API_KEY,
    base_url=DEEPSEEK_BASE_URL,
    temperature=0.7,
)

# Vision model — DeepSeek-V4-Flash also accepts image input via the same API
DEEPSEEK_VISION_MODEL = "DeepSeek-V4-Flash"


def extract_json(text: str) -> dict:
    """Pulls the first JSON object out of an LLM answer (handles ```json fences)."""
    match = re.search(r"\{.*\}", str(text), re.DOTALL)
    if not match:
        raise ValueError(f"No JSON found in LLM output: {text[:200]}")
    return json.loads(match.group(0))

"""DeepSeek LLM setup used by all crews"""

import json
import os

from crewai import LLM

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
DEEPSEEK_BASE_URL = "https://api.deepseek.com"

# model id is case-sensitive, must match exactly what GET /models returns
deepseek_llm = LLM(
    model="deepseek/deepseek-v4-flash",
    api_key=DEEPSEEK_API_KEY,
    base_url=DEEPSEEK_BASE_URL,
    temperature=0.7,
)

# lower temperature for route/trip crews since their output must be strict JSON
deepseek_llm_structured = LLM(
    model="deepseek/deepseek-v4-flash",
    api_key=DEEPSEEK_API_KEY,
    base_url=DEEPSEEK_BASE_URL,
    temperature=0.2,
)

# same model, also supports image input for the vision crew
DEEPSEEK_VISION_MODEL = "deepseek-v4-flash"


def extract_json(text: str) -> dict:
    """extracts the first valid JSON object from the model's response.
    uses raw_decode instead of regex to avoid matching wrong braces."""
    text = str(text)
    decoder = json.JSONDecoder()
    start = text.find("{")
    while start != -1:
        try:
            obj, _ = decoder.raw_decode(text, start)
            return obj
        except json.JSONDecodeError:
            start = text.find("{", start + 1)
    raise ValueError(f"No valid JSON found in LLM output: {text[:200]}")

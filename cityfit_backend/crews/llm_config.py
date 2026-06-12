"""Shared DeepSeek LLM configuration for all crews."""

import json
import os
import re

from crewai import LLM

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
DEEPSEEK_BASE_URL = "https://api.deepseek.com"

# deepseek-v4-flash: cheap, fast, strong — used by all 3 crews.
# NOTE: DeepSeek's API is case-sensitive — the id must be lowercase exactly as
# returned by GET /models ("deepseek-v4-flash"). The openai/ prefix tells
# CrewAI/LiteLLM to treat base_url as an OpenAI-compatible endpoint.
deepseek_llm = LLM(
    model="openai/deepseek-v4-flash",
    api_key=DEEPSEEK_API_KEY,
    base_url=DEEPSEEK_BASE_URL,
    temperature=0.7,
)

# Vision model — deepseek-v4-flash also accepts image input via the same API
DEEPSEEK_VISION_MODEL = "deepseek-v4-flash"


def extract_json(text: str) -> dict:
    """Pulls the first JSON object out of an LLM answer (handles ```json fences)."""
    match = re.search(r"\{.*\}", str(text), re.DOTALL)
    if not match:
        raise ValueError(f"No JSON found in LLM output: {text[:200]}")
    return json.loads(match.group(0))

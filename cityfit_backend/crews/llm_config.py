"""Shared DeepSeek LLM configuration for all crews."""

import json
import os

from crewai import LLM

DEEPSEEK_API_KEY = os.getenv("DEEPSEEK_API_KEY")
DEEPSEEK_BASE_URL = "https://api.deepseek.com"

# deepseek-v4-flash: cheap, fast, strong — used by all 3 crews.
# NOTE: model id is case-sensitive — must be lowercase exactly as returned by
# GET /models. The "deepseek/" prefix is CrewAI's native provider — no litellm needed.
deepseek_llm = LLM(
    model="deepseek/deepseek-v4-flash",
    api_key=DEEPSEEK_API_KEY,
    base_url=DEEPSEEK_BASE_URL,
    temperature=0.7,
)

# Lower temperature for agents whose entire output must be machine-parsed JSON
# (Route Crew) — 0.7 is fine for conversational chat but invites more
# formatting drift (stray prose, markdown fences) than a strict schema can
# tolerate.
deepseek_llm_structured = LLM(
    model="deepseek/deepseek-v4-flash",
    api_key=DEEPSEEK_API_KEY,
    base_url=DEEPSEEK_BASE_URL,
    temperature=0.2,
)

# Vision model — deepseek-v4-flash also accepts image input via the same API
DEEPSEEK_VISION_MODEL = "deepseek-v4-flash"


def extract_json(text: str) -> dict:
    """Pulls the first complete JSON object out of an LLM answer. Scans for
    balanced braces via json.JSONDecoder.raw_decode at each '{' instead of a
    greedy regex — a greedy "\\{.*\\}" matches from the FIRST '{' to the LAST
    '}' in the whole string, which silently produces invalid JSON the moment
    the model adds any stray brace in surrounding prose or a markdown fence."""
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

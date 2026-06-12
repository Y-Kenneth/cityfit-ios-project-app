"""Vision Crew — 1 agent: the Object Detection Specialist.

Two steps:
1. DeepSeek Vision looks at the photo and describes it (OpenAI-compatible API).
2. The CrewAI Object Detection Specialist turns that description into a
   strict detected/rejected verdict (Tier 2 of the app's detection system).
"""

import os

from crewai import Agent, Crew, Process, Task
from openai import OpenAI

from .llm_config import DEEPSEEK_BASE_URL, DEEPSEEK_VISION_MODEL, deepseek_llm, extract_json

deepseek_client = OpenAI(
    api_key=os.getenv("DEEPSEEK_API_KEY"),
    base_url=DEEPSEEK_BASE_URL,
)

vision_agent = Agent(
    role="Object Detection Specialist",
    goal="Verify if photo contains the required mission object",
    backstory="""You analyze photos to verify CityFit mission completion.
    The object must be clearly visible. Be strict but fair.""",
    llm=deepseek_llm,
    verbose=False,
)


def _describe_photo(image_base64: str, target_object: str) -> str:
    """Step 1 — DeepSeek Vision describes what is in the photo."""
    completion = deepseek_client.chat.completions.create(
        model=DEEPSEEK_VISION_MODEL,
        messages=[{
            "role": "user",
            "content": [
                {"type": "text",
                 "text": (f"Describe this photo in 2-3 sentences, focusing on "
                          f"whether a {target_object} is clearly visible, where "
                          f"it is, and how certain you are.")},
                {"type": "image_url",
                 "image_url": {"url": f"data:image/jpeg;base64,{image_base64}"}},
            ],
        }],
        max_tokens=200,
    )
    return completion.choices[0].message.content


def run_vision_crew(image_base64: str, target_object: str, user_id: str) -> dict:
    description = _describe_photo(image_base64, target_object)

    task = Task(
        description=f"""A CityFit user ({user_id}) submitted a photo for the mission
"find a {target_object}". An image analysis of their photo says:

\"\"\"{description}\"\"\"

Decide whether the {target_object} is clearly visible. Be strict but fair.
Output ONLY one JSON object exactly in this shape:
{{"detected": true/false,
  "description": "<short phrase, e.g. 'red bicycle on left'>",
  "confidence": "HIGH" | "MEDIUM" | "LOW"}}""",
        expected_output="A single JSON object with detected, description, confidence.",
        agent=vision_agent,
    )
    crew = Crew(agents=[vision_agent], tasks=[task], process=Process.sequential)
    result = extract_json(crew.kickoff())

    result.setdefault("detected", False)
    result.setdefault("description", "unclear photo")
    result.setdefault("confidence", "LOW")
    return result

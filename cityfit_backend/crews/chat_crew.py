"""Chat Crew — 1 agent: the CityFit Personal Coach."""

from crewai import Agent, Crew, Process, Task

from .llm_config import deepseek_llm

chat_agent = Agent(
    role="CityFit Personal Coach",
    goal="Help the user with fitness advice, app guidance, and motivation",
    backstory="""You are CityFit's AI coach. You know the user's level,
    EXP, steps, missions, and streak. Respond in 2-3 sentences max,
    friendly and encouraging.""",
    llm=deepseek_llm,
    verbose=False,
)


def run_chat_crew(user_message: str, level: int, exp: int,
                  steps_today: int, active_mission: str, streak: int,
                  missions_completed: int = 0) -> str:
    task = Task(
        description=f"""The user's current stats:
- Level: {level} ({exp} EXP)
- Steps today: {steps_today}
- Active mission: {active_mission}
- Streak: {streak} days
- Missions completed: {missions_completed}

The user says: "{user_message}"

Reply as their personal coach. Reference their stats when relevant.
Keep it to 2-3 short, friendly, encouraging sentences. No markdown.""",
        expected_output="A 2-3 sentence conversational coaching reply.",
        agent=chat_agent,
    )
    crew = Crew(agents=[chat_agent], tasks=[task], process=Process.sequential)
    return str(crew.kickoff()).strip()

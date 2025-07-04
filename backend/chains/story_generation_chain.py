from typing import Dict, Any, Optional, List
import json
import httpx

from models.requests import StoryGenerationRequest
from models.responses import StoryGenerationResponse, InteractionPoint


class StoryGenerationChain:
    def __init__(self):
        self.api_url = "http://localhost:1234/v1/chat/completions"
        self.headers = {"Content-Type": "application/json"}

    def _get_story_prompt_template(self) -> str:
        return """
You are an expert educational content creator specializing in neurodivergent learners. Create a personalized learning story based on the following student profile and requirements.

STUDENT PROFILE:
- Name: {student_name}
- Subject area: {subject}
- Characters: {characters}
- Memory context: {memory_context}
{topic_to_be_reached}

OUTPUT FORMAT:
Return a JSON object with the following structure:
{
    "title": "Engaging story title",
    "content": "Main story content",
    "characters": ["List of main characters"],
    "learning_points": ["Key educational concepts covered"],
    "interaction_points": [
        {
            "type": "question|choice|activity|gesture",
            "prompt": "Interaction prompt for student",
            "expected_responses": ["possible responses"]
        }
    ],
    "vocabulary_words": ["New vocabulary introduced"],
    "comprehension_questions": ["Assessment questions"],
    "adaptation_notes": "How to modify based on student response",
    "estimated_duration_minutes": 15
}

Create an engaging, educational story that makes learning joyful and accessible for this specific student.
"""

    def _process_student_data(self, request: StoryGenerationRequest) -> Dict[str, Any]:
        data = {
            "student_name": request.student_name,
            "subject": request.subject,
            "characters": ", ".join(request.characters) if request.characters else "None specified",
            "memory_context": request.memory_context or "No context provided"
        }
        if request.topic_to_be_reached:
            data["topic_to_be_reached"] = f"- Topic to be reached: {request.topic_to_be_reached}"
        else:
            data["topic_to_be_reached"] = ""

        return data

    def _parse_story_response(self, llm_output: str) -> StoryGenerationResponse:
        print(f"Raw LLM output: {llm_output}")

        try:
            story_data = json.loads(llm_output)
        except json.JSONDecodeError as e:
            print(f"JSON parsing error: {str(e)}")
            return StoryGenerationResponse(
                title="Generated Learning Story",
                content=llm_output,
                characters=[],
                learning_points=[],
                interaction_points=[],
                vocabulary_words=[],
                comprehension_questions=[],
                adaptation_notes="Manual adaptation may be needed",
                estimated_duration_minutes=15
            )

        interaction_points = [
            InteractionPoint(
                type=item.get("type", "question"),
                prompt=item.get("prompt", ""),
                expected_responses=item.get("expected_responses", [])
            )
            for item in story_data.get("interaction_points", [])
        ]

        return StoryGenerationResponse(
            title=story_data.get("title", "Learning Story"),
            content=story_data.get("content", ""),
            characters=story_data.get("characters", []),
            learning_points=story_data.get("learning_points", []),
            interaction_points=interaction_points,
            vocabulary_words=story_data.get("vocabulary_words", []),
            comprehension_questions=story_data.get("comprehension_questions", []),
            adaptation_notes=story_data.get("adaptation_notes", ""),
            estimated_duration_minutes=story_data.get("estimated_duration_minutes", 15)
        )

    async def run(self, request: StoryGenerationRequest) -> StoryGenerationResponse:
        processed_input = self._process_student_data(request)
        payload = {
            "model": "gemma-3-27b-it",
            "messages": [
                {"role": "system", "content": self._get_story_prompt_template().format(**processed_input)},
                {"role": "user", "content": json.dumps(processed_input)}
            ],
            "temperature": 0.7,
            "max_tokens": 2024,
            "stream": False
        }

        try:
            async with httpx.AsyncClient() as client:
                response = await client.post(self.api_url, headers=self.headers, json=payload)
                response.raise_for_status()
                data = response.json()

                print(f"Response headers: {response.headers}")
                print(f"Response body: {data}")

                raw_content = data.get("choices", [{}])[0].get("message", {}).get("content", "")

                if isinstance(raw_content, str):
                    return self._parse_story_response(raw_content)
                else:
                    return StoryGenerationResponse(
                        title="Generated Learning Story",
                        content=str(raw_content),
                        characters=[],
                        learning_points=[],
                        interaction_points=[],
                        vocabulary_words=[],
                        comprehension_questions=[],
                        adaptation_notes="Manual adaptation may be needed",
                        estimated_duration_minutes=15
                    )

        except httpx.HTTPError as e:
            print(f"HTTP error: {str(e)}")
        except Exception as e:
            import traceback
            print(f"Unexpected error: {str(e)}")
            print(traceback.format_exc())

        return StoryGenerationResponse(
            title="Generated Learning Story",
            content="An error occurred during story generation.",
            characters=[],
            learning_points=[],
            interaction_points=[],
            vocabulary_words=[],
            comprehension_questions=[],
            adaptation_notes="Manual adaptation may be needed",
            estimated_duration_minutes=15
        )
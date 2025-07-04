import os
import json
import logging
import httpx
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from dotenv import load_dotenv
from typing import Dict

from services.voice_clone_service import VoiceCloneService
from models.requests import (
    StoryGenerationRequest,
    ProgressSummaryRequest,
    VoiceCloneRequest,
)
from models.responses import (
    StoryGenerationResponse,
    ProgressSummaryResponse,
    VoiceCloneResponse,
    InteractionPoint
)
from models.enums import DifficultyLevel

# Load environment variables
load_dotenv()

app = FastAPI(
    title="NeuroLearn AI API",
    description="AI-powered educational content generation for neurodivergent learners with Text-to-Speech capabilities",
    version="1.0.0",
    docs_url="/docs",
    redoc_url="/redoc"
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

logging.basicConfig(level=logging.INFO)
voice_clone_service = VoiceCloneService()


@app.get("/")
async def root():
    return {"message": "NeuroLearn AI LangChain Backend is running"}


@app.post("/storygeneration", response_model=StoryGenerationResponse)
async def generate_story_from_lmstudio(request: StoryGenerationRequest) -> StoryGenerationResponse:
    try:
        url = "http://localhost:1234/v1/chat/completions"
        headers = {"Content-Type": "application/json"}

        prompt = f"""
You are a teacher helping a young neurodivergent student understand a basic math or science concept through a very short story.

### Instructions:
- Use the student profile below to create a **simple story** that includes both a fun situation **and** teaches the core concept (e.g., addition, subtraction, fractions).
- Be very clear and supportive. Say the steps out loud in the story.
- Show how to solve the problem inside the story (e.g., "3 + 1 = 4").
- Avoid using complex words, JSON formatting, or markdown.
- End the story with a question to involve the student, based on what was just taught.

### Student Profile:
- Name: {request.student_name}
- Age: 3-6
- Subject and Concept: {request.subject}
- Memory Context: {request.memory_context or 'None'}
- Characters: {', '.join(request.characters) if request.characters else 'None'}

Keep it short and friendly (about 2–4 lines). Example:
"Ali the astronaut had 2 stars. Then he found 2 more. He counted: 2 + 2 = 4 stars. How many stars does Ali have now?"
"""


        payload = {
            "model": "gemma-3-27b-it",
            "messages": [
                {"role": "system", "content": prompt.strip()},
                {"role": "user", "content": "Generate the story now as plain text only."}
            ],
            "temperature": 0.7,
            "max_tokens": 256,
            "stream": False
        }

        logging.info(f"📤 Sending to LM Studio:\n{json.dumps(payload, indent=2)}")

        async with httpx.AsyncClient(timeout=httpx.Timeout(60.0)) as client:
            response = await client.post(url, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()

        logging.info(f"📥 LM Studio response:\n{json.dumps(data, indent=2)}")

        story_text = data.get("choices", [{}])[0].get("message", {}).get("content", "").strip()

        if not story_text:
            raise ValueError("Empty response from LM Studio.")

        return StoryGenerationResponse(content=story_text)

    except Exception as e:
        logging.error("🔥 Story generation error:\n")
        raise HTTPException(status_code=500, detail=f"Story generation failed: {str(e)}")

@app.post("/clone", response_model=VoiceCloneResponse)
async def clone_voice(request: VoiceCloneRequest) -> VoiceCloneResponse:
    try:
        # Ensure optional fields in VoiceCloneRequest have default values
        reference_audio = request.reference_audio or ""
        speed = request.speed or 1.0
        language = request.language or "en"

        output_path, audio_base64, duration = voice_clone_service.clone_voice(
            text=request.text,
            reference_audio_base64=reference_audio,
            speed=speed,
            language=language,
            output_filename=request.output_filename
        )
        return VoiceCloneResponse(
            success=True,
            audio_base64=audio_base64,
            output_path=output_path,
            duration_seconds=duration,
            message="Voice cloning completed successfully"
        )
    except Exception as e:
        return VoiceCloneResponse(
            success=False,
            message=f"Voice cloning failed: {str(e)}"
        )


@app.post("/generate-progress-summary", response_model=ProgressSummaryResponse)
async def generate_progress_summary(request: ProgressSummaryRequest) -> ProgressSummaryResponse:
    try:
        url = "http://localhost:1234/v1/chat/completions"
        headers = {"Content-Type": "application/json"}
        payload = {
            "model": "gemma-3-27b-it",
            "messages": [
                {
                    "role": "system",
                    "content": "You are an expert educational progress analyst specializing in neurodivergent learners. Analyze the student's progress data and create a comprehensive progress summary for parents and educators."
                },
                {
                    "role": "user",
                    "content": json.dumps({
                        "student_name": request.student_name,
                        "time_period": request.time_period,
                        "progress_data": request.progress_data or [],
                        "learning_insights": request.learning_insights or [],
                        "visual_progress_data": request.visual_progress_data
                    })
                }
            ],
            "temperature": 0.2,
            "max_tokens": 1024,
            "stream": False
        }

        timeout = httpx.Timeout(300.0)
        async with httpx.AsyncClient(timeout=timeout) as client:
            response = await client.post(url, headers=headers, json=payload)
            response.raise_for_status()
            data = response.json()

        progress_summary_content = data.get("choices", [{}])[0].get("message", {}).get("content", "")
        return ProgressSummaryResponse.parse_raw(progress_summary_content)

    except Exception as e:
        logging.error(f"🔥 Progress summary generation error:\n{e}")
        raise HTTPException(status_code=500, detail=f"Progress summary generation failed: {str(e)}")


@app.get("/health")
async def health_check() -> Dict[str, str]:
    return {"status": "healthy"}


if __name__ == "__main__":
    port = int(os.getenv("PORT", 8000))
    uvicorn.run(app, host="0.0.0.0", port=port)
import os
import json
import logging
import httpx
import uvicorn
import shutil
import base64
import re
from fastapi import FastAPI, HTTPException, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
from typing import Dict, Optional

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

# Define paths for audio storage
REFERENCE_AUDIO_PATH = os.path.join(os.path.dirname(__file__), "uploads", "reference_audio.wav")

# Ensure uploads directory exists
os.makedirs(os.path.dirname(REFERENCE_AUDIO_PATH), exist_ok=True)

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
    expose_headers=["Content-Type"],
)

logging.basicConfig(level=logging.INFO)
voice_clone_service = VoiceCloneService()


def clean_story_text(text: str) -> str:
    """Clean and normalize story text from encoding issues"""
    if not text:
        return ""
    
    # Fix common UTF-8 encoding issues
    cleaned_text = text
    
    # Handle smart quotes and apostrophes
    cleaned_text = cleaned_text.replace('"', '"')  # Left double quote
    cleaned_text = cleaned_text.replace('"', '"')  # Right double quote
    cleaned_text = cleaned_text.replace(''', "'")  # Left single quote
    cleaned_text = cleaned_text.replace(''', "'")  # Right single quote
    cleaned_text = cleaned_text.replace('´', "'")  # Acute accent
    cleaned_text = cleaned_text.replace('`', "'")  # Grave accent
    
    # Handle em dashes and en dashes
    cleaned_text = cleaned_text.replace('—', '-')  # Em dash
    cleaned_text = cleaned_text.replace('–', '-')  # En dash
    
    # Handle ellipsis
    cleaned_text = cleaned_text.replace('…', '...')
    
    # Handle common encoding artifacts
    cleaned_text = cleaned_text.replace('â€™', "'")  # Common apostrophe encoding
    cleaned_text = cleaned_text.replace('â€œ', '"')  # Common left quote encoding
    cleaned_text = cleaned_text.replace('â€', '"')   # Common right quote encoding
    cleaned_text = cleaned_text.replace('â€"', '-')  # Common dash encoding
    cleaned_text = cleaned_text.replace('Ã¢â‚¬â„¢', "'")  # Another apostrophe variant
    cleaned_text = cleaned_text.replace('â', "'")    # Generic â replacement
    
    # Remove any remaining non-printable characters except newlines and tabs
    cleaned_text = re.sub(r'[^\x20-\x7E\n\t]', '', cleaned_text)
    
    # Normalize whitespace
    cleaned_text = re.sub(r'\s+', ' ', cleaned_text)
    cleaned_text = cleaned_text.strip()
    
    return cleaned_text


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

        # Clean the story text to fix encoding issues
        cleaned_story = clean_story_text(story_text)
        
        logging.info(f"📝 Original story: {story_text}")
        logging.info(f"✨ Cleaned story: {cleaned_story}")

        return StoryGenerationResponse(content=cleaned_story)

    except Exception as e:
        logging.error("🔥 Story generation error:\n")
        raise HTTPException(status_code=500, detail=f"Story generation failed: {str(e)}")

@app.post("/save-reference-audio")
async def save_reference_audio(reference_audio: UploadFile = File(...)):
    """Save uploaded reference audio file to backend storage"""
    try:
        with open(REFERENCE_AUDIO_PATH, "wb") as buffer:
            shutil.copyfileobj(reference_audio.file, buffer)
        return {"success": True, "message": "Reference audio saved successfully", "path": REFERENCE_AUDIO_PATH}
    except Exception as e:
        return JSONResponse(status_code=500, content={"success": False, "message": f"Failed to save reference audio: {str(e)}"})

@app.post("/clone", response_model=VoiceCloneResponse)
async def clone_voice(
    text: str = Form(...),
    speed: float = Form(...),
    language: str = Form(...),
    output_filename: str = Form(...),
    reference_audio: Optional[UploadFile] = File(None)
) -> VoiceCloneResponse:
    """Clone voice using reference audio and generate speech"""
    try:
        if reference_audio is not None:
            audio_bytes = await reference_audio.read()
        else:
            # Load the saved reference audio from disk
            with open(REFERENCE_AUDIO_PATH, "rb") as f:
                audio_bytes = f.read()
        reference_audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")

        # Try to use the voice clone service
        try:
            output_path, audio_base64, duration = voice_clone_service.clone_voice(
                text=text,
                reference_audio_base64=reference_audio_base64,
                speed=speed,
                language=language,
                output_filename=output_filename
            )
        except Exception as service_error:
            logging.warning(f"Voice clone service failed: {service_error}")
            # Fallback: look for generated audio file in outputs directory
            outputs_dir = os.path.join(os.path.dirname(__file__), "outputs")
            
            # Try different possible file extensions and names
            possible_files = [
                os.path.join(outputs_dir, f"base_{output_filename}.wav"),  # Most likely pattern
                os.path.join(outputs_dir, f"base_{output_filename}.mp3"),
                os.path.join(outputs_dir, f"base_{output_filename}"),
                os.path.join(outputs_dir, output_filename),
                os.path.join(outputs_dir, f"{output_filename}.wav"),
                os.path.join(outputs_dir, f"{output_filename}.mp3"),
                os.path.join(outputs_dir, "output.wav"),
                os.path.join(outputs_dir, "output.mp3"),
                os.path.join(outputs_dir, "base_output.wav")
            ]
            
            output_path = None
            for file_path in possible_files:
                if os.path.exists(file_path):
                    output_path = file_path
                    break
            
            if output_path and os.path.exists(output_path):
                # Read the generated audio file and convert to base64
                with open(output_path, "rb") as audio_file:
                    audio_bytes = audio_file.read()
                    audio_base64 = base64.b64encode(audio_bytes).decode("utf-8")
                
                # Calculate approximate duration (rough estimate)
                duration = len(audio_bytes) / (44100 * 2 * 2)  # Assuming 44.1kHz, 16-bit, stereo
            else:
                raise Exception("No audio file found in outputs directory")

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
from pydantic import BaseModel
from typing import List, Optional, Dict, Any


# Request Model: Only required fields
class StoryGenerationRequest(BaseModel):
    student_name: str
    subject: str
    memory_context: Optional[str] = None
    characters: Optional[List[str]] = None
    topic_to_be_reached: Optional[str] = None


# Define supporting model for interaction points
class InteractionPoint(BaseModel):
    question: str
    options: List[str]
    correct_answer: str
    explanation: str


# Response Model: Removed `difficulty_level`
class StoryGenerationResponse(BaseModel):
    title: str
    content: str
    characters: List[str]
    learning_points: List[str]
    interaction_points: List[InteractionPoint]
    vocabulary_words: List[str]
    comprehension_questions: List[str]
    adaptation_notes: str
    estimated_duration_minutes: int


class ProgressSummaryRequest(BaseModel):
    student_name: Optional[str] = None
    time_period: Optional[str] = None
    progress_data: Optional[List[Dict[str, Any]]] = None
    learning_insights: Optional[List[Dict[str, Any]]] = None
    visual_progress_data: Optional[Dict[str, Any]] = None


class VoiceCloneRequest(BaseModel):
    text: str
    reference_audio: Optional[str] = None
    speed: Optional[float] = 1.0
    language: Optional[str] = "en"
    output_filename: Optional[str] = "output.wav"

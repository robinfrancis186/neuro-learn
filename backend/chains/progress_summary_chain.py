from typing import Dict, Any, List
import json
import statistics
import httpx

from models.requests import ProgressSummaryRequest
from models.responses import ProgressSummaryResponse, IEPGoalProgress, LearningInsight

class ProgressSummaryChain:
    def __init__(self):
        self.api_url = "http://localhost:1234/v1/chat/completions"
        self.headers = {"Content-Type": "application/json"}

    def _get_progress_prompt_template(self) -> str:
        return """
You are an expert educational progress analyst specializing in neurodivergent learners. Analyze the student's progress data and create a comprehensive progress summary for parents and educators.

STUDENT INFORMATION:
- Name: {student_name}
- Reporting period: {time_period}

PROGRESS DATA:
{progress_data}

LEARNING INSIGHTS:
{learning_insights}

VISUAL PROGRESS DATA:
{visual_progress_data}

ANALYSIS REQUIREMENTS:
1. Provide an overall progress overview
2. Analyze each IEP goal's progress with evidence
3. Generate actionable insights with recommendations
4. Highlight celebration points and areas needing focus
5. Suggest home activities and next meeting talking points

OUTPUT FORMAT:
Return a JSON object with the following structure:
{{
    "overview": "Overall progress summary",
    "iep_goal_progress": [
        {{
            "goal_id": "goal identifier",
            "goal_description": "description of the goal",
            "current_progress": 0.75,
            "progress_change": 0.15,
            "status": "on track|ahead|needs attention",
            "evidence": ["specific examples of progress"],
            "next_steps": ["recommended next actions"]
        }}
    ],
    "insights": [
        {{
            "category": "learning pattern|behavior|engagement",
            "insight": "specific observation",
            "supporting_data": "data that supports this insight",
            "recommendation": "actionable recommendation",
            "priority": "high|medium|low"
        }}
    ],
    "celebration_highlights": ["positive achievements to celebrate"],
    "areas_for_focus": ["areas that need additional attention"],
    "parent_collaboration_summary": "How parents can support learning",
    "recommended_home_activities": ["specific activities for home"],
    "next_meeting_talking_points": ["key points for next IEP meeting"],
    "overall_progress_score": 0.78
}}

Provide a comprehensive, data-driven analysis that supports both celebration and growth.
"""

    def _process_progress_data(self, request: ProgressSummaryRequest) -> Dict[str, Any]:
        """Process and format progress data for analysis"""
        
        # Format progress data
        progress_summary = []
        for item in request.progress_data:
            progress_summary.append(f"Goal: {item.goal_description} - Current: {item.current_score}, Target: {item.target_score}")
        
        processed = {
            "student_name": request.student_name,
            "time_period": request.time_period,
            "progress_data": "\n".join(progress_summary),
            "learning_insights": json.dumps(request.learning_insights, indent=2),
            "visual_progress_data": json.dumps(request.visual_progress_data or {}, indent=2)
        }
        
        return processed

    async def run(self, request: ProgressSummaryRequest) -> ProgressSummaryResponse:
        """Execute the progress summary chain"""
        payload = {
            "model": "gemma-3-27b-it",
            "messages": [
                {"role": "system", "content": self._get_progress_prompt_template()},
                {"role": "user", "content": json.dumps(self._process_progress_data(request))}
            ],
            "temperature": 0.2,
            "max_tokens": -1,
            "stream": False
        }

        async with httpx.AsyncClient() as client:
            response = await client.post(self.api_url, headers=self.headers, json=payload)
            response.raise_for_status()
            data = response.json()

        return self._parse_progress_response(data.get("choices", [{}])[0].get("message", {}).get("content", ""))
    
    def _parse_progress_response(self, llm_output: str) -> ProgressSummaryResponse:
        """Parse LLM output into structured response"""
        try:
            # Try to parse as JSON
            progress_data = json.loads(llm_output)
            
            # Convert IEP goal progress to proper format
            iep_goals = []
            for goal in progress_data.get("iep_goal_progress", []):
                iep_goals.append(IEPGoalProgress(
                    goal_id=goal.get("goal_id", ""),
                    goal_description=goal.get("goal_description", ""),
                    current_progress=goal.get("current_progress", 0.0),
                    progress_change=goal.get("progress_change", 0.0),
                    status=goal.get("status", "needs attention"),
                    evidence=goal.get("evidence", []),
                    next_steps=goal.get("next_steps", [])
                ))
            
            # Convert insights to proper format
            insights = []
            for insight in progress_data.get("insights", []):
                insights.append(LearningInsight(
                    category=insight.get("category", ""),
                    insight=insight.get("insight", ""),
                    supporting_data=insight.get("supporting_data", ""),
                    recommendation=insight.get("recommendation", ""),
                    priority=insight.get("priority", "medium")
                ))
            
            return ProgressSummaryResponse(
                student_name=progress_data.get("student_name", ""),
                time_period=progress_data.get("time_period"),
                overview=progress_data.get("overview"),
                iep_goal_progress=iep_goals if progress_data.get("iep_goal_progress") else [],
                insights=insights if progress_data.get("insights") else [],
                celebration_highlights=progress_data.get("celebration_highlights"),
                areas_for_focus=progress_data.get("areas_for_focus"),
                parent_collaboration_summary=progress_data.get("parent_collaboration_summary"),
                recommended_home_activities=progress_data.get("recommended_home_activities"),
                next_meeting_talking_points=progress_data.get("next_meeting_talking_points"),
                overall_progress_score=progress_data.get("overall_progress_score"),
                visual_data=progress_data.get("visual_data")
            )
            
        except json.JSONDecodeError:
            # Fallback for non-JSON responses
            return ProgressSummaryResponse(
                student_name="",
                time_period="",
                overview=llm_output,
                iep_goal_progress=[],
                insights=[],
                celebration_highlights=[],
                areas_for_focus=[],
                parent_collaboration_summary="Manual review needed",
                recommended_home_activities=[],
                next_meeting_talking_points=[],
                overall_progress_score=0.0,
                visual_data=None
            )
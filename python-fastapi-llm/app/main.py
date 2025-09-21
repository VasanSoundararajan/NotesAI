from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from dotenv import load_dotenv
from typing import Optional
import os
import uvicorn # Import uvicorn
import threading
import asyncio

import google.generativeai as genai
# Used to securely store your API key
from google.colab import userdata


# Load environment variables
load_dotenv()

# Configure Gemini API
try:
    # Access the API key from Google Colab secrets
    GOOGLE_API_KEY = "AIzaSyCO3ZAadsBiMgYeP0DOfDYgy9IoSUDH9WQ";
    if not GOOGLE_API_KEY:
        raise ValueError("GOOGLE_API_KEY not found in Colab secrets.")
    genai.configure(api_key=GOOGLE_API_KEY)
except Exception as e:
    print(f"Error configuring Gemini API: {e}")
    # Handle the error appropriately, e.g., exit or raise an exception
    exit()


MODEL = "gemini-2.0-flash" # Use an appropriate Gemini model

# FastAPI app
app = FastAPI(title="Notes + AI Summarizer API (Streaming)")

# Request schema
class SummarizeRequest(BaseModel):
    text: str
    max_tokens: Optional[int] = 1024


def get_client():
    # With the Gemini API, the client is not explicitly created like with OpenAI.
    # The genai.configure(api_key=...) handles the setup.
    # We will return the generative model directly.
    return genai.GenerativeModel(MODEL)


async def stream_summary(text: str, max_tokens: int = 1024) -> str:
    """
    Collects streamed summary from Gemini LLM and returns full text.
    """
    model = get_client()

    # Truncate text if longer than 1024 characters
    truncated_text = text[:1024] if len(text) > 1024 else text

    completion = model.generate_content(
        contents=[
            {"role": "user", "parts": [{"text": f"Summarize this:\n\n{truncated_text}"}]},
        ],
        generation_config={
            "temperature": 0.6,
            "top_p": 0.95,
            "max_output_tokens": max_tokens, # Use max_output_tokens for Gemini
        },
        stream=True,
    )

    summary = ""
    for chunk in completion:
        # Access text content from parts
        if chunk.candidates[0].content.parts is not None:
             for part in chunk.candidates[0].content.parts:
                 summary += part.text

    return summary


@app.get("/")
async def root():
    return {"status": "ok", "message": "Streaming Summarizer API is running"}


@app.post("/summarize")
async def summarize(req: SummarizeRequest):
    try:
        summary = await stream_summary(req.text, max_tokens=req.max_tokens or 1024)
        return {"summary": summary} # Return as JSON
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

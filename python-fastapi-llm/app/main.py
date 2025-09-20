from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from pydantic import BaseModel
from dotenv import load_dotenv
from typing import Optional
import os

from openai import OpenAI


NVIDIA_API_KEY = "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"
BASE_URL = "https://integrate.api.nvidia.com/v1"
MODEL = "nvidia/llama-3.3-nemotron-super-49b-v1.5"

# FastAPI app
app = FastAPI(title="Notes + AI Summarizer API (Streaming)")

# Request schema
class SummarizeRequest(BaseModel):
    text: str
    max_tokens: Optional[int] = 1024


def get_client():
    return OpenAI(base_url=BASE_URL, api_key=NVIDIA_API_KEY)


async def stream_summary(text: str, max_tokens: int = 1024) -> str:
    """
    Collects streamed summary from NVIDIA LLM and returns full text.
    """
    client = get_client()

    completion = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": "You are a helpful summarizer."},
            {"role": "user", "content": f"Summarize this:\n\n{text[:1024] if len(text) > 1024 else text}"},
        ],
        temperature=0.6,
        top_p=0.95,
        max_tokens=max_tokens,
        frequency_penalty=0,
        presence_penalty=0,
        stream=True,
    )

    summary = ""
    for chunk in completion:
        if chunk.choices[0].delta.content is not None:
            summary += chunk.choices[0].delta.content

    return summary


@app.get("/")
async def root():
    return {"status": "ok", "message": "Streaming Summarizer API is running"}


@app.post("/summarize")
async def summarize(req: SummarizeRequest):
    try:
        return StreamingResponse(
            stream_summary(req.text, max_tokens=req.max_tokens or 1024),
            media_type="text/plain"
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

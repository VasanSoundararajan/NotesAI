import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from openai import OpenAI
# OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
# if not OPENROUTER_API_KEY:
#     raise RuntimeError("Missing OPENROUTER_API_KEY. Please set it in environment variables.")
client = OpenAI(
    base_url="https://openrouter.ai/api/v1",
    api_key="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",
)
MODEL = "openai/gpt-5"
app = FastAPI(title="AI Summarizer API (OpenRouter)")
class SummarizeRequest(BaseModel):
    text: str
async def generate_summary(text_to_summarize: str) -> str:
    """
    Calls the OpenRouter API to summarize text.
    """
    try:
        completion = client.chat.completions.create(
            model=MODEL,
            messages=[
                {"role": "system", "content": "You are a helpful summarizer."},
                {"role": "user", "content": f"Summarize this text:\n\n{text_to_summarize}"},
            ],
            temperature=0.6,
            top_p=0.95,
            max_tokens=512,
        )

        return completion.choices[0].message.content.strip()
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Summarization failed: {e}")
@app.get("/")
async def root():
    return {"status": "ok", "message": "AI Summarizer API (OpenRouter) is running"}

@app.post("/summarize")
async def summarize(req: SummarizeRequest):
    if not req.text:
        raise HTTPException(status_code=400, detail="Text field cannot be empty.")
    return {"summary": await generate_summary(req.text)}

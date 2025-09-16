from fastapi import FastAPI, HTTPException
from .schemas import SummarizeRequest
from .provider import summarize_text

app = FastAPI(title="Notes + AI Summarizer API")

@app.get("/")
async def root():
    return {"status": "ok", "message": "Summarizer API is running"}

@app.post("/summarize")
async def summarize(req: SummarizeRequest):
    try:
        result = await summarize_text(req.text, max_tokens=req.max_tokens or 200)
        return {"summary": result}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

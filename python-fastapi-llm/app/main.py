import json
import os
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import Optional

# Best practice: use the google.generativeai library for Gemini
import google.generativeai as genai

# --- Configuration ---
# It's much safer to load your API key from an environment variable
# than to hardcode it in your script.
# On your server, you would set: export GOOGLE_API_KEY="your_real_api_key"
try:
    # Attempt to get the key from environment variables
    GOOGLE_API_KEY = os.getenv("GOOGLE_API_KEY")
    if not GOOGLE_API_KEY:
        # Fallback for environments like Colab secrets or if you must hardcode (not recommended)
        GOOGLE_API_KEY = l" # Replace with your actual key if needed
    
    genai.configure(api_key=GOOGLE_API_KEY)
except Exception as e:
    print(f"Error configuring Gemini API: {e}")
    # In a real application, you might want to log this error and exit.
    exit()

# Use a current, valid model name. 'gemini-1.5-flash-latest' is a great choice.
MODEL = "gemini-1.5-flash-latest"

# --- FastAPI App ---
app = FastAPI(title="AI Summarizer API")

# Define the structure of the request body using Pydantic
# The max_tokens field has been removed.
class SummarizeRequest(BaseModel):
    text: str

# --- API Logic ---
def get_gemini_model():
    """Initializes and returns the Gemini generative model."""
    return genai.GenerativeModel(MODEL)

async def generate_summary_stream(text_to_summarize: str) -> str:
    """
    Generates a summary from the Gemini LLM using streaming.
    The max_tokens value is now hardcoded here.
    """
    model = get_gemini_model()
    
    # The prompt for the model.
    prompt = f"Please provide a concise summary of the following text:\n\n---\n\n{text_to_summarize}"

    # Configure the generation
    generation_config = genai.types.GenerationConfig(
        temperature=0.7,
        top_p=0.95,
        max_output_tokens=1024, # Using a fixed default value
    )

    # Start the generation with streaming enabled
    stream = model.generate_content(
        prompt,
        generation_config=generation_config,
        stream=True
    )

    summary = ""
    try:
        for chunk in stream:
            # The .text attribute directly gives you the generated text in the chunk
            if chunk.text:
                summary += chunk.text
    except Exception as e:
        # Handle potential errors during streaming (e.g., safety blocks)
        print(f"An error occurred during content generation: {e}")
        # Depending on the error, you might get a partial summary.
        # We'll return what we have, but you could also raise an HTTPException.
        if not summary: # If no summary was generated at all
             raise HTTPException(status_code=500, detail=f"Failed to generate summary: {e}") from e

    return summary

# --- API Endpoints ---
@app.get("/")
async def root():
    """Root endpoint to check if the API is running."""
    return {"status": "ok", "message": "AI Summarizer API is running"}

@app.post("/summarize")
async def summarize(req: SummarizeRequest):
    """
    Endpoint to receive text and return a summary.
    """
    if not req.text:
        raise HTTPException(status_code=400, detail="Text field cannot be empty.")
        
    try:
        # The call to the generator function no longer includes max_tokens.
        summary = await generate_summary_stream(req.text)
        return {"summary": summary}
    except HTTPException as http_exc:
        # Re-raise HTTP exceptions from the generator
        raise http_exc
    except Exception as e:
        # Catch any other unexpected errors and return a 500 status code.
        print(f"An internal server error occurred: {e}")
        raise HTTPException(status_code=500, detail=f"An internal server error occurred: {e}")


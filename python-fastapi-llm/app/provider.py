from openai import OpenAI
from .config import NVIDIA_API_KEY, BASE_URL, MODEL

client = OpenAI(base_url=BASE_URL, api_key=NVIDIA_API_KEY)

async def summarize_text(text: str, max_tokens: int = 200) -> str:
    """
    Calls NVIDIA LLM to summarize text.
    """
    completion = client.chat.completions.create(
        model=MODEL,
        messages=[
            {"role": "system", "content": "You are a helpful summarizer."},
            {"role": "user", "content": f"Summarize this:\n\n{text}"}
        ],
        temperature=0.7,
        top_p=1,
        max_tokens=max_tokens,
    )

    # non-streaming, just return the first message
    return completion.choices[0].message.content

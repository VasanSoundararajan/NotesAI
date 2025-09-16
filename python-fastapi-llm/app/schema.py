from pydantic import BaseModel

class SummarizeRequest(BaseModel):
    text: str
    max_tokens: int | None = 200

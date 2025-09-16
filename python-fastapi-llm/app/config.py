from dotenv import load_dotenv
import os

load_dotenv()

NVIDIA_API_KEY = os.getenv("NVIDIA_API_KEY", "")
BASE_URL = "https://integrate.api.nvidia.com/v1"
MODEL = "openai/gpt-oss-120b"

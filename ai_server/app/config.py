"""
AI Server Configuration
"""
from pydantic_settings import BaseSettings
from functools import lru_cache
from typing import Optional


class Settings(BaseSettings):
    """Application settings"""

    # Server
    app_name: str = "Beauty AI Synthesis Server"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 8000

    # CORS
    cors_origins: list[str] = ["*"]

    # AI Models
    device: str = "cuda"  # cuda or cpu
    model_base: str = "runwayml/stable-diffusion-v1-5"
    controlnet_model: str = "lllyasviel/control_v11p_sd15_inpaint"
    ip_adapter_model: str = "h94/IP-Adapter"
    sam_checkpoint: str = "models/sam_vit_h.pth"
    lora_path: Optional[str] = "models/lora/eyebrow_v1"

    # Inference
    default_inference_steps: int = 30
    default_guidance_scale: float = 7.5
    default_denoise_strength: float = 0.75
    max_image_size: int = 1024

    # Supabase
    supabase_url: str = ""
    supabase_service_key: str = ""

    # Redis (for job queue)
    redis_url: str = "redis://localhost:6379/0"

    # Storage
    temp_dir: str = "/tmp/beauty_ai"
    max_upload_size: int = 10 * 1024 * 1024  # 10MB

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


@lru_cache()
def get_settings() -> Settings:
    return Settings()


settings = get_settings()

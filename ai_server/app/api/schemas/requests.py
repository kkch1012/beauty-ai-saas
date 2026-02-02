"""
API Request/Response Schemas
"""
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List
from enum import Enum


class BlendMode(str, Enum):
    MULTIPLY = "multiply"
    SOFT_LIGHT = "soft_light"
    OVERLAY = "overlay"


class SynthesisRequest(BaseModel):
    """Request for eyebrow synthesis"""
    preserve_hair_strength: float = Field(
        default=0.7,
        ge=0.0,
        le=1.0,
        description="How much to preserve existing eyebrow hair (0-1)"
    )
    blend_mode: BlendMode = Field(
        default=BlendMode.MULTIPLY,
        description="Blending mode for synthesis"
    )
    tone_correction: bool = Field(
        default=True,
        description="Apply tone harmonization"
    )
    denoise_strength: float = Field(
        default=0.75,
        ge=0.0,
        le=1.0,
        description="Inpainting strength"
    )
    guidance_scale: float = Field(
        default=7.5,
        ge=1.0,
        le=20.0,
        description="CFG scale"
    )
    num_inference_steps: int = Field(
        default=30,
        ge=10,
        le=100,
        description="Number of diffusion steps"
    )
    seed: Optional[int] = Field(
        default=None,
        description="Random seed for reproducibility"
    )
    return_debug: bool = Field(
        default=False,
        description="Return debug images"
    )


class SynthesisResponse(BaseModel):
    """Response for eyebrow synthesis"""
    success: bool
    result_url: Optional[str] = None
    debug_urls: Optional[Dict[str, str]] = None
    metadata: Optional[Dict[str, Any]] = None
    processing_time_ms: int = 0
    error: Optional[str] = None


class AnalysisResponse(BaseModel):
    """Response for face analysis"""
    success: bool
    skin_tone: Optional[Dict[str, Any]] = None
    golden_ratio: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


class ExtractionResponse(BaseModel):
    """Response for eyebrow extraction"""
    success: bool
    design_url: Optional[str] = None
    thumbnail_url: Optional[str] = None
    metadata: Optional[Dict[str, Any]] = None
    error: Optional[str] = None


class HealthResponse(BaseModel):
    """Health check response"""
    status: str
    gpu_available: bool
    models_loaded: bool
    version: str = "1.0.0"

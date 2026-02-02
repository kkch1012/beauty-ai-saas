"""
Synthesis API Routes
"""
from fastapi import APIRouter, UploadFile, File, Form, HTTPException, Depends
from fastapi.responses import StreamingResponse
from PIL import Image
import io
import uuid
import os
from typing import Optional

from app.config import settings
from app.api.schemas.requests import (
    SynthesisRequest,
    SynthesisResponse,
    AnalysisResponse,
    BlendMode
)
from app.core.pipeline import EyebrowSynthesisPipeline, SynthesisConfig

router = APIRouter(prefix="/api/v1", tags=["synthesis"])

# Global pipeline instance (initialized on startup)
_pipeline: Optional[EyebrowSynthesisPipeline] = None


def get_pipeline() -> EyebrowSynthesisPipeline:
    """Dependency to get pipeline instance"""
    global _pipeline
    if _pipeline is None:
        _pipeline = EyebrowSynthesisPipeline(
            device=settings.device,
            lora_path=settings.lora_path
        )
        _pipeline.load_models()
    return _pipeline


@router.post("/synthesize", response_model=SynthesisResponse)
async def synthesize_eyebrow(
    target_image: UploadFile = File(..., description="Customer's face image"),
    source_eyebrow: UploadFile = File(..., description="Eyebrow design image"),
    preserve_hair_strength: float = Form(default=0.7),
    blend_mode: str = Form(default="multiply"),
    tone_correction: bool = Form(default=True),
    denoise_strength: float = Form(default=0.75),
    guidance_scale: float = Form(default=7.5),
    num_inference_steps: int = Form(default=30),
    seed: Optional[int] = Form(default=None),
    return_debug: bool = Form(default=False),
    pipeline: EyebrowSynthesisPipeline = Depends(get_pipeline)
):
    """
    Synthesize eyebrow on customer's face

    - **target_image**: Customer's face photo
    - **source_eyebrow**: Eyebrow design to apply
    - **preserve_hair_strength**: How much to keep existing eyebrow hair (0-1)
    - **blend_mode**: Blending mode (multiply, soft_light, overlay)
    """
    try:
        # Load images
        target = Image.open(io.BytesIO(await target_image.read())).convert("RGB")
        source = Image.open(io.BytesIO(await source_eyebrow.read())).convert("RGB")

        # Validate image sizes
        if target.size[0] > settings.max_image_size or target.size[1] > settings.max_image_size:
            # Resize if too large
            target.thumbnail((settings.max_image_size, settings.max_image_size))

        # Create config
        config = SynthesisConfig(
            preserve_hair_strength=preserve_hair_strength,
            blend_mode=blend_mode,
            tone_correction=tone_correction,
            denoise_strength=denoise_strength,
            guidance_scale=guidance_scale,
            num_inference_steps=num_inference_steps,
            seed=seed
        )

        # Run synthesis
        result = pipeline.synthesize(
            target_image=target,
            source_eyebrow=source,
            config=config,
            return_debug=return_debug
        )

        # Save result to temp file (in production, upload to storage)
        result_id = str(uuid.uuid4())
        os.makedirs(settings.temp_dir, exist_ok=True)

        result_path = os.path.join(settings.temp_dir, f"{result_id}.png")
        result.final_image.save(result_path)

        debug_urls = {}
        if return_debug:
            for name, img in result.debug_images.items():
                debug_path = os.path.join(settings.temp_dir, f"{result_id}_{name}.png")
                img.save(debug_path)
                debug_urls[name] = f"/api/v1/images/{result_id}_{name}.png"

        return SynthesisResponse(
            success=True,
            result_url=f"/api/v1/images/{result_id}.png",
            debug_urls=debug_urls if debug_urls else None,
            metadata=result.metadata,
            processing_time_ms=result.processing_time_ms
        )

    except ValueError as e:
        return SynthesisResponse(
            success=False,
            error=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Synthesis failed: {str(e)}")


@router.post("/synthesize/stream")
async def synthesize_eyebrow_stream(
    target_image: UploadFile = File(...),
    source_eyebrow: UploadFile = File(...),
    preserve_hair_strength: float = Form(default=0.7),
    blend_mode: str = Form(default="multiply"),
    pipeline: EyebrowSynthesisPipeline = Depends(get_pipeline)
):
    """
    Synthesize and return image directly as stream
    """
    try:
        target = Image.open(io.BytesIO(await target_image.read())).convert("RGB")
        source = Image.open(io.BytesIO(await source_eyebrow.read())).convert("RGB")

        config = SynthesisConfig(
            preserve_hair_strength=preserve_hair_strength,
            blend_mode=blend_mode
        )

        result = pipeline.synthesize(
            target_image=target,
            source_eyebrow=source,
            config=config
        )

        # Return image as stream
        img_byte_arr = io.BytesIO()
        result.final_image.save(img_byte_arr, format='PNG')
        img_byte_arr.seek(0)

        return StreamingResponse(
            img_byte_arr,
            media_type="image/png",
            headers={
                "X-Processing-Time-Ms": str(result.processing_time_ms)
            }
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/analyze", response_model=AnalysisResponse)
async def analyze_face(
    image: UploadFile = File(..., description="Face image to analyze"),
    pipeline: EyebrowSynthesisPipeline = Depends(get_pipeline)
):
    """
    Analyze face for consultation

    Returns skin tone, golden ratio analysis, and recommendations
    """
    try:
        img = Image.open(io.BytesIO(await image.read())).convert("RGB")

        analysis = pipeline.analyze_face(img)

        return AnalysisResponse(
            success=True,
            skin_tone=analysis["skin_tone"],
            golden_ratio=analysis["golden_ratio"]
        )

    except ValueError as e:
        return AnalysisResponse(
            success=False,
            error=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.get("/images/{filename}")
async def get_image(filename: str):
    """Serve generated images"""
    filepath = os.path.join(settings.temp_dir, filename)

    if not os.path.exists(filepath):
        raise HTTPException(status_code=404, detail="Image not found")

    return StreamingResponse(
        open(filepath, "rb"),
        media_type="image/png"
    )

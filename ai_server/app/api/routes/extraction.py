"""
Eyebrow Extraction API Routes
"""
from fastapi import APIRouter, UploadFile, File, HTTPException, Depends
from fastapi.responses import StreamingResponse
from PIL import Image
import io
import uuid
import os
from typing import Optional

from app.config import settings
from app.api.schemas.requests import ExtractionResponse
from app.core.pipeline import EyebrowSynthesisPipeline

router = APIRouter(prefix="/api/v1", tags=["extraction"])

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


@router.post("/extract-design", response_model=ExtractionResponse)
async def extract_eyebrow_design(
    image: UploadFile = File(..., description="Image containing eyebrows to extract"),
    pipeline: EyebrowSynthesisPipeline = Depends(get_pipeline)
):
    """
    Extract eyebrow design from an image

    The extracted design can be saved to the design library
    for later use in synthesis.
    """
    try:
        img = Image.open(io.BytesIO(await image.read())).convert("RGB")

        # Extract design
        extracted, metadata = pipeline.extract_design(img)

        # Save to temp (in production, upload to storage)
        design_id = str(uuid.uuid4())
        os.makedirs(settings.temp_dir, exist_ok=True)

        # Save full size
        design_path = os.path.join(settings.temp_dir, f"design_{design_id}.png")
        extracted.save(design_path)

        # Create thumbnail
        thumbnail = extracted.copy()
        thumbnail.thumbnail((256, 256))
        thumb_path = os.path.join(settings.temp_dir, f"design_{design_id}_thumb.png")
        thumbnail.save(thumb_path)

        return ExtractionResponse(
            success=True,
            design_url=f"/api/v1/images/design_{design_id}.png",
            thumbnail_url=f"/api/v1/images/design_{design_id}_thumb.png",
            metadata=metadata
        )

    except ValueError as e:
        return ExtractionResponse(
            success=False,
            error=str(e)
        )
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))


@router.post("/extract-design/stream")
async def extract_eyebrow_design_stream(
    image: UploadFile = File(...),
    pipeline: EyebrowSynthesisPipeline = Depends(get_pipeline)
):
    """
    Extract eyebrow design and return as PNG stream
    """
    try:
        img = Image.open(io.BytesIO(await image.read())).convert("RGB")

        extracted, _ = pipeline.extract_design(img)

        # Return as stream
        img_byte_arr = io.BytesIO()
        extracted.save(img_byte_arr, format='PNG')
        img_byte_arr.seek(0)

        return StreamingResponse(
            img_byte_arr,
            media_type="image/png"
        )

    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

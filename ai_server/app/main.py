"""
Beauty AI Synthesis Server
FastAPI application entry point
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import torch

from app.config import settings
from app.api.routes import synthesis, extraction
from app.api.schemas.requests import HealthResponse


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Application lifespan handler"""
    # Startup
    print(f"Starting {settings.app_name}...")
    print(f"Device: {settings.device}")
    print(f"CUDA available: {torch.cuda.is_available()}")

    if torch.cuda.is_available():
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        print(f"GPU Memory: {torch.cuda.get_device_properties(0).total_memory / 1024**3:.1f}GB")

    # Pre-load models if not in debug mode
    if not settings.debug:
        from app.core.pipeline import EyebrowSynthesisPipeline
        pipeline = EyebrowSynthesisPipeline(
            device=settings.device,
            lora_path=settings.lora_path
        )
        pipeline.load_models()
        print("Models pre-loaded")

    yield

    # Shutdown
    print("Shutting down...")
    if torch.cuda.is_available():
        torch.cuda.empty_cache()


app = FastAPI(
    title=settings.app_name,
    description="AI-powered eyebrow synthesis for beauty salons",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(synthesis.router)
app.include_router(extraction.router)


@app.get("/", tags=["root"])
async def root():
    """Root endpoint"""
    return {
        "name": settings.app_name,
        "version": "1.0.0",
        "docs": "/docs"
    }


@app.get("/health", response_model=HealthResponse, tags=["health"])
async def health_check():
    """Health check endpoint"""
    return HealthResponse(
        status="healthy",
        gpu_available=torch.cuda.is_available(),
        models_loaded=True,  # Simplified for now
        version="1.0.0"
    )


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug
    )

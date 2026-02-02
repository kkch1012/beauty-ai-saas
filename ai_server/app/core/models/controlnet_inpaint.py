"""
ControlNet + IP-Adapter Inpainting for Eyebrow Synthesis
"""
import torch
import numpy as np
from PIL import Image
from typing import Optional
from diffusers import (
    StableDiffusionControlNetInpaintPipeline,
    ControlNetModel,
    AutoencoderKL,
    UniPCMultistepScheduler,
)
from transformers import CLIPVisionModelWithProjection, CLIPImageProcessor


class ControlNetInpainter:
    """ControlNet-based inpainting with IP-Adapter support"""

    def __init__(
        self,
        device: str = "cuda",
        model_base: str = "runwayml/stable-diffusion-v1-5",
        controlnet_model: str = "lllyasviel/control_v11p_sd15_inpaint",
        ip_adapter_model: str = "h94/IP-Adapter",
        lora_path: Optional[str] = None
    ):
        self.device = device
        self.model_base = model_base
        self.controlnet_model = controlnet_model
        self.ip_adapter_model = ip_adapter_model
        self.lora_path = lora_path

        self.pipe = None
        self._loaded = False

    def load(self):
        """Load models (call once at startup)"""
        if self._loaded:
            return

        print("Loading ControlNet Inpainting pipeline...")

        # Load VAE with better decoder
        vae = AutoencoderKL.from_pretrained(
            "stabilityai/sd-vae-ft-mse",
            torch_dtype=torch.float16
        )

        # Load ControlNet
        controlnet = ControlNetModel.from_pretrained(
            self.controlnet_model,
            torch_dtype=torch.float16
        )

        # Create pipeline
        self.pipe = StableDiffusionControlNetInpaintPipeline.from_pretrained(
            self.model_base,
            controlnet=controlnet,
            vae=vae,
            torch_dtype=torch.float16,
            safety_checker=None
        )

        # Better scheduler for faster inference
        self.pipe.scheduler = UniPCMultistepScheduler.from_config(
            self.pipe.scheduler.config
        )

        # Load IP-Adapter
        try:
            self.pipe.load_ip_adapter(
                self.ip_adapter_model,
                subfolder="models",
                weight_name="ip-adapter-plus-face_sd15.bin"
            )
            print("IP-Adapter loaded successfully")
        except Exception as e:
            print(f"Warning: Could not load IP-Adapter: {e}")

        # Load LoRA if specified
        if self.lora_path:
            try:
                self.pipe.load_lora_weights(self.lora_path)
                print(f"LoRA loaded from {self.lora_path}")
            except Exception as e:
                print(f"Warning: Could not load LoRA: {e}")

        # Move to device
        self.pipe.to(self.device)

        # Memory optimizations
        self._apply_optimizations()

        self._loaded = True
        print("Pipeline loaded successfully")

    def _apply_optimizations(self):
        """Apply memory and speed optimizations"""
        # xFormers for memory-efficient attention
        try:
            self.pipe.enable_xformers_memory_efficient_attention()
            print("xFormers enabled")
        except Exception:
            print("xFormers not available, using default attention")

        # Attention slicing for lower VRAM
        self.pipe.enable_attention_slicing(slice_size="auto")

        # VAE slicing
        self.pipe.enable_vae_slicing()

        # Optional: CPU offload for very low VRAM
        # self.pipe.enable_model_cpu_offload()

    def inpaint(
        self,
        image: Image.Image,
        mask: np.ndarray,
        style_embedding: Optional[torch.Tensor] = None,
        control_image: Optional[Image.Image] = None,
        prompt: str = "realistic eyebrow, natural skin texture, photo realistic, high quality",
        negative_prompt: str = "blurry, artificial, painted, cartoon, anime, drawing, deformed",
        denoise_strength: float = 0.75,
        guidance_scale: float = 7.5,
        num_inference_steps: int = 30,
        ip_adapter_scale: float = 0.6,
        seed: Optional[int] = None
    ) -> Image.Image:
        """
        Perform inpainting

        Args:
            image: Original image
            mask: Inpainting mask (white = areas to inpaint)
            style_embedding: IP-Adapter style embedding from source eyebrow
            control_image: ControlNet control image (edges, etc.)
            prompt: Generation prompt
            negative_prompt: Negative prompt
            denoise_strength: How much to change masked area (0-1)
            guidance_scale: CFG scale
            num_inference_steps: Number of diffusion steps
            ip_adapter_scale: IP-Adapter influence (0-1)
            seed: Random seed for reproducibility

        Returns:
            Inpainted image
        """
        if not self._loaded:
            self.load()

        # Prepare mask image
        mask_image = Image.fromarray((mask * 255).astype(np.uint8))

        # Create control image if not provided
        if control_image is None:
            control_image = self._create_control_image(image, mask)

        # Set IP-Adapter scale
        if style_embedding is not None:
            self.pipe.set_ip_adapter_scale(ip_adapter_scale)

        # Generator for reproducibility
        generator = None
        if seed is not None:
            generator = torch.Generator(device=self.device).manual_seed(seed)

        # Run inpainting
        with torch.inference_mode():
            if style_embedding is not None:
                result = self.pipe(
                    prompt=prompt,
                    negative_prompt=negative_prompt,
                    image=image,
                    mask_image=mask_image,
                    control_image=control_image,
                    ip_adapter_image_embeds=style_embedding,
                    strength=denoise_strength,
                    guidance_scale=guidance_scale,
                    num_inference_steps=num_inference_steps,
                    generator=generator
                ).images[0]
            else:
                result = self.pipe(
                    prompt=prompt,
                    negative_prompt=negative_prompt,
                    image=image,
                    mask_image=mask_image,
                    control_image=control_image,
                    strength=denoise_strength,
                    guidance_scale=guidance_scale,
                    num_inference_steps=num_inference_steps,
                    generator=generator
                ).images[0]

        return result

    def _create_control_image(self, image: Image.Image, mask: np.ndarray) -> Image.Image:
        """Create control image for ControlNet (inpaint model expects specific format)"""
        import cv2

        img_np = np.array(image.convert("RGB"))

        # For inpaint ControlNet, control image is the original with masked area
        # converted to a specific format
        control = img_np.copy()

        # Set masked area to gray (or use edge detection)
        control[mask > 0] = 128

        return Image.fromarray(control)

    def unload(self):
        """Unload models to free memory"""
        if self.pipe is not None:
            del self.pipe
            self.pipe = None
            self._loaded = False

            if torch.cuda.is_available():
                torch.cuda.empty_cache()


class IPAdapterEncoder:
    """Encode images for IP-Adapter style transfer"""

    def __init__(
        self,
        device: str = "cuda",
        model_path: str = "h94/IP-Adapter"
    ):
        self.device = device
        self.model_path = model_path

        self.image_encoder = None
        self.processor = None
        self._loaded = False

    def load(self):
        """Load encoder model"""
        if self._loaded:
            return

        print("Loading IP-Adapter encoder...")

        # CLIP Vision encoder
        self.image_encoder = CLIPVisionModelWithProjection.from_pretrained(
            self.model_path,
            subfolder="models/image_encoder",
            torch_dtype=torch.float16
        ).to(self.device)

        # Image processor
        self.processor = CLIPImageProcessor.from_pretrained(
            "openai/clip-vit-large-patch14"
        )

        self._loaded = True
        print("IP-Adapter encoder loaded")

    def encode(self, image: Image.Image) -> torch.Tensor:
        """
        Encode image to style embedding

        Args:
            image: Source eyebrow image

        Returns:
            Style embedding tensor
        """
        if not self._loaded:
            self.load()

        # Preprocess
        inputs = self.processor(images=image, return_tensors="pt")
        inputs = {k: v.to(self.device).half() for k, v in inputs.items()}

        # Encode
        with torch.inference_mode():
            outputs = self.image_encoder(**inputs)
            image_embeds = outputs.image_embeds

        return image_embeds

    def unload(self):
        """Unload to free memory"""
        if self.image_encoder is not None:
            del self.image_encoder
            del self.processor
            self.image_encoder = None
            self.processor = None
            self._loaded = False

            if torch.cuda.is_available():
                torch.cuda.empty_cache()

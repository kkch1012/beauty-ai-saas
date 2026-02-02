"""
Main Eyebrow Synthesis Pipeline
"""
import torch
import numpy as np
from PIL import Image
from dataclasses import dataclass, field
from typing import Optional, Dict, Any
import time

from app.core.models.face_detector import FaceDetector, FaceData
from app.core.models.segmentation import EyebrowSegmenter
from app.core.models.controlnet_inpaint import ControlNetInpainter, IPAdapterEncoder
from app.core.utils.color_utils import ToneHarmonizer, SkinToneAnalyzer
from app.core.utils.mask_utils import MaskProcessor


@dataclass
class SynthesisConfig:
    """Configuration for eyebrow synthesis"""
    preserve_hair_strength: float = 0.7      # Preserve existing eyebrow hair (0-1)
    blend_mode: str = "multiply"             # Blending mode: multiply, soft_light, overlay
    tone_correction: bool = True             # Apply tone harmonization
    denoise_strength: float = 0.75           # Inpainting strength
    guidance_scale: float = 7.5              # CFG scale
    num_inference_steps: int = 30            # Diffusion steps
    ip_adapter_scale: float = 0.6            # Style transfer strength
    seed: Optional[int] = None               # Random seed


@dataclass
class SynthesisResult:
    """Result of eyebrow synthesis"""
    final_image: Image.Image
    debug_images: Dict[str, Image.Image] = field(default_factory=dict)
    metadata: Dict[str, Any] = field(default_factory=dict)
    processing_time_ms: int = 0


class EyebrowSynthesisPipeline:
    """
    Main pipeline for eyebrow synthesis

    Pipeline steps:
    1. Face detection & landmark extraction
    2. Eyebrow segmentation
    3. Hair/skin separation
    4. Style embedding extraction (IP-Adapter)
    5. ControlNet inpainting
    6. Hair blending
    7. Tone harmonization
    """

    def __init__(
        self,
        device: str = "cuda",
        model_base: str = "runwayml/stable-diffusion-v1-5",
        sam_checkpoint: str = "models/sam_vit_h.pth",
        lora_path: Optional[str] = None
    ):
        self.device = device

        # Initialize components
        print("Initializing pipeline components...")

        self.face_detector = FaceDetector(device=device)
        self.segmenter = EyebrowSegmenter(device=device, sam_checkpoint=sam_checkpoint)
        self.inpainter = ControlNetInpainter(
            device=device,
            model_base=model_base,
            lora_path=lora_path
        )
        self.ip_adapter = IPAdapterEncoder(device=device)
        self.tone_harmonizer = ToneHarmonizer()
        self.skin_analyzer = SkinToneAnalyzer()
        self.mask_processor = MaskProcessor()

        self._models_loaded = False

    def load_models(self):
        """Load all AI models (call once at startup)"""
        if self._models_loaded:
            return

        print("Loading AI models...")
        self.inpainter.load()
        self.ip_adapter.load()
        self._models_loaded = True
        print("All models loaded")

    def synthesize(
        self,
        target_image: Image.Image,
        source_eyebrow: Image.Image,
        config: Optional[SynthesisConfig] = None,
        return_debug: bool = False
    ) -> SynthesisResult:
        """
        Synthesize eyebrow on target face

        Args:
            target_image: Customer's face image
            source_eyebrow: Eyebrow design image
            config: Synthesis configuration
            return_debug: Include debug images in result

        Returns:
            SynthesisResult with final image and metadata
        """
        start_time = time.time()
        config = config or SynthesisConfig()
        debug_images = {}

        # Ensure models are loaded
        self.load_models()

        # ===== Step 1: Face Detection =====
        print("Step 1: Detecting face...")
        face_data = self.face_detector.detect(target_image)
        if face_data is None:
            raise ValueError("No face detected in target image")

        if return_debug:
            debug_images["landmarks"] = self.face_detector.visualize_landmarks(
                target_image, face_data
            )

        # ===== Step 2: Eyebrow Segmentation =====
        print("Step 2: Segmenting eyebrow...")
        eyebrow_mask = self.segmenter.segment_eyebrow(target_image, face_data)

        if return_debug:
            debug_images["eyebrow_mask"] = self._mask_to_image(eyebrow_mask)

        # ===== Step 3: Separate Hair and Skin =====
        print("Step 3: Separating hair and skin...")
        hair_mask, skin_mask = self.segmenter.separate_hair_and_skin(
            target_image, eyebrow_mask
        )

        if return_debug:
            debug_images["hair_mask"] = self._mask_to_image(hair_mask)
            debug_images["skin_mask"] = self._mask_to_image(skin_mask)

        # ===== Step 4: Extract Style Embedding =====
        print("Step 4: Extracting style embedding...")
        style_embedding = self.ip_adapter.encode(source_eyebrow)

        # ===== Step 5: Create Inpainting Mask =====
        print("Step 5: Creating inpainting mask...")
        inpaint_mask = self.mask_processor.create_inpaint_mask(
            eyebrow_mask=eyebrow_mask,
            hair_mask=hair_mask,
            preserve_strength=config.preserve_hair_strength
        )

        if return_debug:
            debug_images["inpaint_mask"] = self._mask_to_image(inpaint_mask)

        # ===== Step 6: Inpainting =====
        print("Step 6: Running inpainting...")
        raw_result = self.inpainter.inpaint(
            image=target_image,
            mask=inpaint_mask,
            style_embedding=style_embedding,
            denoise_strength=config.denoise_strength,
            guidance_scale=config.guidance_scale,
            num_inference_steps=config.num_inference_steps,
            ip_adapter_scale=config.ip_adapter_scale,
            seed=config.seed
        )

        if return_debug:
            debug_images["raw_inpaint"] = raw_result

        # ===== Step 7: Blend with Original Hair =====
        print("Step 7: Blending with original hair...")
        blended = self._blend_with_original_hair(
            original=target_image,
            inpainted=raw_result,
            hair_mask=hair_mask,
            blend_mode=config.blend_mode
        )

        if return_debug:
            debug_images["blended"] = blended

        # ===== Step 8: Tone Harmonization =====
        if config.tone_correction:
            print("Step 8: Harmonizing tones...")
            final = self.tone_harmonizer.harmonize(
                result=blended,
                reference=target_image,
                region_mask=eyebrow_mask
            )
        else:
            final = blended

        # Calculate processing time
        processing_time = int((time.time() - start_time) * 1000)

        print(f"Synthesis complete in {processing_time}ms")

        return SynthesisResult(
            final_image=final,
            debug_images=debug_images if return_debug else {},
            metadata={
                "face_detected": True,
                "config": config.__dict__,
                "face_bbox": face_data.bounding_box
            },
            processing_time_ms=processing_time
        )

    def analyze_face(self, image: Image.Image) -> Dict[str, Any]:
        """
        Analyze face for consultation (skin tone, face shape, etc.)

        Args:
            image: Face image

        Returns:
            Analysis results
        """
        face_data = self.face_detector.detect(image)
        if face_data is None:
            raise ValueError("No face detected")

        # Skin tone analysis
        skin_tone = self.skin_analyzer.analyze(image, face_data.landmarks)

        # Golden ratio analysis
        golden_ratio = self._analyze_golden_ratio(face_data)

        return {
            "skin_tone": {
                "type": skin_tone.tone,
                "brightness": skin_tone.brightness,
                "hex_color": skin_tone.hex_color,
                "recommendation": skin_tone.recommendation
            },
            "golden_ratio": golden_ratio,
            "face_bbox": face_data.bounding_box
        }

    def extract_design(self, image: Image.Image) -> tuple[Image.Image, Dict[str, Any]]:
        """
        Extract eyebrow design from an image

        Args:
            image: Image containing eyebrows

        Returns:
            (extracted_image, metadata)
        """
        face_data = self.face_detector.detect(image)
        if face_data is None:
            raise ValueError("No face detected")

        extracted, mask = self.segmenter.extract_eyebrow_design(image, face_data)

        # Generate style embedding for later use
        self.ip_adapter.load()
        embedding = self.ip_adapter.encode(extracted)

        return extracted, {
            "embedding_shape": list(embedding.shape),
            "mask_coverage": float(mask.sum()) / mask.size
        }

    def _blend_with_original_hair(
        self,
        original: Image.Image,
        inpainted: Image.Image,
        hair_mask: np.ndarray,
        blend_mode: str
    ) -> Image.Image:
        """Blend inpainted result with original hair"""
        original_np = np.array(original).astype(np.float32)
        inpainted_np = np.array(inpainted).astype(np.float32)

        # Feather hair mask for smooth blending
        hair_mask_soft = self.mask_processor.feather_mask(hair_mask, radius=3)
        hair_mask_3ch = np.stack([hair_mask_soft] * 3, axis=-1)

        if blend_mode == "multiply":
            # Multiply blend - pigment effect
            blended_hair = (original_np * inpainted_np) / 255.0
        elif blend_mode == "soft_light":
            blended_hair = self._soft_light_blend(original_np, inpainted_np)
        elif blend_mode == "overlay":
            blended_hair = self._overlay_blend(original_np, inpainted_np)
        else:
            blended_hair = inpainted_np

        # Hair region: blend original + effect, other regions: inpainted
        result = (
            hair_mask_3ch * (original_np * 0.3 + blended_hair * 0.7) +
            (1 - hair_mask_3ch) * inpainted_np
        )

        return Image.fromarray(result.clip(0, 255).astype(np.uint8))

    def _soft_light_blend(self, base: np.ndarray, blend: np.ndarray) -> np.ndarray:
        """Soft light blending mode"""
        base_norm = base / 255.0
        blend_norm = blend / 255.0

        result = np.where(
            blend_norm <= 0.5,
            base_norm - (1 - 2 * blend_norm) * base_norm * (1 - base_norm),
            base_norm + (2 * blend_norm - 1) * (np.sqrt(base_norm) - base_norm)
        )

        return (result * 255).clip(0, 255)

    def _overlay_blend(self, base: np.ndarray, blend: np.ndarray) -> np.ndarray:
        """Overlay blending mode"""
        base_norm = base / 255.0
        blend_norm = blend / 255.0

        result = np.where(
            base_norm <= 0.5,
            2 * base_norm * blend_norm,
            1 - 2 * (1 - base_norm) * (1 - blend_norm)
        )

        return (result * 255).clip(0, 255)

    def _analyze_golden_ratio(self, face_data: FaceData) -> Dict[str, Any]:
        """Analyze facial golden ratio for eyebrow placement"""
        landmarks = face_data.landmarks

        # Key points
        left_eye = landmarks[FaceData.LEFT_EYE_INDICES].mean(axis=0)
        right_eye = landmarks[FaceData.RIGHT_EYE_INDICES].mean(axis=0)
        nose_tip = landmarks[FaceData.NOSE_TIP_INDEX]

        # Calculate face width
        face_width = np.linalg.norm(right_eye[:2] - left_eye[:2]) * 2.5

        # Ideal eyebrow measurements (golden ratio based)
        phi = 1.618
        ideal_eyebrow_length = face_width * 0.32
        ideal_eyebrow_gap = face_width / phi / phi  # ~38% of face width

        # Current measurements
        left_eyebrow = face_data.get_left_eyebrow_points()
        right_eyebrow = face_data.get_right_eyebrow_points()

        current_left_length = np.linalg.norm(
            left_eyebrow[0, :2] - left_eyebrow[-1, :2]
        )
        current_right_length = np.linalg.norm(
            right_eyebrow[0, :2] - right_eyebrow[-1, :2]
        )

        # Symmetry check
        left_height = left_eyebrow[:, 1].mean()
        right_height = right_eyebrow[:, 1].mean()
        height_diff = abs(left_height - right_height)

        is_symmetric = height_diff < face_width * 0.02  # 2% tolerance

        return {
            "face_width": float(face_width),
            "ideal_eyebrow_length": float(ideal_eyebrow_length),
            "current_left_length": float(current_left_length),
            "current_right_length": float(current_right_length),
            "is_symmetric": is_symmetric,
            "height_difference": float(height_diff),
            "recommendations": self._get_ratio_recommendations(
                current_left_length, current_right_length,
                ideal_eyebrow_length, is_symmetric
            )
        }

    def _get_ratio_recommendations(
        self,
        left_len: float,
        right_len: float,
        ideal_len: float,
        is_symmetric: bool
    ) -> list[str]:
        """Generate recommendations based on analysis"""
        recommendations = []

        avg_len = (left_len + right_len) / 2
        if avg_len < ideal_len * 0.85:
            recommendations.append("눈썹 길이가 짧습니다. 꼬리 부분 연장을 권장합니다.")
        elif avg_len > ideal_len * 1.15:
            recommendations.append("눈썹 길이가 깁니다. 꼬리 부분 정리를 권장합니다.")

        if not is_symmetric:
            recommendations.append("좌우 눈썹 높이가 다릅니다. 균형 조정을 권장합니다.")

        if len(recommendations) == 0:
            recommendations.append("눈썹 비율이 이상적입니다.")

        return recommendations

    def _mask_to_image(self, mask: np.ndarray) -> Image.Image:
        """Convert mask to viewable image"""
        if mask.max() <= 1:
            mask = (mask * 255).astype(np.uint8)
        return Image.fromarray(mask)

    def unload_models(self):
        """Unload models to free memory"""
        self.inpainter.unload()
        self.ip_adapter.unload()
        self._models_loaded = False

        if torch.cuda.is_available():
            torch.cuda.empty_cache()

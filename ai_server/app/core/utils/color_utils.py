"""
Color Processing Utilities for Tone Harmonization
"""
import cv2
import numpy as np
from PIL import Image
from skimage import exposure
from typing import Tuple, Optional
from dataclasses import dataclass


@dataclass
class SkinToneResult:
    """Skin tone analysis result"""
    tone: str  # "warm", "cool", "neutral"
    brightness: str  # "17호", "21호", "23호", etc.
    hex_color: str
    lab_values: Tuple[float, float, float]  # L, a, b
    recommendation: str


class SkinToneAnalyzer:
    """Analyze skin tone from face image"""

    def analyze(
        self,
        image: Image.Image,
        face_landmarks: np.ndarray
    ) -> SkinToneResult:
        """
        Analyze skin tone from face image

        Args:
            image: Face image
            face_landmarks: MediaPipe landmarks (468 points)

        Returns:
            SkinToneResult with tone classification
        """
        img_np = np.array(image.convert("RGB"))

        # Sample points from forehead and cheeks
        forehead_indices = [10, 151, 9, 8, 168]
        left_cheek_indices = [123, 147, 187, 207]
        right_cheek_indices = [352, 376, 411, 427]

        sample_indices = forehead_indices + left_cheek_indices + right_cheek_indices
        sample_colors = []

        for idx in sample_indices:
            if idx < len(face_landmarks):
                x, y = int(face_landmarks[idx][0]), int(face_landmarks[idx][1])

                # Get average color in small region
                region = img_np[
                    max(0, y-5):min(img_np.shape[0], y+5),
                    max(0, x-5):min(img_np.shape[1], x+5)
                ]

                if region.size > 0:
                    avg_color = region.mean(axis=(0, 1))
                    sample_colors.append(avg_color)

        if not sample_colors:
            return SkinToneResult(
                tone="neutral",
                brightness="21호",
                hex_color="#E0C8B0",
                lab_values=(70, 10, 15),
                recommendation="분석 불가"
            )

        # Average color
        avg_color = np.mean(sample_colors, axis=0).astype(np.uint8)

        # Convert to LAB
        rgb_pixel = np.array([[avg_color]], dtype=np.uint8)
        lab_pixel = cv2.cvtColor(rgb_pixel, cv2.COLOR_RGB2LAB)[0, 0]
        l, a, b = float(lab_pixel[0]), float(lab_pixel[1]) - 128, float(lab_pixel[2]) - 128

        # Classify tone (based on b* value)
        if b > 10:
            tone = "warm"
            tone_kr = "웜톤"
        elif b < -5:
            tone = "cool"
            tone_kr = "쿨톤"
        else:
            tone = "neutral"
            tone_kr = "뉴트럴"

        # Classify brightness (based on L* value)
        if l > 75:
            brightness = "17호"
        elif l > 70:
            brightness = "21호"
        elif l > 65:
            brightness = "23호"
        elif l > 60:
            brightness = "25호"
        else:
            brightness = "27호"

        # Convert to hex
        hex_color = "#{:02x}{:02x}{:02x}".format(*avg_color)

        # Recommendation
        recommendation = f"피부톤: {brightness} {tone_kr}"
        if tone == "warm":
            recommendation += " / 권장 눈썹색: 브라운, 카키브라운"
        elif tone == "cool":
            recommendation += " / 권장 눈썹색: 그레이브라운, 애쉬브라운"
        else:
            recommendation += " / 권장 눈썹색: 다크브라운, 내추럴브라운"

        return SkinToneResult(
            tone=tone,
            brightness=brightness,
            hex_color=hex_color,
            lab_values=(l, a, b),
            recommendation=recommendation
        )


class ToneHarmonizer:
    """Harmonize synthesized result with original skin tone"""

    def harmonize(
        self,
        result: Image.Image,
        reference: Image.Image,
        region_mask: np.ndarray,
        strength: float = 0.7
    ) -> Image.Image:
        """
        Harmonize color tones in synthesized result

        Args:
            result: Synthesized image
            reference: Original image (color reference)
            region_mask: Mask of region to harmonize
            strength: Harmonization strength (0-1)

        Returns:
            Color-harmonized image
        """
        result_np = np.array(result).astype(np.float32)
        reference_np = np.array(reference).astype(np.float32)

        # Expand mask region for smoother blending
        expanded_mask = self._expand_mask(region_mask, iterations=10)
        feathered_mask = self._feather_mask(expanded_mask, radius=15)
        mask_3ch = np.stack([feathered_mask] * 3, axis=-1)

        # Method 1: Histogram matching
        matched = self._histogram_match(result_np, reference_np, region_mask)

        # Method 2: Reinhard color transfer
        transferred = self._reinhard_color_transfer(result_np, reference_np, region_mask)

        # Blend both methods
        harmonized = (matched * 0.5 + transferred * 0.5)

        # Apply with strength
        final = (
            mask_3ch * strength * harmonized +
            mask_3ch * (1 - strength) * result_np +
            (1 - mask_3ch) * result_np
        )

        return Image.fromarray(final.clip(0, 255).astype(np.uint8))

    def _histogram_match(
        self,
        source: np.ndarray,
        reference: np.ndarray,
        mask: np.ndarray
    ) -> np.ndarray:
        """Match histogram of masked region"""
        result = source.copy()

        for i in range(3):
            src_channel = source[:, :, i]
            ref_channel = reference[:, :, i]

            # Only match within mask region
            if mask.sum() > 0:
                matched = exposure.match_histograms(
                    src_channel,
                    ref_channel,
                    channel_axis=None
                )
                result[:, :, i] = np.where(mask > 0, matched, src_channel)

        return result

    def _reinhard_color_transfer(
        self,
        source: np.ndarray,
        target: np.ndarray,
        mask: np.ndarray
    ) -> np.ndarray:
        """Reinhard color transfer algorithm"""
        # Convert to LAB
        source_lab = cv2.cvtColor(source.astype(np.uint8), cv2.COLOR_RGB2LAB).astype(np.float32)
        target_lab = cv2.cvtColor(target.astype(np.uint8), cv2.COLOR_RGB2LAB).astype(np.float32)

        mask_bool = mask > 0
        result_lab = source_lab.copy()

        for i in range(3):
            # Source statistics
            src_masked = source_lab[:, :, i][mask_bool]
            tgt_masked = target_lab[:, :, i][mask_bool]

            if len(src_masked) == 0 or len(tgt_masked) == 0:
                continue

            src_mean = src_masked.mean()
            src_std = src_masked.std() + 1e-6

            tgt_mean = tgt_masked.mean()
            tgt_std = tgt_masked.std() + 1e-6

            # Transfer
            channel = source_lab[:, :, i]
            normalized = (channel - src_mean) / src_std
            transferred = normalized * tgt_std + tgt_mean

            result_lab[:, :, i] = np.where(mask_bool, transferred, channel)

        # Convert back to RGB
        result_lab = np.clip(result_lab, 0, 255).astype(np.uint8)
        result = cv2.cvtColor(result_lab, cv2.COLOR_LAB2RGB)

        return result.astype(np.float32)

    def _feather_mask(self, mask: np.ndarray, radius: int) -> np.ndarray:
        """Feather mask edges"""
        mask_float = mask.astype(np.float32)
        if mask_float.max() > 1:
            mask_float = mask_float / 255.0

        kernel_size = radius * 2 + 1
        blurred = cv2.GaussianBlur(mask_float, (kernel_size, kernel_size), 0)

        return blurred

    def _expand_mask(self, mask: np.ndarray, iterations: int) -> np.ndarray:
        """Expand mask region"""
        kernel = np.ones((3, 3), np.uint8)
        expanded = cv2.dilate(mask.astype(np.uint8), kernel, iterations=iterations)
        return expanded

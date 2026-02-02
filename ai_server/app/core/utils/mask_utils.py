"""
Mask Processing Utilities
"""
import cv2
import numpy as np
from typing import Tuple


class MaskProcessor:
    """Utilities for processing segmentation masks"""

    @staticmethod
    def create_inpaint_mask(
        eyebrow_mask: np.ndarray,
        hair_mask: np.ndarray,
        preserve_strength: float = 0.7
    ) -> np.ndarray:
        """
        Create inpainting mask that preserves existing hair

        Args:
            eyebrow_mask: Full eyebrow region mask
            hair_mask: Existing eyebrow hair mask
            preserve_strength: How much to preserve existing hair (0-1)

        Returns:
            Inpainting mask (uint8, 0-255)
        """
        # Start with full eyebrow region
        inpaint_mask = eyebrow_mask.copy().astype(np.float32)

        # Reduce weight in hair regions (to preserve them)
        hair_weight = 1.0 - preserve_strength
        inpaint_mask[hair_mask > 0] *= hair_weight

        # Binarize
        inpaint_mask = (inpaint_mask > 0.3).astype(np.uint8)

        # Feather edges
        inpaint_mask = MaskProcessor.feather_mask(inpaint_mask, radius=2)

        return (inpaint_mask * 255).astype(np.uint8)

    @staticmethod
    def feather_mask(mask: np.ndarray, radius: int) -> np.ndarray:
        """Apply Gaussian blur to feather mask edges"""
        if radius <= 0:
            return mask.astype(np.float32)

        mask_float = mask.astype(np.float32)
        if mask_float.max() > 1:
            mask_float = mask_float / 255.0

        kernel_size = radius * 2 + 1
        blurred = cv2.GaussianBlur(mask_float, (kernel_size, kernel_size), 0)

        return blurred

    @staticmethod
    def erode_mask(mask: np.ndarray, iterations: int = 1) -> np.ndarray:
        """Erode mask"""
        kernel = np.ones((3, 3), np.uint8)
        return cv2.erode(mask.astype(np.uint8), kernel, iterations=iterations)

    @staticmethod
    def dilate_mask(mask: np.ndarray, iterations: int = 1) -> np.ndarray:
        """Dilate mask"""
        kernel = np.ones((3, 3), np.uint8)
        return cv2.dilate(mask.astype(np.uint8), kernel, iterations=iterations)

    @staticmethod
    def smooth_mask(mask: np.ndarray, kernel_size: int = 5) -> np.ndarray:
        """Smooth mask with morphological operations"""
        kernel = np.ones((kernel_size, kernel_size), np.uint8)

        # Close (fill small holes)
        smoothed = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_CLOSE, kernel)

        # Open (remove small noise)
        smoothed = cv2.morphologyEx(smoothed, cv2.MORPH_OPEN, kernel)

        return smoothed

    @staticmethod
    def get_mask_bbox(mask: np.ndarray, padding: int = 0) -> Tuple[int, int, int, int]:
        """Get bounding box of mask region"""
        y_indices, x_indices = np.where(mask > 0)

        if len(y_indices) == 0:
            return (0, 0, mask.shape[1], mask.shape[0])

        x_min = max(0, x_indices.min() - padding)
        x_max = min(mask.shape[1], x_indices.max() + padding)
        y_min = max(0, y_indices.min() - padding)
        y_max = min(mask.shape[0], y_indices.max() + padding)

        return (x_min, y_min, x_max - x_min, y_max - y_min)

    @staticmethod
    def mask_to_rgba(
        image: np.ndarray,
        mask: np.ndarray
    ) -> np.ndarray:
        """Apply mask as alpha channel"""
        if image.shape[2] == 3:
            rgba = np.dstack([image, np.ones(image.shape[:2], dtype=np.uint8) * 255])
        else:
            rgba = image.copy()

        # Set alpha based on mask
        rgba[:, :, 3] = (mask * 255).astype(np.uint8)

        return rgba

    @staticmethod
    def combine_masks(*masks: np.ndarray, operation: str = "union") -> np.ndarray:
        """Combine multiple masks"""
        if len(masks) == 0:
            raise ValueError("At least one mask required")

        result = masks[0].astype(bool)

        for mask in masks[1:]:
            if operation == "union":
                result = np.logical_or(result, mask)
            elif operation == "intersection":
                result = np.logical_and(result, mask)
            elif operation == "difference":
                result = np.logical_and(result, ~mask.astype(bool))

        return result.astype(np.uint8)

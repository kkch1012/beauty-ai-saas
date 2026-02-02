"""
Eyebrow Segmentation using SAM (Segment Anything Model)
"""
import torch
import numpy as np
from PIL import Image
from typing import Tuple, Optional
import cv2

try:
    from segment_anything import sam_model_registry, SamPredictor
    SAM_AVAILABLE = True
except ImportError:
    SAM_AVAILABLE = False
    print("Warning: segment_anything not installed. Using fallback segmentation.")

from app.core.models.face_detector import FaceData


class EyebrowSegmenter:
    """SAM-based eyebrow segmentation"""

    def __init__(self, device: str = "cuda", sam_checkpoint: str = "models/sam_vit_h.pth"):
        self.device = device
        self.sam_checkpoint = sam_checkpoint
        self.predictor = None

        if SAM_AVAILABLE:
            self._load_sam()

    def _load_sam(self):
        """Load SAM model"""
        try:
            sam = sam_model_registry["vit_h"](checkpoint=self.sam_checkpoint)
            sam.to(self.device)
            self.predictor = SamPredictor(sam)
            print("SAM model loaded successfully")
        except Exception as e:
            print(f"Failed to load SAM model: {e}")
            self.predictor = None

    def segment_eyebrow(
        self,
        image: Image.Image,
        face_data: FaceData
    ) -> np.ndarray:
        """
        Segment eyebrow region

        Args:
            image: Input image
            face_data: Face detection result with landmarks

        Returns:
            Binary mask (H, W) where 1 = eyebrow region
        """
        img_np = np.array(image.convert("RGB"))
        h, w = img_np.shape[:2]

        if self.predictor is not None:
            return self._segment_with_sam(img_np, face_data)
        else:
            return self._segment_fallback(img_np, face_data)

    def _segment_with_sam(self, img_np: np.ndarray, face_data: FaceData) -> np.ndarray:
        """Use SAM for precise segmentation"""
        self.predictor.set_image(img_np)
        h, w = img_np.shape[:2]

        masks = []

        for eyebrow_indices in [FaceData.LEFT_EYEBROW_INDICES, FaceData.RIGHT_EYEBROW_INDICES]:
            # Get eyebrow landmark points
            points = face_data.landmarks[eyebrow_indices][:, :2]

            # Use points as prompts for SAM
            input_points = points.astype(np.float32)
            input_labels = np.ones(len(input_points), dtype=np.int32)

            mask, score, _ = self.predictor.predict(
                point_coords=input_points,
                point_labels=input_labels,
                multimask_output=False
            )

            masks.append(mask[0])

        # Combine left and right eyebrow masks
        combined_mask = np.logical_or(masks[0], masks[1]).astype(np.uint8)

        return combined_mask

    def _segment_fallback(self, img_np: np.ndarray, face_data: FaceData) -> np.ndarray:
        """Fallback segmentation using convex hull of landmarks"""
        h, w = img_np.shape[:2]
        mask = np.zeros((h, w), dtype=np.uint8)

        for eyebrow_indices in [FaceData.LEFT_EYEBROW_INDICES, FaceData.RIGHT_EYEBROW_INDICES]:
            points = face_data.landmarks[eyebrow_indices][:, :2].astype(np.int32)

            # Create convex hull
            hull = cv2.convexHull(points)

            # Fill the hull
            cv2.fillConvexPoly(mask, hull, 1)

        # Dilate slightly to ensure coverage
        kernel = np.ones((5, 5), np.uint8)
        mask = cv2.dilate(mask, kernel, iterations=2)

        return mask

    def separate_hair_and_skin(
        self,
        image: Image.Image,
        eyebrow_mask: np.ndarray
    ) -> Tuple[np.ndarray, np.ndarray]:
        """
        Separate hair (existing eyebrow strands) from skin within eyebrow region

        This is critical for preserving natural eyebrow hair while adding pigment

        Args:
            image: Input image
            eyebrow_mask: Binary mask of eyebrow region

        Returns:
            (hair_mask, skin_mask) - both binary numpy arrays
        """
        img_np = np.array(image.convert("RGB"))

        # Extract eyebrow region
        eyebrow_region = img_np.copy()
        eyebrow_region[eyebrow_mask == 0] = 255  # Set background to white

        # === Method 1: Color-based separation ===
        # Convert to LAB color space
        lab = cv2.cvtColor(eyebrow_region, cv2.COLOR_RGB2LAB)
        l_channel = lab[:, :, 0]

        # Dark regions = hair (Otsu's threshold)
        _, hair_mask_otsu = cv2.threshold(
            l_channel, 0, 255,
            cv2.THRESH_BINARY_INV + cv2.THRESH_OTSU
        )
        hair_mask_otsu = (hair_mask_otsu > 0).astype(np.uint8)

        # === Method 2: Texture-based (Gabor filter) ===
        hair_mask_gabor = self._detect_hair_texture(eyebrow_region)

        # Combine both methods
        hair_mask = np.logical_and(
            hair_mask_otsu > 0,
            hair_mask_gabor > 0
        ).astype(np.uint8)

        # Apply only within eyebrow region
        hair_mask = np.logical_and(hair_mask, eyebrow_mask > 0).astype(np.uint8)

        # Skin mask = eyebrow region - hair
        skin_mask = np.logical_and(
            eyebrow_mask > 0,
            hair_mask == 0
        ).astype(np.uint8)

        # Clean up with morphological operations
        kernel = np.ones((3, 3), np.uint8)
        hair_mask = cv2.morphologyEx(hair_mask, cv2.MORPH_CLOSE, kernel)
        skin_mask = cv2.morphologyEx(skin_mask, cv2.MORPH_OPEN, kernel)

        return hair_mask, skin_mask

    def _detect_hair_texture(self, image: np.ndarray) -> np.ndarray:
        """Detect hair texture using Gabor filters"""
        gray = cv2.cvtColor(image, cv2.COLOR_RGB2GRAY)

        # Apply Gabor filters at multiple orientations
        responses = []
        for theta in np.arange(0, np.pi, np.pi / 8):
            kernel = cv2.getGaborKernel(
                ksize=(21, 21),
                sigma=3.0,
                theta=theta,
                lambd=8.0,
                gamma=0.5,
                psi=0
            )
            response = cv2.filter2D(gray, cv2.CV_64F, kernel)
            responses.append(np.abs(response))

        # Take maximum response across orientations
        max_response = np.max(responses, axis=0)

        # Threshold
        threshold = np.percentile(max_response[max_response > 0], 70)
        hair_texture = (max_response > threshold).astype(np.uint8)

        return hair_texture

    def extract_eyebrow_design(
        self,
        image: Image.Image,
        face_data: FaceData,
        padding: int = 30
    ) -> Tuple[Image.Image, np.ndarray]:
        """
        Extract eyebrow design from an image (for design library)

        Args:
            image: Source image containing eyebrows
            face_data: Face detection result
            padding: Padding around eyebrow region

        Returns:
            (cropped_image, mask) - Extracted eyebrow with transparent background
        """
        img_np = np.array(image.convert("RGBA"))

        # Get eyebrow mask
        eyebrow_mask = self.segment_eyebrow(image, face_data)

        # Get bounding box
        y_indices, x_indices = np.where(eyebrow_mask > 0)
        if len(y_indices) == 0:
            raise ValueError("No eyebrow region found")

        x_min = max(0, x_indices.min() - padding)
        x_max = min(img_np.shape[1], x_indices.max() + padding)
        y_min = max(0, y_indices.min() - padding)
        y_max = min(img_np.shape[0], y_indices.max() + padding)

        # Crop
        cropped = img_np[y_min:y_max, x_min:x_max].copy()
        cropped_mask = eyebrow_mask[y_min:y_max, x_min:x_max]

        # Apply mask to alpha channel
        if cropped.shape[2] == 4:
            cropped[:, :, 3] = (cropped_mask * 255).astype(np.uint8)
        else:
            alpha = (cropped_mask * 255).astype(np.uint8)
            cropped = np.dstack([cropped, alpha])

        return Image.fromarray(cropped, "RGBA"), cropped_mask

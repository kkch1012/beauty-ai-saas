"""
Face Detection and Landmark Extraction using MediaPipe
"""
import numpy as np
import mediapipe as mp
from PIL import Image
from dataclasses import dataclass
from typing import Optional, List, Tuple
import cv2


@dataclass
class FaceData:
    """Face detection result"""
    landmarks: np.ndarray  # (468, 3) - x, y, z coordinates
    bounding_box: Tuple[int, int, int, int]  # x, y, width, height
    confidence: float

    # Key landmark indices
    LEFT_EYEBROW_INDICES = [70, 63, 105, 66, 107, 55, 65, 52, 53, 46, 124, 35, 111, 117, 118, 119]
    RIGHT_EYEBROW_INDICES = [300, 293, 334, 296, 336, 285, 295, 282, 283, 276, 353, 265, 340, 346, 347, 348]
    LEFT_EYE_INDICES = [33, 133, 160, 159, 158, 144, 145, 153]
    RIGHT_EYE_INDICES = [362, 263, 387, 386, 385, 373, 374, 380]
    NOSE_TIP_INDEX = 1
    FOREHEAD_INDICES = [10, 151, 9, 8, 168, 6, 197, 195, 5]

    def get_left_eyebrow_points(self) -> np.ndarray:
        return self.landmarks[self.LEFT_EYEBROW_INDICES]

    def get_right_eyebrow_points(self) -> np.ndarray:
        return self.landmarks[self.RIGHT_EYEBROW_INDICES]

    def get_eyebrow_region(self, padding: int = 20) -> Tuple[int, int, int, int]:
        """Get bounding box for both eyebrows with padding"""
        left_points = self.get_left_eyebrow_points()
        right_points = self.get_right_eyebrow_points()
        all_points = np.vstack([left_points, right_points])

        x_min = int(all_points[:, 0].min()) - padding
        y_min = int(all_points[:, 1].min()) - padding
        x_max = int(all_points[:, 0].max()) + padding
        y_max = int(all_points[:, 1].max()) + padding

        return (x_min, y_min, x_max - x_min, y_max - y_min)


class FaceDetector:
    """MediaPipe Face Mesh based detector"""

    def __init__(self, device: str = "cuda"):
        self.device = device

        # Initialize MediaPipe Face Mesh
        self.mp_face_mesh = mp.solutions.face_mesh
        self.face_mesh = self.mp_face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            refine_landmarks=True,  # Include iris landmarks
            min_detection_confidence=0.5,
            min_tracking_confidence=0.5
        )

    def detect(self, image: Image.Image) -> Optional[FaceData]:
        """
        Detect face and extract landmarks

        Args:
            image: PIL Image

        Returns:
            FaceData or None if no face detected
        """
        # Convert to RGB numpy array
        img_np = np.array(image.convert("RGB"))
        h, w = img_np.shape[:2]

        # Process with MediaPipe
        results = self.face_mesh.process(img_np)

        if not results.multi_face_landmarks:
            return None

        face_landmarks = results.multi_face_landmarks[0]

        # Convert normalized coordinates to pixel coordinates
        landmarks = np.array([
            [lm.x * w, lm.y * h, lm.z * w]
            for lm in face_landmarks.landmark
        ])

        # Calculate bounding box
        x_coords = landmarks[:, 0]
        y_coords = landmarks[:, 1]
        bbox = (
            int(x_coords.min()),
            int(y_coords.min()),
            int(x_coords.max() - x_coords.min()),
            int(y_coords.max() - y_coords.min())
        )

        return FaceData(
            landmarks=landmarks,
            bounding_box=bbox,
            confidence=1.0  # MediaPipe doesn't provide per-face confidence
        )

    def detect_batch(self, images: List[Image.Image]) -> List[Optional[FaceData]]:
        """Process multiple images"""
        return [self.detect(img) for img in images]

    def visualize_landmarks(
        self,
        image: Image.Image,
        face_data: FaceData,
        draw_eyebrows: bool = True,
        draw_mesh: bool = False
    ) -> Image.Image:
        """Draw landmarks on image for debugging"""
        img_np = np.array(image.convert("RGB")).copy()

        if draw_mesh:
            # Draw all face mesh connections
            mp_drawing = mp.solutions.drawing_utils
            mp_drawing_styles = mp.solutions.drawing_styles
            # ... simplified for brevity

        if draw_eyebrows:
            # Draw eyebrow points
            for idx in FaceData.LEFT_EYEBROW_INDICES + FaceData.RIGHT_EYEBROW_INDICES:
                pt = face_data.landmarks[idx]
                cv2.circle(img_np, (int(pt[0]), int(pt[1])), 2, (0, 255, 0), -1)

            # Draw eyebrow contour
            left_pts = face_data.get_left_eyebrow_points()[:, :2].astype(np.int32)
            right_pts = face_data.get_right_eyebrow_points()[:, :2].astype(np.int32)

            cv2.polylines(img_np, [left_pts], False, (255, 0, 0), 2)
            cv2.polylines(img_np, [right_pts], False, (255, 0, 0), 2)

        return Image.fromarray(img_np)

    def __del__(self):
        self.face_mesh.close()

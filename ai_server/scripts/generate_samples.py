"""
샘플 이미지 자동 생성 스크립트

Before → 1차 성형 → 최종 성형 이미지를 API로 자동 생성합니다.
Replicate API를 사용하여 SDXL + Inpainting으로 눈썹만 자연스럽게 변형합니다.

사용법:
    export REPLICATE_API_TOKEN="your_token_here"
    python generate_samples.py
"""

import os
import sys
import time
import requests
import numpy as np
from io import BytesIO
from pathlib import Path
from datetime import datetime

try:
    import replicate
except ImportError:
    print("replicate 패키지를 설치하세요: pip install replicate")
    sys.exit(1)

try:
    import mediapipe as mp
except ImportError:
    print("mediapipe 패키지를 설치하세요: pip install mediapipe")
    sys.exit(1)

try:
    from PIL import Image
except ImportError:
    print("Pillow 패키지를 설치하세요: pip install Pillow")
    sys.exit(1)

try:
    import cv2
except ImportError:
    print("opencv-python 패키지를 설치하세요: pip install opencv-python")
    sys.exit(1)


class SampleGenerator:
    """눈썹 성형 샘플 이미지 생성기"""

    # 얼굴형별 Before 프롬프트
    BEFORE_PROMPTS = {
        "round": """Portrait photo of young Korean woman age 25 with round soft face shape.
Long straight black hair with middle part reaching shoulders.
Monolid eyes, dark brown iris, small nose with rounded tip.
Clear light beige skin, natural no makeup look.
EYEBROWS: Thin sparse ungroomed natural eyebrows with visible gaps between hairs.
Obvious asymmetry - left brow slightly higher than right.
Some hairs pointing in random different directions.
Weak thin tails that fade out. Overall unkempt appearance.
Front facing, neutral expression, soft studio lighting, pure white background.
High resolution professional beauty portrait photography.""",

        "long": """Portrait photo of young Korean woman age 27 with long oval face shape.
Long straight black hair with middle part reaching shoulders.
Monolid eyes, dark brown iris, straight nose bridge.
Clear light beige skin, natural no makeup look.
EYEBROWS: Overly arched curved eyebrows that make face look even longer.
Very obvious asymmetry - left eyebrow noticeably higher and more arched than right.
Sparse patchy areas with visible skin gaps throughout brows.
Messy scattered hairs pointing in completely different directions.
Thin weak tails that droop downward. Tired unkempt appearance.
Front facing, neutral expression, soft studio lighting, pure white background.
High resolution professional beauty portrait photography.""",

        "square": """Portrait photo of young Korean woman age 28 with square jaw angular face shape.
Long straight black hair with middle part reaching shoulders.
Monolid eyes, dark brown iris, defined nose bridge.
Clear light beige skin, natural no makeup look.
EYEBROWS: Thick bushy ungroomed natural eyebrows with stray hairs everywhere.
Hairs going in random directions, some pointing up some down.
Slight unibrow - visible hair growth between the brows.
Uneven thickness, messy edges, needs serious professional help.
Front facing, neutral expression, soft studio lighting, pure white background.
High resolution professional beauty portrait photography."""
    }

    # 얼굴형별 1차 성형 프롬프트
    STAGE1_PROMPTS = {
        "round": """Slightly groomed natural eyebrows showing first professional touch.
Hairs now brushed in more uniform upward-outward direction.
Asymmetry improved but not perfect yet.
Edges slightly cleaner, stray hairs reduced.
Tails lifted but still thin.
Natural hair texture fully preserved, not filled in.
Looks like first grooming session - noticeable improvement but not final result.""",

        "long": """Partially straightened eyebrows, arch height visibly reduced.
Shape transitioning from curved to straighter horizontal style.
Left and right brows more balanced and symmetric now.
All hairs redirected to flow in uniform direction.
Edges cleaner and more defined, tails lifted horizontally.
Natural hair texture preserved throughout.
Clear improvement from messy before state but still work in progress.""",

        "square": """Cleaned up eyebrows with stray hairs removed.
Shape becoming softer and more feminine.
Unibrow area cleaned, brows now clearly separated.
Hairs directed in uniform pattern.
Thickness more even, edges more refined.
Natural hair texture maintained, not drawn or filled.
Visible transformation toward softer look but not complete yet."""
    }

    # 얼굴형별 최종 성형 프롬프트
    FINAL_PROMPTS = {
        "round": """Beautifully shaped soft arched eyebrows - perfect final result.
Golden ratio arch position to visually elongate round face.
Arch peaks at two-thirds from inner corner, above outer iris edge.
Perfect mirror symmetry between left and right brows.
Fuller appearance with gaps now looking intentionally feathered.
Every hair aligned perfectly in sleek uniform direction.
Premium brow lamination finish - polished and sophisticated.
Natural hair texture 100% preserved, looks like perfect natural growth.
Stunning transformation that beautifully frames her eyes.
Face appears slimmer and more balanced.""",

        "long": """Perfect straight horizontal Korean-style eyebrows - stunning final result.
Minimal to no arch - sleek straight line ideal for long face.
Golden ratio positioning visually shortens her long face.
Both brows perfectly parallel and symmetric.
Fuller thicker appearance from start to end, no weak tails.
Every hair aligned perfectly in uniform direction.
Premium brow lamination finish - modern and sophisticated.
Natural hair texture preserved, looks naturally perfect.
Face appears more balanced and proportionate.
Dramatic beautiful transformation.""",

        "square": """Soft curved feminine eyebrows - gorgeous final result.
Gentle arch that softens her angular jaw and square features.
Golden ratio curve position ideal for square face shape.
Perfect symmetry, beautifully balanced left and right.
Refined thickness, elegant shape from start to end.
Every hair perfectly groomed in uniform direction.
Premium brow lamination finish - soft and feminine.
Natural hair texture preserved, looks effortlessly perfect.
Face appears softer, more feminine, more balanced.
Stunning transformation that complements her features."""
    }

    # 눈썹 랜드마크 인덱스 (MediaPipe Face Mesh)
    LEFT_EYEBROW_IDX = [276, 283, 282, 295, 285, 300, 293, 334, 296, 336]
    RIGHT_EYEBROW_IDX = [46, 53, 52, 65, 55, 70, 63, 105, 66, 107]

    def __init__(self, output_dir: str = None):
        """
        초기화

        Args:
            output_dir: 출력 디렉토리 경로
        """
        self.output_dir = Path(output_dir) if output_dir else Path("./generated_samples")
        self.output_dir.mkdir(parents=True, exist_ok=True)

        # MediaPipe Face Mesh 초기화
        self.face_mesh = mp.solutions.face_mesh.FaceMesh(
            static_image_mode=True,
            max_num_faces=1,
            refine_landmarks=True,
            min_detection_confidence=0.5
        )

        print(f"출력 디렉토리: {self.output_dir.absolute()}")

    def generate_before(self, face_type: str) -> str:
        """
        Before 이미지 생성

        Args:
            face_type: 얼굴형 ("round", "long", "square")

        Returns:
            생성된 이미지 URL
        """
        print(f"\n[Before 생성] {face_type} 얼굴형...")

        prompt = self.BEFORE_PROMPTS.get(face_type)
        if not prompt:
            raise ValueError(f"Unknown face type: {face_type}")

        output = replicate.run(
            "stability-ai/sdxl:39ed52f2a78e934b3ba6e2a89f5b1c712de7dfea535525255b1aa35c5565e08b",
            input={
                "prompt": prompt,
                "negative_prompt": "groomed eyebrows, perfect brows, makeup on brows, microblading, tattooed brows, drawn eyebrows, cartoon, anime, illustration, painting",
                "width": 1024,
                "height": 1024,
                "num_outputs": 1,
                "scheduler": "K_EULER",
                "num_inference_steps": 30,
                "guidance_scale": 7.5
            }
        )

        image_url = output[0] if isinstance(output, list) else output
        print(f"  생성 완료: {image_url[:80]}...")

        return image_url

    def download_image(self, url: str) -> Image.Image:
        """URL에서 이미지 다운로드"""
        response = requests.get(url)
        response.raise_for_status()
        return Image.open(BytesIO(response.content)).convert("RGB")

    def create_eyebrow_mask(self, image: Image.Image, expansion: int = 40) -> Image.Image:
        """
        눈썹 영역 마스크 생성

        Args:
            image: 입력 이미지
            expansion: 마스크 확장 크기 (픽셀)

        Returns:
            눈썹 영역 마스크 이미지 (흰색=편집영역)
        """
        print("  마스크 생성 중...")

        image_np = np.array(image)
        h, w = image_np.shape[:2]

        # 얼굴 랜드마크 감지
        results = self.face_mesh.process(cv2.cvtColor(image_np, cv2.COLOR_RGB2BGR))

        if not results.multi_face_landmarks:
            raise Exception("얼굴을 감지할 수 없습니다")

        landmarks = results.multi_face_landmarks[0]

        # 마스크 생성 (검은색 배경)
        mask = np.zeros((h, w), dtype=np.uint8)

        # 양쪽 눈썹 영역에 대해
        for eyebrow_idx in [self.LEFT_EYEBROW_IDX, self.RIGHT_EYEBROW_IDX]:
            points = []
            for idx in eyebrow_idx:
                lm = landmarks.landmark[idx]
                x = int(lm.x * w)
                y = int(lm.y * h)
                points.append([x, y])

            points = np.array(points)

            # 눈썹 위아래로 영역 확장
            min_y = points[:, 1].min() - expansion
            max_y = points[:, 1].max() + expansion // 2
            min_x = points[:, 0].min() - expansion // 2
            max_x = points[:, 0].max() + expansion // 2

            # 사각형 마스크 그리기
            cv2.rectangle(mask, (min_x, min_y), (max_x, max_y), 255, -1)

        # 마스크 블러 처리 (부드러운 경계)
        mask = cv2.GaussianBlur(mask, (21, 21), 0)

        print("  마스크 생성 완료")

        return Image.fromarray(mask).convert("RGB")

    def upload_to_tmpfiles(self, image: Image.Image) -> str:
        """
        이미지를 임시 파일 호스팅에 업로드

        Args:
            image: 업로드할 이미지

        Returns:
            업로드된 이미지 URL
        """
        # 이미지를 바이트로 변환
        buffer = BytesIO()
        image.save(buffer, format="PNG")
        buffer.seek(0)

        # tmpfiles.org에 업로드 (1시간 유효)
        response = requests.post(
            "https://tmpfiles.org/api/v1/upload",
            files={"file": ("image.png", buffer, "image/png")}
        )

        if response.status_code == 200:
            data = response.json()
            # URL 변환: tmpfiles.org/xxx -> tmpfiles.org/dl/xxx
            url = data["data"]["url"].replace("tmpfiles.org/", "tmpfiles.org/dl/")
            return url
        else:
            raise Exception(f"업로드 실패: {response.status_code}")

    def generate_stage(self, base_image_url: str, mask: Image.Image,
                       face_type: str, stage: str) -> str:
        """
        성형 단계 이미지 생성 (Inpainting)

        Args:
            base_image_url: 기반 이미지 URL
            mask: 눈썹 마스크
            face_type: 얼굴형
            stage: "stage1" 또는 "final"

        Returns:
            생성된 이미지 URL
        """
        stage_name = "1차 성형" if stage == "stage1" else "최종 성형"
        print(f"\n[{stage_name} 생성] {face_type} 얼굴형...")

        # 프롬프트 선택
        if stage == "stage1":
            prompt = self.STAGE1_PROMPTS[face_type]
        else:
            prompt = self.FINAL_PROMPTS[face_type]

        # 마스크 업로드
        mask_url = self.upload_to_tmpfiles(mask)
        print(f"  마스크 업로드 완료")

        # Inpainting 실행
        output = replicate.run(
            "stability-ai/stable-diffusion-inpainting:95b7223104132402a9ae91cc677285bc5eb997834bd2349fa486f53910fd68b3",
            input={
                "image": base_image_url,
                "mask": mask_url,
                "prompt": f"eyebrow area only: {prompt}",
                "negative_prompt": "tattooed eyebrows, microblading, drawn on brows, unnatural, fake looking, harsh edges, solid filled brows, cartoon, different face, changed face shape",
                "num_outputs": 1,
                "num_inference_steps": 30,
                "guidance_scale": 7.5
            }
        )

        image_url = output[0] if isinstance(output, list) else output
        print(f"  생성 완료: {image_url[:80]}...")

        return image_url

    def save_image(self, url: str, filename: str) -> str:
        """
        이미지 다운로드 및 저장

        Args:
            url: 이미지 URL
            filename: 저장할 파일명

        Returns:
            저장된 파일 경로
        """
        image = self.download_image(url)
        filepath = self.output_dir / filename
        image.save(filepath)
        print(f"  저장됨: {filepath}")
        return str(filepath)

    def generate_full_set(self, face_type: str) -> dict:
        """
        한 얼굴형에 대한 전체 세트 생성 (Before + 1차 + 최종)

        Args:
            face_type: 얼굴형 ("round", "long", "square")

        Returns:
            생성된 이미지 URL 딕셔너리
        """
        print(f"\n{'='*60}")
        print(f" {face_type.upper()} 얼굴형 세트 생성 시작")
        print(f"{'='*60}")

        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

        # 1. Before 이미지 생성
        before_url = self.generate_before(face_type)
        before_path = self.save_image(before_url, f"{face_type}_before_{timestamp}.png")

        # 2. Before 이미지 다운로드 및 마스크 생성
        before_image = self.download_image(before_url)
        mask = self.create_eyebrow_mask(before_image)
        mask.save(self.output_dir / f"{face_type}_mask_{timestamp}.png")

        # 3. 1차 성형 이미지 생성
        stage1_url = self.generate_stage(before_url, mask, face_type, "stage1")
        stage1_path = self.save_image(stage1_url, f"{face_type}_stage1_{timestamp}.png")

        # 4. 1차 성형 이미지 기반으로 새 마스크 생성
        stage1_image = self.download_image(stage1_url)
        mask2 = self.create_eyebrow_mask(stage1_image)

        # 5. 최종 성형 이미지 생성
        final_url = self.generate_stage(stage1_url, mask2, face_type, "final")
        final_path = self.save_image(final_url, f"{face_type}_final_{timestamp}.png")

        result = {
            "face_type": face_type,
            "before": {"url": before_url, "path": before_path},
            "stage1": {"url": stage1_url, "path": stage1_path},
            "final": {"url": final_url, "path": final_path}
        }

        print(f"\n{face_type} 세트 완료!")

        return result

    def generate_all_sets(self) -> list:
        """
        모든 얼굴형에 대한 세트 생성 (총 9장)

        Returns:
            생성 결과 리스트
        """
        results = []

        for face_type in ["round", "long", "square"]:
            try:
                result = self.generate_full_set(face_type)
                results.append(result)

                # API 속도 제한 방지
                time.sleep(2)

            except Exception as e:
                print(f"\n[에러] {face_type} 생성 실패: {e}")
                continue

        return results


def main():
    """메인 실행 함수"""

    # API 키 확인
    if not os.environ.get("REPLICATE_API_TOKEN"):
        print("=" * 60)
        print("REPLICATE_API_TOKEN 환경변수를 설정하세요!")
        print("")
        print("1. https://replicate.com 에서 가입")
        print("2. API 토큰 복사")
        print("3. 터미널에서 실행:")
        print("   export REPLICATE_API_TOKEN='your_token_here'")
        print("=" * 60)
        sys.exit(1)

    # 출력 디렉토리 설정
    output_dir = Path(__file__).parent.parent / "generated_samples"

    # 생성기 초기화
    generator = SampleGenerator(output_dir=str(output_dir))

    print("\n" + "=" * 60)
    print(" 눈썹 성형 샘플 이미지 자동 생성기")
    print(" Before → 1차 성형 → 최종 성형")
    print("=" * 60)

    # 얼굴형 선택
    print("\n생성할 얼굴형을 선택하세요:")
    print("1. 둥근 얼굴 (round)")
    print("2. 긴 얼굴 (long)")
    print("3. 각진 얼굴 (square)")
    print("4. 전체 (3가지 모두)")

    choice = input("\n선택 (1-4): ").strip()

    if choice == "1":
        generator.generate_full_set("round")
    elif choice == "2":
        generator.generate_full_set("long")
    elif choice == "3":
        generator.generate_full_set("square")
    elif choice == "4":
        generator.generate_all_sets()
    else:
        print("잘못된 선택입니다.")
        sys.exit(1)

    print("\n" + "=" * 60)
    print(" 생성 완료!")
    print(f" 결과물 위치: {output_dir.absolute()}")
    print("=" * 60)


if __name__ == "__main__":
    main()

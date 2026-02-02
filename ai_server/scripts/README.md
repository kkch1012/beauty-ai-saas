# 샘플 이미지 생성 스크립트

눈썹 성형 시뮬레이션 샘플 이미지를 자동으로 생성합니다.

## 생성되는 이미지

| 단계 | 설명 |
|------|------|
| Before | 정리 안 된 자연 상태 눈썹 |
| 1차 성형 | 기본 정돈 (털 방향, 대칭 개선) |
| 최종 성형 | 황금비율 완성 (얼굴형 맞춤) |

얼굴형 3가지 × 단계 3개 = **총 9장** 생성

## 사전 준비

### 1. Replicate API 토큰 발급

1. https://replicate.com 가입
2. Settings > API tokens에서 토큰 복사

### 2. 패키지 설치

```bash
cd ai_server
pip install replicate mediapipe Pillow opencv-python requests
```

## 실행 방법

### 환경변수 설정

```bash
export REPLICATE_API_TOKEN="r8_your_token_here"
```

### 스크립트 실행

```bash
cd ai_server/scripts
python generate_samples.py
```

### 선택 메뉴

```
생성할 얼굴형을 선택하세요:
1. 둥근 얼굴 (round)
2. 긴 얼굴 (long)
3. 각진 얼굴 (square)
4. 전체 (3가지 모두)

선택 (1-4):
```

## 출력 결과

생성된 이미지는 `ai_server/generated_samples/` 폴더에 저장됩니다:

```
generated_samples/
├── round_before_20240201_143022.png
├── round_stage1_20240201_143022.png
├── round_final_20240201_143022.png
├── round_mask_20240201_143022.png
├── long_before_20240201_143156.png
├── long_stage1_20240201_143156.png
├── long_final_20240201_143156.png
...
```

## 비용

| API | 대략적 비용 |
|-----|------------|
| SDXL (Before 생성) | ~$0.003/장 |
| Inpainting (성형) | ~$0.005/장 |
| **총 9장** | **~$0.05** |

## 프롬프트 커스터마이징

`generate_samples.py` 파일 내의 다음 변수들을 수정하여 프롬프트를 조정할 수 있습니다:

- `BEFORE_PROMPTS`: Before 이미지 생성 프롬프트
- `STAGE1_PROMPTS`: 1차 성형 프롬프트
- `FINAL_PROMPTS`: 최종 성형 프롬프트

## 문제 해결

### "얼굴을 감지할 수 없습니다" 에러

Before 이미지에서 얼굴이 잘 안 나온 경우입니다. 다시 실행하세요.

### API 속도 제한

Replicate 무료 플랜은 속도 제한이 있습니다. 에러 발생 시 잠시 후 다시 시도하세요.

### 이미지 품질이 낮음

프롬프트의 `num_inference_steps`를 30 → 50으로 올리면 품질이 향상됩니다 (비용 증가).

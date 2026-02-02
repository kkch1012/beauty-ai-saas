# 사용자가 해야 할 일 (TODO List)

이 문서는 프로젝트를 완성하기 위해 **반드시 해야 할 작업들**을 정리한 것입니다.

---

## 1. 필수 설정 작업

### 1.1 Supabase 프로젝트 생성
- [ ] [Supabase](https://supabase.com)에서 새 프로젝트 생성
- [ ] Project URL과 API Keys 복사
- [ ] `supabase/migrations/*.sql` 파일들을 SQL Editor에서 실행
- [ ] Storage 버킷 생성 확인

### 1.2 RevenueCat 설정
- [ ] [RevenueCat](https://www.revenuecat.com) 계정 생성
- [ ] iOS/Android 앱 등록
- [ ] 상품(Products) 생성:
  - `beautyshop_basic_monthly` - ₩29,000
  - `beautyshop_basic_yearly` - ₩290,000
  - `beautyshop_premium_monthly` - ₩79,000
- [ ] Entitlements 생성: `basic`, `premium`
- [ ] Webhook URL 설정: `https://your-project.supabase.co/functions/v1/revenuecat-webhook`

### 1.3 Apple/Google 개발자 계정
- [ ] Apple Developer Program 가입 ($99/년)
- [ ] Google Play Console 가입 ($25 일회성)
- [ ] 앱 번들 ID 등록

---

## 2. AI 모델 준비

### 2.1 필수 모델 다운로드
- [ ] **SAM (Segment Anything Model)**
  ```bash
  # models/sam_vit_h.pth 다운로드
  wget https://dl.fbaipublicfiles.com/segment_anything/sam_vit_h_4b8939.pth -O ai_server/models/sam_vit_h.pth
  ```

- [ ] **Stable Diffusion 모델** (자동 다운로드됨)
  - 첫 실행 시 HuggingFace에서 자동 다운로드
  - 약 4GB 필요

- [ ] **ControlNet 모델** (자동 다운로드됨)

- [ ] **IP-Adapter 모델** (자동 다운로드됨)

### 2.2 LoRA 학습 (선택사항이지만 권장)
- [ ] 눈썹 시술 사진 50-100장 수집
- [ ] 학습 데이터 준비:
  ```bash
  cd ai_server
  python scripts/train_lora.py prepare --raw_dir ./raw_images --output_dir ./training_data
  ```
- [ ] LoRA 학습 실행:
  ```bash
  python scripts/train_lora.py train --data_dir ./training_data --epochs 100
  ```

---

## 3. GPU 서버 준비

### 3.1 옵션 A: 클라우드 GPU (권장)
- [ ] AWS, GCP, 또는 RunPod에서 GPU 인스턴스 생성
- [ ] 권장 사양:
  - **개발**: NVIDIA A10G (24GB) - AWS g5.xlarge
  - **프로덕션**: NVIDIA L4 (24GB) x 2
- [ ] Docker 설치
- [ ] AI 서버 Docker 이미지 빌드 및 배포

### 3.2 옵션 B: 온프레미스
- [ ] NVIDIA GPU (RTX 3090 이상, VRAM 24GB 권장)
- [ ] CUDA 12.1 + cuDNN 설치
- [ ] Python 환경 설정

---

## 4. 코드 수정 필요 부분

### 4.1 Flutter 앱

#### 네이티브 MediaPipe 연동 (AR 기능)
현재 ML Kit만 사용 중. MediaPipe 468 랜드마크를 사용하려면:

- [ ] `android/app/src/main/kotlin/.../MediaPipeFaceModule.kt` 작성
- [ ] `ios/Runner/MediaPipeFaceModule.swift` 작성
- [ ] Platform Channel 연동

```dart
// lib/core/platform/mediapipe_channel.dart 작성 필요
```

#### 카메라 이미지 변환
- [ ] `capture_screen.dart`의 `_convertCameraImage` 메서드 구현
  - iOS: `bgra8888` 형식 처리
  - Android: `yuv420` 형식 처리

### 4.2 AI 서버

#### 모델 경로 수정
- [ ] `.env` 파일에서 실제 모델 경로 설정
- [ ] SAM 모델 경로 확인

---

## 5. 테스트 및 검증

### 5.1 AI 파이프라인 테스트
- [ ] 얼굴 감지 테스트
- [ ] 눈썹 세그멘테이션 테스트
- [ ] 합성 품질 테스트
- [ ] 처리 시간 측정 (목표: 2-5초)

### 5.2 앱 테스트
- [ ] 카메라 권한 테스트
- [ ] 얼굴 인식 정확도 테스트
- [ ] 시뮬레이션 플로우 테스트
- [ ] 결제 플로우 테스트 (Sandbox)

### 5.3 관리자 웹 테스트
- [ ] 로그인 테스트
- [ ] 대시보드 데이터 표시 테스트
- [ ] 회원 목록 조회 테스트

---

## 6. 배포

### 6.1 AI 서버 배포
```bash
# Docker 빌드
docker build -t beauty-ai-server ./ai_server

# Docker 실행
docker run -d --gpus all -p 8000:8000 beauty-ai-server
```

### 6.2 Flutter 앱 배포
- [ ] iOS:
  ```bash
  flutter build ipa
  # App Store Connect에 업로드
  ```
- [ ] Android:
  ```bash
  flutter build appbundle
  # Google Play Console에 업로드
  ```

### 6.3 관리자 웹 배포
- [ ] Vercel 또는 자체 서버에 배포
  ```bash
  cd admin_web
  npm run build
  ```

---

## 7. 추가 구현 필요 기능

### 우선순위 높음
- [ ] 고객 CRUD 완성
- [ ] 예약 기능 완성
- [ ] 계약서 PDF 생성
- [ ] 전자서명 저장

### 우선순위 중간
- [ ] 푸시 알림 (예약 리마인더)
- [ ] 예약금 PG 결제 연동 (토스페이먼츠)
- [ ] Before/After 비교 UI

### 우선순위 낮음
- [ ] 다국어 지원
- [ ] 다크 모드
- [ ] 통계 리포트

---

## 8. 보안 체크리스트

- [ ] API 키를 환경변수로 관리
- [ ] Supabase RLS 정책 테스트
- [ ] HTTPS 적용
- [ ] 민감한 데이터 암호화
- [ ] 로그에서 개인정보 제거

---

## 9. 비용 예상

| 항목 | 월 비용 (예상) |
|------|---------------|
| Supabase Pro | $25 |
| GPU 서버 (AWS g5.xlarge) | $300-500 |
| RevenueCat | 매출의 1% |
| Apple Developer | $8.25 ($99/년) |
| **총합** | **~$350-550/월** |

---

## 10. 문의 및 지원

기술적인 문제가 있으면:
1. 코드 주석 확인
2. 에러 메시지 검색
3. 관련 문서 참조

---

## 체크리스트 요약

```
[ ] Supabase 설정
[ ] RevenueCat 설정
[ ] 모델 다운로드
[ ] GPU 서버 준비
[ ] 네이티브 코드 작성
[ ] 테스트
[ ] 배포
```

**예상 소요 시간**: 2-4주 (풀타임 기준)

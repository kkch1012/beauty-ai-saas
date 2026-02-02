# Beauty AI SaaS - 프로젝트 진행 상황

> AI 기반 눈썹 시뮬레이션 및 전자계약 시스템

---

## 📋 프로젝트 개요

| 항목 | 내용 |
|------|------|
| 프로젝트명 | Beauty AI SaaS |
| 목적 | 미용실용 AI 눈썹 시뮬레이션 + 전자계약 플랫폼 |
| 타겟 | 반영구/눈썹 전문 미용실 |

### 핵심 기능
- 🎯 고객 얼굴 촬영 + AR 가이드
- 🤖 AI 눈썹 합성 (자기 털 유지 + 황금비율)
- 📝 전자 계약서 (서명 포함)
- 📅 예약 관리
- 💳 구독 결제 시스템

---

## 🏗️ 기술 스택

| 구성요소 | 기술 | 상태 |
|----------|------|------|
| 태블릿 앱 | Flutter | ✅ 코드 완성 |
| Admin 웹 | Next.js | ✅ 기본 구조 완성 |
| AI 서버 | Python + FastAPI | ✅ 코드 완성 |
| 데이터베이스 | Supabase (PostgreSQL) | ✅ 스키마 완성 |
| 인증 | Supabase Auth | ✅ 코드 완성 |
| 스토리지 | Supabase Storage | ✅ 설정 완성 |
| 결제 | RevenueCat | ⏸️ 임시 비활성화 |
| AI 모델 | ControlNet + IP-Adapter | ✅ 코드 완성 |

---

## 📁 프로젝트 구조

```
beauty-ai-saas/
├── flutter_app/          # Flutter 태블릿 앱
├── admin_web/            # Next.js 관리자 웹
├── ai_server/            # Python AI 서버
│   ├── app/              # FastAPI 앱
│   ├── scripts/          # 유틸리티 스크립트
│   └── generated_samples/# 생성된 샘플 이미지
├── supabase/             # Supabase 설정
│   ├── migrations/       # DB 마이그레이션
│   └── functions/        # Edge Functions
└── docs/                 # 문서
```

---

## ✅ 완료된 작업

### 2024-XX-XX (Day 1)

#### AI 서버
- [x] FastAPI 프로젝트 구조 설정
- [x] MediaPipe 얼굴 감지 모듈 (`face_detector.py`)
- [x] SAM 기반 눈썹 세그멘테이션 (`segmentation.py`)
- [x] ControlNet + IP-Adapter 인페인팅 (`controlnet_inpaint.py`)
- [x] 피부톤 분석 + 톤 하모니제이션 (`color_utils.py`)
- [x] 눈썹 합성 파이프라인 (`eyebrow_pipeline.py`)
- [x] API 엔드포인트 (`synthesis.py`)
- [x] LoRA 훈련 스크립트 (`train_lora.py`)
- [x] 샘플 이미지 생성 스크립트 (`generate_samples.py`)

#### Flutter 앱
- [x] 프로젝트 초기화 및 의존성 설정
- [x] Riverpod 상태 관리 구조
- [x] GoRouter 네비게이션 설정
- [x] Supabase 연동 서비스
- [x] AI 서버 통신 서비스
- [x] 구독 서비스 (RevenueCat)
- [x] 인증 서비스
- [x] 카메라 캡처 화면
- [x] AR 얼굴 가이드 오버레이
- [x] 시뮬레이션 화면
- [x] 앱 테마 설정
- [x] macOS 빌드 테스트 성공 ✅

#### Supabase
- [x] 데이터베이스 스키마 설계
- [x] RLS 정책 설정
- [x] Storage 버킷 설정
- [x] RevenueCat 웹훅 Edge Function

#### Admin Web
- [x] Next.js 프로젝트 구조
- [x] 대시보드 레이아웃
- [x] 기본 페이지 구성

---

## 🔄 진행 중인 작업

### 샘플 이미지 생성
- [ ] Replicate API 토큰 발급
- [ ] 둥근 얼굴 세트 생성 (Before/1차/최종)
- [ ] 긴 얼굴 세트 생성 (Before/1차/최종)
- [ ] 각진 얼굴 세트 생성 (Before/1차/최종)

---

## 📝 TODO (사용자 작업 필요)

### 1단계: 기본 설정 (필수)

#### Supabase 설정
- [ ] https://supabase.com 프로젝트 생성
- [ ] Project URL 복사
- [ ] Anon Key 복사
- [ ] SQL Editor에서 마이그레이션 실행:
  - `supabase/migrations/001_initial_schema.sql`
  - `supabase/migrations/002_storage_setup.sql`

#### Flutter 앱 설정
- [ ] `flutter_app/.env` 파일 생성:
  ```
  SUPABASE_URL=https://your-project.supabase.co
  SUPABASE_ANON_KEY=your_anon_key
  AI_SERVER_URL=http://localhost:8000
  ```

### 2단계: 결제 시스템 (선택)

#### RevenueCat 설정
- [ ] https://app.revenuecat.com 프로젝트 생성
- [ ] Apple App Store Connect 연동
- [ ] Google Play Console 연동
- [ ] 상품 등록 (basic, premium)
- [ ] Entitlements 설정
- [ ] API 키 복사

#### 인앱 결제 설정
- [ ] App Store Connect에서 인앱 결제 상품 등록
- [ ] Google Play Console에서 인앱 결제 상품 등록

### 3단계: AI 서버 (GPU 필요)

#### 모델 다운로드 (~7GB)
- [ ] Stable Diffusion v1.5 Inpainting
- [ ] ControlNet Inpaint 모델
- [ ] IP-Adapter 모델
- [ ] SAM 모델 (sam_vit_h)

```bash
cd ai_server
python -c "from app.core.models.controlnet_inpaint import ControlNetInpaintModel; ControlNetInpaintModel()"
```

#### 서버 실행
```bash
cd ai_server
pip install -r requirements.txt
uvicorn app.main:app --host 0.0.0.0 --port 8000
```

### 4단계: 샘플 이미지 생성

```bash
export REPLICATE_API_TOKEN="your_token"
cd ai_server/scripts
python generate_samples.py
```

---

## 🐛 알려진 이슈

### 1. RevenueCat Swift 호환성 (해결됨)
- **문제**: `SubscriptionPeriod` 타입 충돌로 macOS 빌드 실패
- **해결**: RevenueCat 임시 비활성화
- **상태**: ⏸️ 추후 버전 업데이트 시 재활성화 필요

### 2. 폰트 파일 없음 (해결됨)
- **문제**: Pretendard 폰트 파일 없음
- **해결**: pubspec.yaml에서 폰트 설정 주석 처리
- **상태**: ✅ 추후 폰트 파일 추가 필요

### 3. Grok 이미지 편집 제한
- **문제**: 얼굴 이미지 편집 시 모자이크 처리됨
- **원인**: AI 안전 정책으로 얼굴 편집 제한
- **해결**: Replicate API + Inpainting 사용
- **상태**: ✅ 해결됨

---

## 📊 테스트 결과

### Flutter 앱 빌드

| 플랫폼 | 상태 | 비고 |
|--------|------|------|
| macOS | ✅ 성공 | Debug 빌드 완료 |
| iOS | 🔄 미테스트 | 실기기 필요 |
| Android | 🔄 미테스트 | 에뮬레이터/실기기 필요 |

### AI 서버

| 항목 | 상태 | 비고 |
|------|------|------|
| 코드 | ✅ 완성 | 리뷰 완료 |
| 모델 로딩 | 🔄 미테스트 | GPU 서버 필요 |
| API 엔드포인트 | 🔄 미테스트 | 모델 로딩 후 테스트 |

---

## 🚀 배포 계획

### Phase 1: 개발 환경
- [ ] 로컬 개발 환경 완전 구축
- [ ] AI 서버 GPU 인스턴스 확보
- [ ] 샘플 이미지 생성 완료

### Phase 2: 테스트
- [ ] iOS 실기기 테스트
- [ ] Android 실기기 테스트
- [ ] AI 합성 품질 테스트
- [ ] 사용자 플로우 테스트

### Phase 3: 베타 출시
- [ ] TestFlight 배포
- [ ] 베타 테스터 모집
- [ ] 피드백 수집

### Phase 4: 정식 출시
- [ ] App Store 심사 제출
- [ ] Google Play 심사 제출
- [ ] 마케팅 준비

---

## 📞 참고 링크

| 서비스 | URL |
|--------|-----|
| Supabase | https://supabase.com |
| RevenueCat | https://revenuecat.com |
| Replicate | https://replicate.com |
| Flutter | https://flutter.dev |

---

## 📅 업데이트 기록

| 날짜 | 내용 |
|------|------|
| 2024-XX-XX | 프로젝트 초기 설정 완료 |
| 2024-XX-XX | AI 서버 코드 작성 완료 |
| 2024-XX-XX | Flutter 앱 코드 작성 완료 |
| 2024-XX-XX | macOS 빌드 테스트 성공 |
| 2024-XX-XX | 샘플 이미지 생성 스크립트 추가 |

---

> 마지막 업데이트: 2024-XX-XX

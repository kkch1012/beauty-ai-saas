# Beauty AI SaaS - 뷰티샵 Gen-AI 시뮬레이션 플랫폼

AI 기반 눈썹 시뮬레이션 및 전자계약 통합 SaaS 솔루션

## 프로젝트 구조

```
beauty-ai-saas/
├── ai_server/          # Python FastAPI AI 서버
├── flutter_app/        # Flutter 태블릿 앱
├── admin_web/          # Next.js 관리자 웹
├── supabase/           # Supabase 설정 (DB, Functions)
└── docs/               # 문서
```

## 기술 스택

| 구성요소 | 기술 |
|---------|------|
| 태블릿 앱 | Flutter 3.x |
| 관리자 웹 | Next.js 14 + TypeScript |
| AI 서버 | Python FastAPI + PyTorch |
| 데이터베이스 | Supabase (PostgreSQL) |
| 인증 | Supabase Auth |
| 파일 저장 | Supabase Storage |
| 결제 | RevenueCat (인앱결제) |
| AI 모델 | Stable Diffusion + ControlNet + IP-Adapter |

## 빠른 시작

### 1. 사전 요구사항

- Python 3.11+
- Flutter 3.16+
- Node.js 18+
- Docker (선택)
- NVIDIA GPU (AI 서버용, CUDA 12.1+)

### 2. AI 서버 설정

```bash
cd ai_server

# 가상환경 생성
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 의존성 설치
pip install -r requirements.txt

# 환경변수 설정
cp .env.example .env
# .env 파일 편집

# 모델 다운로드 (SAM)
# models/sam_vit_h.pth 다운로드 필요

# 서버 실행
uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload
```

### 3. Supabase 설정

```bash
# Supabase CLI 설치
npm install -g supabase

# 프로젝트 링크
cd supabase
supabase link --project-ref your-project-ref

# 마이그레이션 실행
supabase db push

# Edge Functions 배포
supabase functions deploy revenuecat-webhook
supabase functions deploy reset-monthly-usage
```

### 4. Flutter 앱 빌드

```bash
cd flutter_app

# 의존성 설치
flutter pub get

# 환경변수와 함께 실행
flutter run --dart-define=SUPABASE_URL=https://xxx.supabase.co \
            --dart-define=SUPABASE_ANON_KEY=xxx \
            --dart-define=AI_SERVER_URL=http://localhost:8000 \
            --dart-define=REVENUECAT_APPLE_KEY=xxx \
            --dart-define=REVENUECAT_GOOGLE_KEY=xxx
```

### 5. 관리자 웹 실행

```bash
cd admin_web

# 의존성 설치
npm install

# 환경변수 설정
cp .env.example .env.local
# .env.local 편집

# 개발 서버 실행
npm run dev
```

## API 문서

AI 서버 API 문서: http://localhost:8000/docs

## 라이선스

Proprietary - All rights reserved

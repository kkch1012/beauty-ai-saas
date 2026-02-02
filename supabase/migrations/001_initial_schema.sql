-- ============================================
-- Beauty AI SaaS Database Schema
-- Migration: 001_initial_schema
-- ============================================

-- Enable extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================
-- 1. PROFILES (사용자/가맹점)
-- ============================================
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT NOT NULL,
    business_name TEXT,                    -- 샵 이름
    owner_name TEXT,                       -- 원장님 이름
    phone TEXT,
    address TEXT,
    business_number TEXT,                  -- 사업자등록번호

    -- 구독 정보 (RevenueCat 연동)
    subscription_tier TEXT DEFAULT 'free' CHECK (subscription_tier IN ('free', 'basic', 'premium')),
    subscription_status TEXT DEFAULT 'inactive' CHECK (subscription_status IN ('active', 'inactive', 'cancelled', 'expired')),
    subscription_expires_at TIMESTAMPTZ,
    revenuecat_user_id TEXT,

    -- 사용량
    monthly_synthesis_count INT DEFAULT 0,
    monthly_synthesis_limit INT DEFAULT 10,
    current_period_start TIMESTAMPTZ DEFAULT DATE_TRUNC('month', NOW()),

    -- 설정
    settings JSONB DEFAULT '{}',

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 프로필 자동 생성 트리거
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO public.profiles (id, email)
    VALUES (NEW.id, NEW.email);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION public.handle_new_user();

-- ============================================
-- 2. CUSTOMERS (고객 관리)
-- ============================================
CREATE TABLE public.customers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    phone TEXT,
    email TEXT,
    birth_date DATE,
    gender TEXT CHECK (gender IN ('male', 'female', 'other')),

    -- 분석 결과
    skin_tone TEXT,                        -- warm, cool, neutral
    skin_brightness TEXT,                  -- 17호, 21호, 23호 등
    skin_hex_color TEXT,
    face_shape TEXT,

    -- 메모
    notes TEXT,
    tags TEXT[],                           -- 태그 배열

    -- 통계
    visit_count INT DEFAULT 0,
    last_visit_at TIMESTAMPTZ,
    total_spent DECIMAL(12, 2) DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_customers_profile ON public.customers(profile_id);
CREATE INDEX idx_customers_phone ON public.customers(phone);
CREATE INDEX idx_customers_name ON public.customers(name);

-- ============================================
-- 3. EYEBROW DESIGNS (눈썹 디자인 라이브러리)
-- ============================================
CREATE TABLE public.eyebrow_designs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,

    name TEXT NOT NULL,
    description TEXT,
    category TEXT CHECK (category IN ('embossed', 'shading', 'combo', 'natural', 'other')),

    -- 이미지
    image_url TEXT NOT NULL,
    thumbnail_url TEXT,
    original_image_url TEXT,               -- 추출 전 원본

    -- AI 메타데이터
    style_embedding_url TEXT,              -- IP-Adapter 임베딩 저장 경로
    extraction_metadata JSONB,

    -- 공개/사용
    is_public BOOLEAN DEFAULT FALSE,
    is_favorite BOOLEAN DEFAULT FALSE,
    usage_count INT DEFAULT 0,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_designs_profile ON public.eyebrow_designs(profile_id);
CREATE INDEX idx_designs_category ON public.eyebrow_designs(category);
CREATE INDEX idx_designs_public ON public.eyebrow_designs(is_public) WHERE is_public = TRUE;

-- ============================================
-- 4. SIMULATIONS (시뮬레이션 기록)
-- ============================================
CREATE TABLE public.simulations (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    customer_id UUID REFERENCES public.customers(id) ON DELETE SET NULL,
    design_id UUID REFERENCES public.eyebrow_designs(id) ON DELETE SET NULL,

    -- 이미지
    original_image_url TEXT NOT NULL,
    result_image_url TEXT NOT NULL,

    -- 설정
    settings JSONB DEFAULT '{}',
    /*
    settings example:
    {
        "preserve_hair_strength": 0.7,
        "blend_mode": "multiply",
        "tone_correction": true,
        "denoise_strength": 0.75
    }
    */

    -- 분석 결과
    analysis_result JSONB,
    /*
    analysis_result example:
    {
        "skin_tone": {"type": "warm", "brightness": "21호"},
        "golden_ratio": {"is_symmetric": true}
    }
    */

    -- 상태
    status TEXT DEFAULT 'completed' CHECK (status IN ('processing', 'completed', 'failed')),
    processing_time_ms INT,
    error_message TEXT,

    -- 고객 피드백
    customer_rating INT CHECK (customer_rating BETWEEN 1 AND 5),
    customer_feedback TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_simulations_profile ON public.simulations(profile_id);
CREATE INDEX idx_simulations_customer ON public.simulations(customer_id);
CREATE INDEX idx_simulations_created ON public.simulations(created_at DESC);

-- 시뮬레이션 생성 시 카운트 증가 트리거
CREATE OR REPLACE FUNCTION increment_synthesis_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.profiles
    SET
        monthly_synthesis_count = monthly_synthesis_count + 1,
        updated_at = NOW()
    WHERE id = NEW.profile_id;

    -- 디자인 사용 카운트 증가
    IF NEW.design_id IS NOT NULL THEN
        UPDATE public.eyebrow_designs
        SET usage_count = usage_count + 1
        WHERE id = NEW.design_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_simulation_created
    AFTER INSERT ON public.simulations
    FOR EACH ROW
    EXECUTE FUNCTION increment_synthesis_count();

-- ============================================
-- 5. CONTRACTS (전자계약)
-- ============================================
CREATE TABLE public.contracts (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,
    simulation_id UUID REFERENCES public.simulations(id) ON DELETE SET NULL,

    -- 계약 정보
    contract_number TEXT UNIQUE,
    procedure_type TEXT,                   -- 엠보, 수지, 콤보 등
    procedure_date TIMESTAMPTZ,
    price DECIMAL(10, 2),
    deposit_amount DECIMAL(10, 2),

    -- 계약 내용
    terms_content TEXT,                    -- 약관 내용
    special_notes TEXT,                    -- 특이사항

    -- 서명
    customer_signature_url TEXT,
    staff_signature_url TEXT,
    signed_at TIMESTAMPTZ,

    -- PDF
    contract_pdf_url TEXT,

    -- 상태
    status TEXT DEFAULT 'draft' CHECK (status IN ('draft', 'pending', 'signed', 'completed', 'cancelled')),

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_contracts_profile ON public.contracts(profile_id);
CREATE INDEX idx_contracts_customer ON public.contracts(customer_id);
CREATE INDEX idx_contracts_status ON public.contracts(status);

-- 계약번호 자동 생성
CREATE OR REPLACE FUNCTION generate_contract_number()
RETURNS TRIGGER AS $$
BEGIN
    NEW.contract_number := 'CT-' || TO_CHAR(NOW(), 'YYYYMMDD') || '-' ||
                           LPAD(FLOOR(RANDOM() * 10000)::TEXT, 4, '0');
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER set_contract_number
    BEFORE INSERT ON public.contracts
    FOR EACH ROW
    WHEN (NEW.contract_number IS NULL)
    EXECUTE FUNCTION generate_contract_number();

-- ============================================
-- 6. BOOKINGS (예약)
-- ============================================
CREATE TABLE public.bookings (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES public.customers(id) ON DELETE CASCADE,

    -- 예약 정보
    scheduled_at TIMESTAMPTZ NOT NULL,
    duration_minutes INT DEFAULT 120,
    procedure_type TEXT,

    -- 예약금
    deposit_amount DECIMAL(10, 2),
    deposit_paid BOOLEAN DEFAULT FALSE,
    deposit_paid_at TIMESTAMPTZ,
    payment_id TEXT,                       -- PG 결제 ID
    payment_method TEXT,

    -- 알림
    reminder_sent BOOLEAN DEFAULT FALSE,
    reminder_sent_at TIMESTAMPTZ,

    -- 상태
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'no_show')),
    cancellation_reason TEXT,

    notes TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_bookings_profile ON public.bookings(profile_id);
CREATE INDEX idx_bookings_customer ON public.bookings(customer_id);
CREATE INDEX idx_bookings_scheduled ON public.bookings(scheduled_at);
CREATE INDEX idx_bookings_status ON public.bookings(status);

-- 예약 확정 시 고객 방문 카운트 업데이트
CREATE OR REPLACE FUNCTION update_customer_visit()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
        UPDATE public.customers
        SET
            visit_count = visit_count + 1,
            last_visit_at = NEW.scheduled_at,
            updated_at = NOW()
        WHERE id = NEW.customer_id;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER on_booking_completed
    AFTER UPDATE ON public.bookings
    FOR EACH ROW
    EXECUTE FUNCTION update_customer_visit();

-- ============================================
-- 7. SUBSCRIPTION EVENTS (구독 이벤트 로그)
-- ============================================
CREATE TABLE public.subscription_events (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

    event_type TEXT NOT NULL,              -- INITIAL_PURCHASE, RENEWAL, CANCELLATION 등
    product_id TEXT,

    -- RevenueCat 데이터
    revenuecat_event_id TEXT UNIQUE,
    raw_payload JSONB,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_subscription_events_profile ON public.subscription_events(profile_id);
CREATE INDEX idx_subscription_events_type ON public.subscription_events(event_type);

-- ============================================
-- 8. AUDIT LOG (감사 로그)
-- ============================================
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    profile_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,

    action TEXT NOT NULL,                  -- CREATE, UPDATE, DELETE
    table_name TEXT NOT NULL,
    record_id UUID,
    old_data JSONB,
    new_data JSONB,
    ip_address INET,
    user_agent TEXT,

    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_profile ON public.audit_logs(profile_id);
CREATE INDEX idx_audit_logs_created ON public.audit_logs(created_at DESC);

-- ============================================
-- ROW LEVEL SECURITY (RLS)
-- ============================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.customers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.eyebrow_designs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.simulations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.contracts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Profiles: 본인만 접근
CREATE POLICY "Users can view own profile"
    ON public.profiles FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "Users can update own profile"
    ON public.profiles FOR UPDATE
    USING (auth.uid() = id);

-- Customers: 해당 가맹점만 접근
CREATE POLICY "Users can manage own customers"
    ON public.customers FOR ALL
    USING (auth.uid() = profile_id);

-- Designs: 본인 것 + 공개된 것 조회, 본인 것만 수정/삭제
CREATE POLICY "Users can view own and public designs"
    ON public.eyebrow_designs FOR SELECT
    USING (auth.uid() = profile_id OR is_public = TRUE);

CREATE POLICY "Users can insert own designs"
    ON public.eyebrow_designs FOR INSERT
    WITH CHECK (auth.uid() = profile_id);

CREATE POLICY "Users can update own designs"
    ON public.eyebrow_designs FOR UPDATE
    USING (auth.uid() = profile_id);

CREATE POLICY "Users can delete own designs"
    ON public.eyebrow_designs FOR DELETE
    USING (auth.uid() = profile_id);

-- Simulations: 본인 것만
CREATE POLICY "Users can manage own simulations"
    ON public.simulations FOR ALL
    USING (auth.uid() = profile_id);

-- Contracts: 본인 것만
CREATE POLICY "Users can manage own contracts"
    ON public.contracts FOR ALL
    USING (auth.uid() = profile_id);

-- Bookings: 본인 것만
CREATE POLICY "Users can manage own bookings"
    ON public.bookings FOR ALL
    USING (auth.uid() = profile_id);

-- Subscription Events: 본인 것만 조회
CREATE POLICY "Users can view own subscription events"
    ON public.subscription_events FOR SELECT
    USING (auth.uid() = profile_id);

-- Audit Logs: 본인 것만 조회
CREATE POLICY "Users can view own audit logs"
    ON public.audit_logs FOR SELECT
    USING (auth.uid() = profile_id);

-- ============================================
-- FUNCTIONS
-- ============================================

-- 월간 사용량 리셋 함수
CREATE OR REPLACE FUNCTION reset_monthly_usage()
RETURNS void AS $$
BEGIN
    UPDATE public.profiles
    SET
        monthly_synthesis_count = 0,
        current_period_start = DATE_TRUNC('month', NOW()),
        updated_at = NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 구독 티어별 한도 조회 함수
CREATE OR REPLACE FUNCTION get_subscription_limit(tier TEXT)
RETURNS INT AS $$
BEGIN
    CASE tier
        WHEN 'free' THEN RETURN 10;
        WHEN 'basic' THEN RETURN 100;
        WHEN 'premium' THEN RETURN 999999;
        ELSE RETURN 10;
    END CASE;
END;
$$ LANGUAGE plpgsql;

-- 사용량 체크 함수
CREATE OR REPLACE FUNCTION check_usage_limit(user_id UUID)
RETURNS BOOLEAN AS $$
DECLARE
    current_count INT;
    limit_count INT;
BEGIN
    SELECT monthly_synthesis_count, monthly_synthesis_limit
    INTO current_count, limit_count
    FROM public.profiles
    WHERE id = user_id;

    RETURN current_count < limit_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

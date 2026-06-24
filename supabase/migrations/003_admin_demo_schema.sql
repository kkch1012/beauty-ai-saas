-- ============================================
-- Beauty AI SaaS - Admin 대시보드 전용 스키마 + 데모 시드
-- Migration: 003_admin_demo_schema
--
-- 목적: 무료 Supabase 인스턴스를 다른 프로젝트와 공유해도 충돌하지 않도록
--       이 프로젝트 전용 스키마(beauty_ai)에 admin 대시보드용 테이블을 둡니다.
--
-- 실행 방법 (Supabase 대시보드):
--   1) SQL Editor 에 이 파일 전체를 붙여넣고 RUN (재실행해도 안전 - drop & create)
--   2) Settings → API → "Exposed schemas" 에 `beauty_ai` 추가 후 저장  ← 필수!
--      (이 단계를 빼면 supabase-js 가 테이블을 못 봅니다)
-- ============================================

CREATE SCHEMA IF NOT EXISTS beauty_ai;

-- PostgREST(API) 가 스키마/테이블에 접근할 수 있도록 권한 부여
GRANT USAGE ON SCHEMA beauty_ai TO anon, authenticated;

-- --------------------------------------------
-- 1. 회원(가맹점)
-- --------------------------------------------
DROP TABLE IF EXISTS beauty_ai.members CASCADE;
CREATE TABLE beauty_ai.members (
    id            TEXT PRIMARY KEY,
    business_name TEXT NOT NULL,
    owner_name    TEXT,
    email         TEXT,
    phone         TEXT,
    tier          TEXT CHECK (tier IN ('free', 'basic', 'premium')),
    status        TEXT CHECK (status IN ('active', 'inactive', 'cancelled', 'expired')),
    monthly_usage INT DEFAULT 0,
    monthly_limit INT DEFAULT 10,
    joined_at     DATE
);

INSERT INTO beauty_ai.members
    (id, business_name, owner_name, email, phone, tier, status, monthly_usage, monthly_limit, joined_at)
VALUES
    ('M-1042', '라뷰티 안과거리점',  '김민지', 'labeauty.gn@gmail.com',     '010-2841-7720', 'premium', 'active',    152, 999999, '2025-06-24'),
    ('M-1038', '브로우랩 강남',      '이서연', 'browlab.gangnam@naver.com', '010-5512-3390', 'premium', 'active',     87, 999999, '2025-05-30'),
    ('M-1031', '프리티브로우 홍대',  '박지훈', 'pretty.hongdae@gmail.com',  '010-7781-2204', 'basic',   'active',     64,    100, '2025-05-12'),
    ('M-1027', '아이브로우살롱 일산','강수빈', 'eyebrow.ilsan@daum.net',    '010-3398-5561', 'premium', 'active',     73, 999999, '2025-04-28'),
    ('M-1019', '네이처브로우 인천',  '한지우', 'naturebrow.ic@gmail.com',   '010-9920-1148', 'basic',   'active',     58,    100, '2025-04-09'),
    ('M-1014', '뷰티풀데이 분당',    '정하늘', 'beautifulday.bd@naver.com', '010-4471-8830', 'basic',   'active',     41,    100, '2025-03-21'),
    ('M-1008', '글램브로우 수원',    '임도현', 'glambrow.sw@gmail.com',     '010-6612-0093', 'premium', 'cancelled',  34, 999999, '2025-03-02'),
    ('M-1005', '퍼펙트라인 대구',    '윤서아', 'perfectline.dg@daum.net',   '010-2230-7741', 'free',    'active',      5,     10, '2025-02-18'),
    ('M-1002', '샤인브로우 부산서면','최유나', 'shine.seomyeon@gmail.com',  '010-8845-3312', 'free',    'inactive',    8,     10, '2025-02-04'),
    ('M-1001', '디어브로우 제주',    '오세영', 'dearbrow.jeju@naver.com',   '010-1190-6657', 'free',    'active',      9,     10, '2025-01-15');

-- --------------------------------------------
-- 2. 결제 내역
-- --------------------------------------------
DROP TABLE IF EXISTS beauty_ai.payments CASCADE;
CREATE TABLE beauty_ai.payments (
    id            TEXT PRIMARY KEY,
    paid_at       DATE,
    business_name TEXT,
    product       TEXT,
    amount        INT,
    method        TEXT,
    status        TEXT CHECK (status IN ('paid', 'pending', 'failed', 'refunded'))
);

INSERT INTO beauty_ai.payments (id, paid_at, business_name, product, amount, method, status) VALUES
    ('PAY-20627', '2025-06-24', '라뷰티 안과거리점',  '프리미엄 월 구독',  99000, '신용카드',  'paid'),
    ('PAY-20618', '2025-06-23', '브로우랩 강남',      '프리미엄 월 구독',  99000, '신용카드',  'paid'),
    ('PAY-20611', '2025-06-22', '프리티브로우 홍대',  '베이직 월 구독',    49000, '계좌이체',  'paid'),
    ('PAY-20604', '2025-06-21', '아이브로우살롱 일산','프리미엄 월 구독',  99000, '신용카드',  'paid'),
    ('PAY-20598', '2025-06-20', '네이처브로우 인천',  '베이직 월 구독',    49000, '신용카드',  'paid'),
    ('PAY-20591', '2025-06-19', '뷰티풀데이 분당',    '베이직 월 구독',    49000, '카카오페이','pending'),
    ('PAY-20585', '2025-06-18', '글램브로우 수원',    '프리미엄 월 구독',  99000, '신용카드',  'refunded'),
    ('PAY-20579', '2025-06-17', '브로우랩 강남',      '추가 크레딧 100건', 30000, '신용카드',  'paid'),
    ('PAY-20572', '2025-06-16', '퍼펙트라인 대구',    '베이직 월 구독',    49000, '신용카드',  'failed'),
    ('PAY-20566', '2025-06-15', '라뷰티 안과거리점',  '추가 크레딧 100건', 30000, '카카오페이','paid');

-- --------------------------------------------
-- 3. 눈썹 디자인 라이브러리
-- --------------------------------------------
DROP TABLE IF EXISTS beauty_ai.designs CASCADE;
CREATE TABLE beauty_ai.designs (
    id          TEXT PRIMARY KEY,
    name        TEXT NOT NULL,
    category    TEXT CHECK (category IN ('embossed', 'shading', 'combo', 'natural')),
    usage_count INT DEFAULT 0,
    is_public   BOOLEAN DEFAULT FALSE,
    is_favorite BOOLEAN DEFAULT FALSE,
    gradient    TEXT
);

INSERT INTO beauty_ai.designs (id, name, category, usage_count, is_public, is_favorite, gradient) VALUES
    ('D-301', '코리안 스트레이트',   'natural',  188, TRUE,  TRUE,  'from-rose-300 to-rose-500'),
    ('D-298', '클래식 엠보',         'embossed', 203, FALSE, TRUE,  'from-amber-300 to-orange-500'),
    ('D-292', '내추럴 아치 브로우',  'natural',  142, TRUE,  FALSE, 'from-violet-300 to-purple-500'),
    ('D-287', '페더 브로우',         'embossed', 121, FALSE, TRUE,  'from-emerald-300 to-teal-500'),
    ('D-281', '슬릭 스트레이트',     'combo',     98, FALSE, FALSE, 'from-sky-300 to-blue-500'),
    ('D-276', '소프트 그라데이션',   'shading',   76, FALSE, FALSE, 'from-pink-300 to-fuchsia-500'),
    ('D-270', '글래머 아치',         'combo',     67, TRUE,  FALSE, 'from-indigo-300 to-indigo-500'),
    ('D-264', '트렌디 일자눈썹',     'natural',   54, FALSE, FALSE, 'from-cyan-300 to-teal-500'),
    ('D-258', '내추럴 풀 쉐딩',      'shading',   45, FALSE, FALSE, 'from-stone-300 to-stone-500');

-- --------------------------------------------
-- 4. 대시보드 요약 지표 (단일 행)
-- --------------------------------------------
DROP TABLE IF EXISTS beauty_ai.metrics CASCADE;
CREATE TABLE beauty_ai.metrics (
    id                          INT PRIMARY KEY DEFAULT 1,
    total_members               INT,
    active_subscriptions        INT,
    monthly_simulations         INT,
    monthly_revenue             INT,
    trend_total_members         REAL,
    trend_active_subscriptions  REAL,
    trend_monthly_simulations   REAL,
    trend_monthly_revenue       REAL
);

INSERT INTO beauty_ai.metrics
    (id, total_members, active_subscriptions, monthly_simulations, monthly_revenue,
     trend_total_members, trend_active_subscriptions, trend_monthly_simulations, trend_monthly_revenue)
VALUES (1, 142, 89, 1247, 6461000, 12.4, 8.1, 23.6, 15.2);

-- --------------------------------------------
-- 5. 월별 시뮬레이션 추이
-- --------------------------------------------
DROP TABLE IF EXISTS beauty_ai.monthly_simulations CASCADE;
CREATE TABLE beauty_ai.monthly_simulations (
    sort_order INT PRIMARY KEY,
    month      TEXT,
    count      INT
);

INSERT INTO beauty_ai.monthly_simulations (sort_order, month, count) VALUES
    (1, '12월', 612), (2, '1월', 734), (3, '2월', 698), (4, '3월', 845),
    (5, '4월', 976), (6, '5월', 1009), (7, '6월', 1247);

-- --------------------------------------------
-- 6. 구독 등급 분포
-- --------------------------------------------
DROP TABLE IF EXISTS beauty_ai.subscription_breakdown CASCADE;
CREATE TABLE beauty_ai.subscription_breakdown (
    sort_order INT PRIMARY KEY,
    tier       TEXT,
    count      INT,
    color      TEXT
);

INSERT INTO beauty_ai.subscription_breakdown (sort_order, tier, count, color) VALUES
    (1, '프리미엄', 34, '#7c3aed'),
    (2, '베이직',   55, '#a78bfa'),
    (3, '무료',     53, '#e5e7eb');

-- --------------------------------------------
-- 7. 최근 활동
-- --------------------------------------------
DROP TABLE IF EXISTS beauty_ai.recent_activity CASCADE;
CREATE TABLE beauty_ai.recent_activity (
    sort_order INT PRIMARY KEY,
    id         INT,
    type       TEXT,
    text       TEXT,
    time_label TEXT
);

INSERT INTO beauty_ai.recent_activity (sort_order, id, type, text, time_label) VALUES
    (1, 1, 'signup',     '라뷰티 안과거리점이 신규 가입했습니다.',                          '5분 전'),
    (2, 2, 'payment',    '브로우랩 강남이 프리미엄 구독을 결제했습니다.',                    '32분 전'),
    (3, 3, 'simulation', '프리티브로우 홍대에서 시뮬레이션 12건이 생성되었습니다.',          '1시간 전'),
    (4, 4, 'upgrade',    '아이브로우살롱 일산이 베이직 → 프리미엄으로 업그레이드했습니다.',  '3시간 전'),
    (5, 5, 'payment',    '네이처브로우 인천이 베이직 구독을 갱신했습니다.',                  '5시간 전'),
    (6, 6, 'signup',     '디어브로우 제주가 신규 가입했습니다.',                            '어제');

-- --------------------------------------------
-- RLS: 데모용 읽기 전용 공개 정책 + 권한
-- (실서비스에서는 auth.uid() 기반으로 좁혀야 함 - 001_initial_schema.sql 참고)
-- --------------------------------------------
DO $$
DECLARE t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY[
        'members', 'payments', 'designs', 'metrics',
        'monthly_simulations', 'subscription_breakdown', 'recent_activity'
    ] LOOP
        EXECUTE format('ALTER TABLE beauty_ai.%I ENABLE ROW LEVEL SECURITY;', t);
        EXECUTE format('DROP POLICY IF EXISTS "demo read" ON beauty_ai.%I;', t);
        EXECUTE format('CREATE POLICY "demo read" ON beauty_ai.%I FOR SELECT USING (true);', t);
    END LOOP;
END $$;

GRANT SELECT ON ALL TABLES IN SCHEMA beauty_ai TO anon, authenticated;
ALTER DEFAULT PRIVILEGES IN SCHEMA beauty_ai GRANT SELECT ON TABLES TO anon, authenticated;

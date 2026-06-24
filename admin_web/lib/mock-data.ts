// ============================================
// 목업 데이터 (데모용 하드코딩)
// 실제 Supabase 연동 전, 화면을 그럴듯하게 보여주기 위한 샘플 데이터입니다.
// ============================================

export type SubscriptionTier = 'free' | 'basic' | 'premium'
export type SubscriptionStatus = 'active' | 'inactive' | 'cancelled' | 'expired'

// --- 대시보드 요약 통계 ---
export const dashboardStats = {
  totalMembers: 142,
  activeSubscriptions: 89,
  monthlySimulations: 1247,
  monthlyRevenue: 6_461_000,
  // 전월 대비 증감(%) — 그럴듯한 추세 표시용
  trends: {
    totalMembers: 12.4,
    activeSubscriptions: 8.1,
    monthlySimulations: 23.6,
    monthlyRevenue: 15.2,
  },
}

// --- 월별 시뮬레이션 추이 (최근 7개월) ---
export const monthlySimulationTrend = [
  { month: '12월', count: 612 },
  { month: '1월', count: 734 },
  { month: '2월', count: 698 },
  { month: '3월', count: 845 },
  { month: '4월', count: 976 },
  { month: '5월', count: 1009 },
  { month: '6월', count: 1247 },
]

// --- 구독 등급 분포 ---
export const subscriptionBreakdown = [
  { tier: '프리미엄', count: 34, color: '#7c3aed' },
  { tier: '베이직', count: 55, color: '#a78bfa' },
  { tier: '무료', count: 53, color: '#e5e7eb' },
]

// --- 최근 활동 ---
export const recentActivity = [
  { id: 1, type: 'signup', text: '라뷰티 안과거리점이 신규 가입했습니다.', time: '5분 전' },
  { id: 2, type: 'payment', text: '브로우랩 강남이 프리미엄 구독을 결제했습니다.', time: '32분 전' },
  { id: 3, type: 'simulation', text: '프리티브로우 홍대에서 시뮬레이션 12건이 생성되었습니다.', time: '1시간 전' },
  { id: 4, type: 'upgrade', text: '아이브로우살롱 일산이 베이직 → 프리미엄으로 업그레이드했습니다.', time: '3시간 전' },
  { id: 5, type: 'payment', text: '네이처브로우 인천이 베이직 구독을 갱신했습니다.', time: '5시간 전' },
  { id: 6, type: 'signup', text: '디어브로우 제주가 신규 가입했습니다.', time: '어제' },
]

// --- 회원(가맹점) 목록 ---
export interface Member {
  id: string
  businessName: string
  ownerName: string
  email: string
  phone: string
  tier: SubscriptionTier
  status: SubscriptionStatus
  monthlyUsage: number
  monthlyLimit: number
  joinedAt: string
}

export const members: Member[] = [
  { id: 'M-1042', businessName: '라뷰티 안과거리점', ownerName: '김민지', email: 'labeauty.gn@gmail.com', phone: '010-2841-7720', tier: 'premium', status: 'active', monthlyUsage: 152, monthlyLimit: 999999, joinedAt: '2025-06-24' },
  { id: 'M-1038', businessName: '브로우랩 강남', ownerName: '이서연', email: 'browlab.gangnam@naver.com', phone: '010-5512-3390', tier: 'premium', status: 'active', monthlyUsage: 87, monthlyLimit: 999999, joinedAt: '2025-05-30' },
  { id: 'M-1031', businessName: '프리티브로우 홍대', ownerName: '박지훈', email: 'pretty.hongdae@gmail.com', phone: '010-7781-2204', tier: 'basic', status: 'active', monthlyUsage: 64, monthlyLimit: 100, joinedAt: '2025-05-12' },
  { id: 'M-1027', businessName: '아이브로우살롱 일산', ownerName: '강수빈', email: 'eyebrow.ilsan@daum.net', phone: '010-3398-5561', tier: 'premium', status: 'active', monthlyUsage: 73, monthlyLimit: 999999, joinedAt: '2025-04-28' },
  { id: 'M-1019', businessName: '네이처브로우 인천', ownerName: '한지우', email: 'naturebrow.ic@gmail.com', phone: '010-9920-1148', tier: 'basic', status: 'active', monthlyUsage: 58, monthlyLimit: 100, joinedAt: '2025-04-09' },
  { id: 'M-1014', businessName: '뷰티풀데이 분당', ownerName: '정하늘', email: 'beautifulday.bd@naver.com', phone: '010-4471-8830', tier: 'basic', status: 'active', monthlyUsage: 41, monthlyLimit: 100, joinedAt: '2025-03-21' },
  { id: 'M-1008', businessName: '글램브로우 수원', ownerName: '임도현', email: 'glambrow.sw@gmail.com', phone: '010-6612-0093', tier: 'premium', status: 'cancelled', monthlyUsage: 34, monthlyLimit: 999999, joinedAt: '2025-03-02' },
  { id: 'M-1005', businessName: '퍼펙트라인 대구', ownerName: '윤서아', email: 'perfectline.dg@daum.net', phone: '010-2230-7741', tier: 'free', status: 'active', monthlyUsage: 5, monthlyLimit: 10, joinedAt: '2025-02-18' },
  { id: 'M-1002', businessName: '샤인브로우 부산서면', ownerName: '최유나', email: 'shine.seomyeon@gmail.com', phone: '010-8845-3312', tier: 'free', status: 'inactive', monthlyUsage: 8, monthlyLimit: 10, joinedAt: '2025-02-04' },
  { id: 'M-1001', businessName: '디어브로우 제주', ownerName: '오세영', email: 'dearbrow.jeju@naver.com', phone: '010-1190-6657', tier: 'free', status: 'active', monthlyUsage: 9, monthlyLimit: 10, joinedAt: '2025-01-15' },
]

// --- 결제 내역 ---
export type PaymentStatus = 'paid' | 'pending' | 'failed' | 'refunded'

export interface Payment {
  id: string
  date: string
  businessName: string
  product: string
  amount: number
  method: string
  status: PaymentStatus
}

export const payments: Payment[] = [
  { id: 'PAY-20627', date: '2025-06-24', businessName: '라뷰티 안과거리점', product: '프리미엄 월 구독', amount: 99000, method: '신용카드', status: 'paid' },
  { id: 'PAY-20618', date: '2025-06-23', businessName: '브로우랩 강남', product: '프리미엄 월 구독', amount: 99000, method: '신용카드', status: 'paid' },
  { id: 'PAY-20611', date: '2025-06-22', businessName: '프리티브로우 홍대', product: '베이직 월 구독', amount: 49000, method: '계좌이체', status: 'paid' },
  { id: 'PAY-20604', date: '2025-06-21', businessName: '아이브로우살롱 일산', product: '프리미엄 월 구독', amount: 99000, method: '신용카드', status: 'paid' },
  { id: 'PAY-20598', date: '2025-06-20', businessName: '네이처브로우 인천', product: '베이직 월 구독', amount: 49000, method: '신용카드', status: 'paid' },
  { id: 'PAY-20591', date: '2025-06-19', businessName: '뷰티풀데이 분당', product: '베이직 월 구독', amount: 49000, method: '카카오페이', status: 'pending' },
  { id: 'PAY-20585', date: '2025-06-18', businessName: '글램브로우 수원', product: '프리미엄 월 구독', amount: 99000, method: '신용카드', status: 'refunded' },
  { id: 'PAY-20579', date: '2025-06-17', businessName: '브로우랩 강남', product: '추가 크레딧 100건', amount: 30000, method: '신용카드', status: 'paid' },
  { id: 'PAY-20572', date: '2025-06-16', businessName: '퍼펙트라인 대구', product: '베이직 월 구독', amount: 49000, method: '신용카드', status: 'failed' },
  { id: 'PAY-20566', date: '2025-06-15', businessName: '라뷰티 안과거리점', product: '추가 크레딧 100건', amount: 30000, method: '카카오페이', status: 'paid' },
]

// --- 눈썹 디자인 라이브러리 ---
export type DesignCategory = 'embossed' | 'shading' | 'combo' | 'natural'

export interface Design {
  id: string
  name: string
  category: DesignCategory
  usageCount: number
  isPublic: boolean
  isFavorite: boolean
  gradient: string // 썸네일 대체용 그라데이션
}

export const designCategoryLabel: Record<DesignCategory, string> = {
  embossed: '엠보',
  shading: '쉐딩',
  combo: '콤보',
  natural: '내추럴',
}

export const designs: Design[] = [
  { id: 'D-301', name: '코리안 스트레이트', category: 'natural', usageCount: 188, isPublic: true, isFavorite: true, gradient: 'from-rose-300 to-rose-500' },
  { id: 'D-298', name: '클래식 엠보', category: 'embossed', usageCount: 203, isPublic: false, isFavorite: true, gradient: 'from-amber-300 to-orange-500' },
  { id: 'D-292', name: '내추럴 아치 브로우', category: 'natural', usageCount: 142, isPublic: true, isFavorite: false, gradient: 'from-violet-300 to-purple-500' },
  { id: 'D-287', name: '페더 브로우', category: 'embossed', usageCount: 121, isPublic: false, isFavorite: true, gradient: 'from-emerald-300 to-teal-500' },
  { id: 'D-281', name: '슬릭 스트레이트', category: 'combo', usageCount: 98, isPublic: false, isFavorite: false, gradient: 'from-sky-300 to-blue-500' },
  { id: 'D-276', name: '소프트 그라데이션', category: 'shading', usageCount: 76, isPublic: false, isFavorite: false, gradient: 'from-pink-300 to-fuchsia-500' },
  { id: 'D-270', name: '글래머 아치', category: 'combo', usageCount: 67, isPublic: true, isFavorite: false, gradient: 'from-indigo-300 to-indigo-500' },
  { id: 'D-264', name: '트렌디 일자눈썹', category: 'natural', usageCount: 54, isPublic: false, isFavorite: false, gradient: 'from-cyan-300 to-teal-500' },
  { id: 'D-258', name: '내추럴 풀 쉐딩', category: 'shading', usageCount: 45, isPublic: false, isFavorite: false, gradient: 'from-stone-300 to-stone-500' },
]

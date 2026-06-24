// ============================================
// 데이터 액세스 레이어
//
// Supabase 환경변수가 "실제 값"으로 설정돼 있으면 전용 스키마(beauty_ai)에서 조회하고,
// 아니면(플레이스홀더/미설정) 목업 데이터로 자동 폴백합니다.
// → 키 없이도 데모가 동작하고, 키만 넣으면 실제 DB 대시보드가 됩니다.
// ============================================

import { createServerClient } from './supabase/server'
import * as mock from './mock-data'
import type { Member, Payment, Design } from './mock-data'

export function isSupabaseConfigured(): boolean {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL
  const key = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  return (
    !!url &&
    !!key &&
    !url.includes('placeholder') &&
    !key.includes('placeholder') &&
    url.startsWith('http')
  )
}

// 현재 화면 데이터가 실제 DB에서 왔는지 여부 (UI 배지 표시에 사용)
export const dataSource: 'supabase' | 'mock' = isSupabaseConfigured() ? 'supabase' : 'mock'

export async function getMembers(): Promise<Member[]> {
  if (!isSupabaseConfigured()) return mock.members
  try {
    const sb = createServerClient()
    const { data, error } = await sb.from('members').select('*').order('joined_at', { ascending: false })
    if (error || !data?.length) return mock.members
    return data.map(
      (r): Member => ({
        id: r.id,
        businessName: r.business_name,
        ownerName: r.owner_name,
        email: r.email,
        phone: r.phone,
        tier: r.tier,
        status: r.status,
        monthlyUsage: r.monthly_usage,
        monthlyLimit: r.monthly_limit,
        joinedAt: r.joined_at,
      })
    )
  } catch {
    return mock.members
  }
}

export async function getPayments(): Promise<Payment[]> {
  if (!isSupabaseConfigured()) return mock.payments
  try {
    const sb = createServerClient()
    const { data, error } = await sb.from('payments').select('*').order('paid_at', { ascending: false })
    if (error || !data?.length) return mock.payments
    return data.map(
      (r): Payment => ({
        id: r.id,
        date: r.paid_at,
        businessName: r.business_name,
        product: r.product,
        amount: r.amount,
        method: r.method,
        status: r.status,
      })
    )
  } catch {
    return mock.payments
  }
}

export async function getDesigns(): Promise<Design[]> {
  if (!isSupabaseConfigured()) return mock.designs
  try {
    const sb = createServerClient()
    const { data, error } = await sb.from('designs').select('*').order('usage_count', { ascending: false })
    if (error || !data?.length) return mock.designs
    return data.map(
      (r): Design => ({
        id: r.id,
        name: r.name,
        category: r.category,
        usageCount: r.usage_count,
        isPublic: r.is_public,
        isFavorite: r.is_favorite,
        gradient: r.gradient,
      })
    )
  } catch {
    return mock.designs
  }
}

export interface DashboardData {
  stats: typeof mock.dashboardStats
  trend: typeof mock.monthlySimulationTrend
  breakdown: typeof mock.subscriptionBreakdown
  activity: typeof mock.recentActivity
}

export async function getDashboardData(): Promise<DashboardData> {
  const fallback: DashboardData = {
    stats: mock.dashboardStats,
    trend: mock.monthlySimulationTrend,
    breakdown: mock.subscriptionBreakdown,
    activity: mock.recentActivity,
  }
  if (!isSupabaseConfigured()) return fallback
  try {
    const sb = createServerClient()
    const [m, ms, sbk, ra] = await Promise.all([
      sb.from('metrics').select('*').eq('id', 1).single(),
      sb.from('monthly_simulations').select('*').order('sort_order'),
      sb.from('subscription_breakdown').select('*').order('sort_order'),
      sb.from('recent_activity').select('*').order('sort_order'),
    ])
    if (m.error || !m.data) return fallback
    return {
      stats: {
        totalMembers: m.data.total_members,
        activeSubscriptions: m.data.active_subscriptions,
        monthlySimulations: m.data.monthly_simulations,
        monthlyRevenue: m.data.monthly_revenue,
        trends: {
          totalMembers: m.data.trend_total_members,
          activeSubscriptions: m.data.trend_active_subscriptions,
          monthlySimulations: m.data.trend_monthly_simulations,
          monthlyRevenue: m.data.trend_monthly_revenue,
        },
      },
      trend: (ms.data ?? fallback.trend).map((r) => ({ month: r.month, count: r.count })),
      breakdown: (sbk.data ?? fallback.breakdown).map((r) => ({ tier: r.tier, count: r.count, color: r.color })),
      activity: (ra.data ?? fallback.activity).map((r) => ({ id: r.id, type: r.type, text: r.text, time: r.time_label })),
    }
  } catch {
    return fallback
  }
}

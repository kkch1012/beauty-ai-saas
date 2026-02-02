'use client'

import { useEffect, useState } from 'react'
import { Users, CreditCard, Image, TrendingUp } from 'lucide-react'
import { createClient } from '@/lib/supabase/client'

interface Stats {
  totalMembers: number
  activeSubscriptions: number
  totalSimulations: number
  monthlyRevenue: number
}

export default function DashboardPage() {
  const [stats, setStats] = useState<Stats>({
    totalMembers: 0,
    activeSubscriptions: 0,
    totalSimulations: 0,
    monthlyRevenue: 0,
  })
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    fetchStats()
  }, [])

  async function fetchStats() {
    const supabase = createClient()

    try {
      // Total members
      const { count: membersCount } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true })

      // Active subscriptions
      const { count: activeCount } = await supabase
        .from('profiles')
        .select('*', { count: 'exact', head: true })
        .eq('subscription_status', 'active')
        .neq('subscription_tier', 'free')

      // Total simulations this month
      const startOfMonth = new Date()
      startOfMonth.setDate(1)
      startOfMonth.setHours(0, 0, 0, 0)

      const { count: simulationsCount } = await supabase
        .from('simulations')
        .select('*', { count: 'exact', head: true })
        .gte('created_at', startOfMonth.toISOString())

      setStats({
        totalMembers: membersCount || 0,
        activeSubscriptions: activeCount || 0,
        totalSimulations: simulationsCount || 0,
        monthlyRevenue: (activeCount || 0) * 29000, // Simplified calculation
      })
    } catch (error) {
      console.error('Failed to fetch stats:', error)
    } finally {
      setLoading(false)
    }
  }

  const statCards = [
    {
      title: '전체 회원',
      value: stats.totalMembers,
      icon: Users,
      color: 'bg-blue-500',
    },
    {
      title: '유료 구독자',
      value: stats.activeSubscriptions,
      icon: CreditCard,
      color: 'bg-green-500',
    },
    {
      title: '이번 달 시뮬레이션',
      value: stats.totalSimulations,
      icon: Image,
      color: 'bg-purple-500',
    },
    {
      title: '예상 월 수익',
      value: `₩${stats.monthlyRevenue.toLocaleString()}`,
      icon: TrendingUp,
      color: 'bg-orange-500',
    },
  ]

  return (
    <div className="p-8">
      <h1 className="text-2xl font-bold mb-8">대시보드</h1>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((card) => (
          <div
            key={card.title}
            className="bg-white rounded-xl p-6 shadow-sm border border-gray-100"
          >
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{card.title}</p>
                <p className="text-2xl font-bold mt-1">
                  {loading ? '...' : card.value}
                </p>
              </div>
              <div className={`${card.color} p-3 rounded-lg`}>
                <card.icon className="w-6 h-6 text-white" />
              </div>
            </div>
          </div>
        ))}
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
        <h2 className="text-lg font-semibold mb-4">최근 활동</h2>
        <p className="text-gray-500">최근 활동 내역이 여기에 표시됩니다.</p>
      </div>
    </div>
  )
}

'use client'

import { Users, CreditCard, Image as ImageIcon, TrendingUp, ArrowUpRight, UserPlus, RefreshCw, Sparkles } from 'lucide-react'
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts'
import type { DashboardData } from '@/lib/data'

const activityIcon: Record<string, typeof UserPlus> = {
  signup: UserPlus,
  payment: CreditCard,
  simulation: Sparkles,
  upgrade: TrendingUp,
}

export default function DashboardClient({ stats, trend, breakdown, activity }: DashboardData) {
  const { totalMembers, activeSubscriptions, monthlySimulations, monthlyRevenue, trends } = stats

  const statCards = [
    { title: '전체 회원', value: totalMembers.toLocaleString(), trend: trends.totalMembers, icon: Users, color: 'bg-blue-500' },
    { title: '유료 구독자', value: activeSubscriptions.toLocaleString(), trend: trends.activeSubscriptions, icon: CreditCard, color: 'bg-green-500' },
    { title: '이번 달 시뮬레이션', value: monthlySimulations.toLocaleString(), trend: trends.monthlySimulations, icon: ImageIcon, color: 'bg-purple-500' },
    { title: '예상 월 수익', value: `₩${monthlyRevenue.toLocaleString()}`, trend: trends.monthlyRevenue, icon: TrendingUp, color: 'bg-orange-500' },
  ]

  const totalSub = breakdown.reduce((s, b) => s + b.count, 0)

  return (
    <>
      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6 mb-8">
        {statCards.map((card) => (
          <div key={card.title} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <div className="flex items-center justify-between">
              <div>
                <p className="text-sm text-gray-500">{card.title}</p>
                <p className="text-2xl font-bold mt-1 text-gray-900">{card.value}</p>
              </div>
              <div className={`${card.color} p-3 rounded-lg`}>
                <card.icon className="w-6 h-6 text-white" />
              </div>
            </div>
            <div className="flex items-center mt-4 text-sm">
              <span className="flex items-center text-green-600 font-medium">
                <ArrowUpRight className="w-4 h-4" />
                {card.trend}%
              </span>
              <span className="text-gray-400 ml-2">전월 대비</span>
            </div>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6 mb-8">
        {/* Bar Chart */}
        <div className="lg:col-span-2 bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h2 className="text-lg font-semibold mb-1 text-gray-900">월별 시뮬레이션 추이</h2>
          <p className="text-sm text-gray-500 mb-6">최근 7개월</p>
          <div className="h-72">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={trend} margin={{ top: 8, right: 8, left: -16, bottom: 0 }}>
                <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f0f0f0" />
                <XAxis dataKey="month" tickLine={false} axisLine={false} tick={{ fontSize: 12, fill: '#9ca3af' }} />
                <YAxis tickLine={false} axisLine={false} tick={{ fontSize: 12, fill: '#9ca3af' }} />
                <Tooltip
                  cursor={{ fill: '#f5f3ff' }}
                  contentStyle={{ borderRadius: 12, border: '1px solid #eee', fontSize: 13 }}
                  formatter={(v: number) => [`${v.toLocaleString()}건`, '시뮬레이션']}
                />
                <Bar dataKey="count" fill="#8b5cf6" radius={[6, 6, 0, 0]} maxBarSize={44} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>

        {/* Subscription Breakdown */}
        <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
          <h2 className="text-lg font-semibold mb-1 text-gray-900">구독 등급 분포</h2>
          <p className="text-sm text-gray-500 mb-6">전체 {totalSub}개 가맹점</p>
          <div className="space-y-5">
            {breakdown.map((item) => {
              const pct = Math.round((item.count / totalSub) * 100)
              return (
                <div key={item.tier}>
                  <div className="flex justify-between text-sm mb-1.5">
                    <span className="font-medium text-gray-700">{item.tier}</span>
                    <span className="text-gray-500">{item.count}개 · {pct}%</span>
                  </div>
                  <div className="h-2.5 w-full rounded-full bg-gray-100">
                    <div className="h-2.5 rounded-full" style={{ width: `${pct}%`, backgroundColor: item.color }} />
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      </div>

      {/* Recent Activity */}
      <div className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
        <h2 className="text-lg font-semibold mb-4 text-gray-900">최근 활동</h2>
        <ul className="divide-y divide-gray-100">
          {activity.map((a) => {
            const Icon = activityIcon[a.type] ?? RefreshCw
            return (
              <li key={a.id} className="flex items-center py-3">
                <div className="w-9 h-9 rounded-full bg-purple-50 flex items-center justify-center mr-3 shrink-0">
                  <Icon className="w-4 h-4 text-purple-600" />
                </div>
                <p className="text-sm text-gray-700 flex-1">{a.text}</p>
                <span className="text-xs text-gray-400 ml-4 shrink-0">{a.time}</span>
              </li>
            )
          })}
        </ul>
      </div>
    </>
  )
}

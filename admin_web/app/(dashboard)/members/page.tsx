'use client'

import { Search, Filter, Download } from 'lucide-react'
import { members, type SubscriptionTier, type SubscriptionStatus } from '@/lib/mock-data'

const tierStyle: Record<SubscriptionTier, string> = {
  premium: 'bg-purple-100 text-purple-700',
  basic: 'bg-blue-100 text-blue-700',
  free: 'bg-gray-100 text-gray-600',
}
const tierLabel: Record<SubscriptionTier, string> = {
  premium: '프리미엄',
  basic: '베이직',
  free: '무료',
}

const statusStyle: Record<SubscriptionStatus, string> = {
  active: 'bg-green-100 text-green-700',
  inactive: 'bg-gray-100 text-gray-500',
  cancelled: 'bg-red-100 text-red-600',
  expired: 'bg-amber-100 text-amber-700',
}
const statusLabel: Record<SubscriptionStatus, string> = {
  active: '활성',
  inactive: '비활성',
  cancelled: '해지',
  expired: '만료',
}

export default function MembersPage() {
  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">회원 관리</h1>
          <p className="text-sm text-gray-500 mt-1">전체 {members.length}개 가맹점</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-600 bg-white border border-gray-200 rounded-lg hover:bg-gray-50">
          <Download className="w-4 h-4" />
          내보내기
        </button>
      </div>

      {/* Toolbar */}
      <div className="flex items-center gap-3 mb-4">
        <div className="relative flex-1 max-w-sm">
          <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="샵 이름, 원장님, 이메일 검색"
            className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-200"
          />
        </div>
        <button className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-600 bg-white border border-gray-200 rounded-lg hover:bg-gray-50">
          <Filter className="w-4 h-4" />
          필터
        </button>
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 text-left text-gray-500">
              <th className="px-6 py-3 font-medium">가맹점</th>
              <th className="px-6 py-3 font-medium">연락처</th>
              <th className="px-6 py-3 font-medium">구독</th>
              <th className="px-6 py-3 font-medium">상태</th>
              <th className="px-6 py-3 font-medium">이번 달 사용량</th>
              <th className="px-6 py-3 font-medium">가입일</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {members.map((m) => {
              const pct = Math.min(100, Math.round((m.monthlyUsage / m.monthlyLimit) * 100))
              const limitText = m.monthlyLimit >= 999999 ? '무제한' : m.monthlyLimit.toLocaleString()
              return (
                <tr key={m.id} className="hover:bg-gray-50">
                  <td className="px-6 py-4">
                    <div className="font-medium text-gray-900">{m.businessName}</div>
                    <div className="text-xs text-gray-500">{m.ownerName} 원장 · {m.id}</div>
                  </td>
                  <td className="px-6 py-4 text-gray-600">
                    <div>{m.phone}</div>
                    <div className="text-xs text-gray-400">{m.email}</div>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${tierStyle[m.tier]}`}>
                      {tierLabel[m.tier]}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${statusStyle[m.status]}`}>
                      {statusLabel[m.status]}
                    </span>
                  </td>
                  <td className="px-6 py-4">
                    <div className="flex items-center gap-2">
                      <div className="h-1.5 w-24 rounded-full bg-gray-100">
                        <div
                          className={`h-1.5 rounded-full ${pct >= 90 ? 'bg-red-400' : 'bg-purple-500'}`}
                          style={{ width: `${pct}%` }}
                        />
                      </div>
                      <span className="text-xs text-gray-500 whitespace-nowrap">
                        {m.monthlyUsage.toLocaleString()} / {limitText}
                      </span>
                    </div>
                  </td>
                  <td className="px-6 py-4 text-gray-500">{m.joinedAt}</td>
                </tr>
              )
            })}
          </tbody>
        </table>
      </div>
    </div>
  )
}

'use client'

import { Search, Download, Wallet, TrendingUp, RotateCcw } from 'lucide-react'
import { payments, type PaymentStatus } from '@/lib/mock-data'

const statusStyle: Record<PaymentStatus, string> = {
  paid: 'bg-green-100 text-green-700',
  pending: 'bg-amber-100 text-amber-700',
  failed: 'bg-red-100 text-red-600',
  refunded: 'bg-gray-100 text-gray-500',
}
const statusLabel: Record<PaymentStatus, string> = {
  paid: '완료',
  pending: '대기',
  failed: '실패',
  refunded: '환불',
}

export default function PaymentsPage() {
  const paidTotal = payments.filter((p) => p.status === 'paid').reduce((s, p) => s + p.amount, 0)
  const refundedTotal = payments.filter((p) => p.status === 'refunded').reduce((s, p) => s + p.amount, 0)
  const paidCount = payments.filter((p) => p.status === 'paid').length

  const summary = [
    { title: '이번 달 매출', value: `₩${paidTotal.toLocaleString()}`, icon: Wallet, color: 'bg-green-500' },
    { title: '결제 완료 건수', value: `${paidCount}건`, icon: TrendingUp, color: 'bg-blue-500' },
    { title: '환불 금액', value: `₩${refundedTotal.toLocaleString()}`, icon: RotateCcw, color: 'bg-gray-500' },
  ]

  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">결제 내역</h1>
          <p className="text-sm text-gray-500 mt-1">2025년 6월 구독 및 결제 현황</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-gray-600 bg-white border border-gray-200 rounded-lg hover:bg-gray-50">
          <Download className="w-4 h-4" />
          정산 내보내기
        </button>
      </div>

      {/* Summary */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 mb-8">
        {summary.map((s) => (
          <div key={s.title} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100 flex items-center justify-between">
            <div>
              <p className="text-sm text-gray-500">{s.title}</p>
              <p className="text-2xl font-bold mt-1 text-gray-900">{s.value}</p>
            </div>
            <div className={`${s.color} p-3 rounded-lg`}>
              <s.icon className="w-6 h-6 text-white" />
            </div>
          </div>
        ))}
      </div>

      {/* Toolbar */}
      <div className="relative max-w-sm mb-4">
        <Search className="w-4 h-4 text-gray-400 absolute left-3 top-1/2 -translate-y-1/2" />
        <input
          type="text"
          placeholder="결제 ID, 가맹점 검색"
          className="w-full pl-9 pr-4 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-200"
        />
      </div>

      {/* Table */}
      <div className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden">
        <table className="w-full text-sm">
          <thead>
            <tr className="bg-gray-50 text-left text-gray-500">
              <th className="px-6 py-3 font-medium">결제 ID</th>
              <th className="px-6 py-3 font-medium">결제일</th>
              <th className="px-6 py-3 font-medium">가맹점</th>
              <th className="px-6 py-3 font-medium">상품</th>
              <th className="px-6 py-3 font-medium">결제수단</th>
              <th className="px-6 py-3 font-medium text-right">금액</th>
              <th className="px-6 py-3 font-medium">상태</th>
            </tr>
          </thead>
          <tbody className="divide-y divide-gray-100">
            {payments.map((p) => (
              <tr key={p.id} className="hover:bg-gray-50">
                <td className="px-6 py-4 font-mono text-xs text-gray-500">{p.id}</td>
                <td className="px-6 py-4 text-gray-600">{p.date}</td>
                <td className="px-6 py-4 font-medium text-gray-900">{p.businessName}</td>
                <td className="px-6 py-4 text-gray-600">{p.product}</td>
                <td className="px-6 py-4 text-gray-600">{p.method}</td>
                <td className="px-6 py-4 text-right font-medium text-gray-900">₩{p.amount.toLocaleString()}</td>
                <td className="px-6 py-4">
                  <span className={`inline-flex px-2.5 py-1 rounded-full text-xs font-medium ${statusStyle[p.status]}`}>
                    {statusLabel[p.status]}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}

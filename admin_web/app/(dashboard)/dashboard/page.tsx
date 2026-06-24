import { getDashboardData } from '@/lib/data'
import { DataBadge } from '@/components/data-badge'
import DashboardClient from './dashboard-client'

export const dynamic = 'force-dynamic'

export default async function DashboardPage() {
  const data = await getDashboardData()

  return (
    <div className="p-8">
      <div className="mb-8">
        <div className="flex items-center gap-3">
          <h1 className="text-2xl font-bold text-gray-900">대시보드</h1>
          <DataBadge />
        </div>
        <p className="text-sm text-gray-500 mt-1">2025년 6월 24일 기준 · 전체 가맹점 현황</p>
      </div>

      <DashboardClient {...data} />
    </div>
  )
}

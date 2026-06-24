import { Database, FlaskConical } from 'lucide-react'
import { dataSource } from '@/lib/data'

// 현재 페이지 데이터가 실제 Supabase DB에서 왔는지, 목업 데모인지 표시합니다.
export function DataBadge() {
  const live = dataSource === 'supabase'
  return (
    <span
      className={`inline-flex items-center gap-1.5 px-2.5 py-1 rounded-full text-xs font-medium ${
        live ? 'bg-green-50 text-green-700 border border-green-200' : 'bg-amber-50 text-amber-700 border border-amber-200'
      }`}
      title={live ? 'Supabase beauty_ai 스키마에서 조회' : '환경변수 미설정 - 목업 데이터'}
    >
      {live ? <Database className="w-3.5 h-3.5" /> : <FlaskConical className="w-3.5 h-3.5" />}
      {live ? '실시간 DB' : '데모 데이터'}
    </span>
  )
}

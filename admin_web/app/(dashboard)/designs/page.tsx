'use client'

import { Star, Globe, Plus } from 'lucide-react'
import { designs, designCategoryLabel } from '@/lib/mock-data'

export default function DesignsPage() {
  return (
    <div className="p-8">
      <div className="flex items-center justify-between mb-6">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">디자인 관리</h1>
          <p className="text-sm text-gray-500 mt-1">눈썹 디자인 라이브러리 · {designs.length}개</p>
        </div>
        <button className="flex items-center gap-2 px-4 py-2 text-sm font-medium text-white bg-purple-600 rounded-lg hover:bg-purple-700">
          <Plus className="w-4 h-4" />
          디자인 추가
        </button>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-6">
        {designs.map((d) => (
          <div key={d.id} className="bg-white rounded-xl shadow-sm border border-gray-100 overflow-hidden hover:shadow-md transition-shadow">
            {/* Thumbnail (gradient placeholder) */}
            <div className={`relative h-40 bg-gradient-to-br ${d.gradient} flex items-center justify-center`}>
              <span className="text-white/90 text-sm font-medium tracking-wide">{d.name}</span>
              <div className="absolute top-3 left-3 flex gap-1.5">
                <span className="px-2 py-0.5 rounded-full bg-white/85 text-gray-700 text-xs font-medium">
                  {designCategoryLabel[d.category]}
                </span>
              </div>
              <div className="absolute top-3 right-3 flex gap-1.5">
                {d.isPublic && (
                  <span className="w-6 h-6 rounded-full bg-white/85 flex items-center justify-center" title="공개">
                    <Globe className="w-3.5 h-3.5 text-blue-600" />
                  </span>
                )}
                {d.isFavorite && (
                  <span className="w-6 h-6 rounded-full bg-white/85 flex items-center justify-center" title="즐겨찾기">
                    <Star className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
                  </span>
                )}
              </div>
            </div>

            <div className="p-4">
              <div className="flex items-center justify-between">
                <h3 className="font-semibold text-gray-900">{d.name}</h3>
                <span className="text-xs text-gray-400">{d.id}</span>
              </div>
              <p className="text-sm text-gray-500 mt-1">
                사용 <span className="font-medium text-gray-700">{d.usageCount.toLocaleString()}</span>회
              </p>
            </div>
          </div>
        ))}
      </div>
    </div>
  )
}

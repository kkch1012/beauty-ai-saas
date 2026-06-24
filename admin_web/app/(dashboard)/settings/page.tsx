'use client'

import { Building2, CreditCard, Bell, Check } from 'lucide-react'

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <label className="block text-sm font-medium text-gray-600 mb-1.5">{label}</label>
      <input
        type="text"
        defaultValue={value}
        className="w-full px-3 py-2 text-sm border border-gray-200 rounded-lg focus:outline-none focus:ring-2 focus:ring-purple-200"
      />
    </div>
  )
}

function Toggle({ label, desc, on }: { label: string; desc: string; on: boolean }) {
  return (
    <div className="flex items-center justify-between py-3">
      <div>
        <p className="text-sm font-medium text-gray-800">{label}</p>
        <p className="text-xs text-gray-500">{desc}</p>
      </div>
      <div className={`w-11 h-6 rounded-full flex items-center px-0.5 ${on ? 'bg-purple-600 justify-end' : 'bg-gray-200 justify-start'}`}>
        <div className="w-5 h-5 rounded-full bg-white shadow" />
      </div>
    </div>
  )
}

export default function SettingsPage() {
  return (
    <div className="p-8 max-w-4xl">
      <div className="mb-6">
        <h1 className="text-2xl font-bold text-gray-900">설정</h1>
        <p className="text-sm text-gray-500 mt-1">가맹점 정보 및 구독 환경설정</p>
      </div>

      <div className="space-y-6">
        {/* 가맹점 정보 */}
        <section className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <div className="flex items-center gap-2 mb-5">
            <Building2 className="w-5 h-5 text-purple-600" />
            <h2 className="text-lg font-semibold text-gray-900">가맹점 정보</h2>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <Field label="샵 이름" value="라뷰티 안과거리점" />
            <Field label="원장님 이름" value="김민지" />
            <Field label="전화번호" value="010-2841-7720" />
            <Field label="사업자등록번호" value="214-86-55012" />
            <div className="md:col-span-2">
              <Field label="주소" value="서울특별시 강남구 강남대로 396" />
            </div>
          </div>
          <div className="mt-5 flex justify-end">
            <button className="flex items-center gap-1.5 px-4 py-2 text-sm font-medium text-white bg-purple-600 rounded-lg hover:bg-purple-700">
              <Check className="w-4 h-4" />
              저장
            </button>
          </div>
        </section>

        {/* 구독 정보 */}
        <section className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <div className="flex items-center gap-2 mb-5">
            <CreditCard className="w-5 h-5 text-purple-600" />
            <h2 className="text-lg font-semibold text-gray-900">구독 정보</h2>
          </div>
          <div className="flex items-center justify-between rounded-lg bg-purple-50 border border-purple-100 p-4">
            <div>
              <div className="flex items-center gap-2">
                <span className="px-2.5 py-1 rounded-full bg-purple-600 text-white text-xs font-medium">프리미엄</span>
                <span className="text-sm font-medium text-gray-800">월 ₩99,000</span>
              </div>
              <p className="text-xs text-gray-500 mt-2">다음 결제일: 2025년 7월 24일 · 이번 달 사용 152건 / 무제한</p>
            </div>
            <button className="px-4 py-2 text-sm font-medium text-purple-700 bg-white border border-purple-200 rounded-lg hover:bg-purple-50">
              플랜 변경
            </button>
          </div>
        </section>

        {/* 알림 설정 */}
        <section className="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
          <div className="flex items-center gap-2 mb-2">
            <Bell className="w-5 h-5 text-purple-600" />
            <h2 className="text-lg font-semibold text-gray-900">알림 설정</h2>
          </div>
          <div className="divide-y divide-gray-100">
            <Toggle label="신규 예약 알림" desc="새 예약이 등록되면 알림을 받습니다." on={true} />
            <Toggle label="결제 알림" desc="구독 결제 및 갱신 시 알림을 받습니다." on={true} />
            <Toggle label="마케팅 정보 수신" desc="신규 기능 및 프로모션 소식을 받습니다." on={false} />
          </div>
        </section>
      </div>
    </div>
  )
}

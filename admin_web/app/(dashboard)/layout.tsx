'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { LayoutDashboard, Users, CreditCard, Image, Settings, LogOut } from 'lucide-react'

const navigation = [
  { name: '대시보드', href: '/dashboard', icon: LayoutDashboard },
  { name: '회원 관리', href: '/members', icon: Users },
  { name: '결제 내역', href: '/payments', icon: CreditCard },
  { name: '디자인 관리', href: '/designs', icon: Image },
  { name: '설정', href: '/settings', icon: Settings },
]

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  const pathname = usePathname()

  return (
    <div className="min-h-screen flex bg-gray-50">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200 flex flex-col fixed h-screen">
        <div className="p-6">
          <h1 className="text-xl font-bold text-purple-600">Beauty AI</h1>
          <p className="text-sm text-gray-500">Admin Dashboard</p>
        </div>

        <nav className="mt-2 flex-1">
          {navigation.map((item) => {
            const active = pathname === item.href
            return (
              <Link
                key={item.name}
                href={item.href}
                className={`flex items-center px-6 py-3 text-sm font-medium border-l-2 transition-colors ${
                  active
                    ? 'border-purple-600 bg-purple-50 text-purple-700'
                    : 'border-transparent text-gray-600 hover:bg-gray-50 hover:text-purple-600'
                }`}
              >
                <item.icon className="w-5 h-5 mr-3" />
                {item.name}
              </Link>
            )
          })}
        </nav>

        <div className="p-6 border-t border-gray-200">
          <div className="flex items-center mb-4">
            <div className="w-9 h-9 rounded-full bg-purple-100 flex items-center justify-center text-purple-700 font-semibold text-sm">
              관
            </div>
            <div className="ml-3">
              <p className="text-sm font-medium text-gray-800">관리자</p>
              <p className="text-xs text-gray-500">admin@beautyai.kr</p>
            </div>
          </div>
          <button className="flex items-center text-sm text-gray-600 hover:text-red-600">
            <LogOut className="w-5 h-5 mr-3" />
            로그아웃
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 ml-64 min-h-screen">{children}</main>
    </div>
  )
}

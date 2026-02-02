import Link from 'next/link'
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
  return (
    <div className="min-h-screen flex">
      {/* Sidebar */}
      <aside className="w-64 bg-white border-r border-gray-200">
        <div className="p-6">
          <h1 className="text-xl font-bold text-purple-600">Beauty AI</h1>
          <p className="text-sm text-gray-500">Admin Dashboard</p>
        </div>

        <nav className="mt-6">
          {navigation.map((item) => (
            <Link
              key={item.name}
              href={item.href}
              className="flex items-center px-6 py-3 text-gray-600 hover:bg-gray-50 hover:text-purple-600"
            >
              <item.icon className="w-5 h-5 mr-3" />
              {item.name}
            </Link>
          ))}
        </nav>

        <div className="absolute bottom-0 w-64 p-6 border-t border-gray-200">
          <button className="flex items-center text-gray-600 hover:text-red-600">
            <LogOut className="w-5 h-5 mr-3" />
            로그아웃
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 bg-gray-50">
        {children}
      </main>
    </div>
  )
}

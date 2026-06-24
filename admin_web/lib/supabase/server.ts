import { createClient } from '@supabase/supabase-js'

// 이 프로젝트 전용 스키마(beauty_ai)를 바라보는 서버용 Supabase 클라이언트.
// 무료 인스턴스를 다른 프로젝트와 공유해도 충돌하지 않도록 별도 스키마를 사용합니다.
// Supabase 대시보드 Settings → API → Exposed schemas 에 `beauty_ai` 를 추가해야 동작합니다.
export function createServerClient() {
  return createClient(
    process.env.NEXT_PUBLIC_SUPABASE_URL!,
    process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
    {
      db: { schema: 'beauty_ai' },
      auth: { persistSession: false },
    }
  )
}

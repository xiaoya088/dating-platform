-- =============================================
-- 修复中介发送私信的问题
-- 问题原因：
-- 1. 中介用户没有使用 Supabase Auth，使用 localStorage 存储用户信息
-- 2. RLS 策略中的 auth.uid() 返回 NULL，导致验证失败
-- 解决方案：
-- 禁用 messages 表的 RLS，由应用层处理授权
-- =============================================

-- 1. 禁用 messages 表的 RLS
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- 2. 删除所有现有的 RLS 策略
DROP POLICY IF EXISTS "users_can_insert_messages" ON messages;
DROP POLICY IF EXISTS "users_can_select_messages" ON messages;
DROP POLICY IF EXISTS "users_can_update_messages" ON messages;
DROP POLICY IF EXISTS "Users can view own messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update received messages" ON messages;
DROP POLICY IF EXISTS "Agencies can view messages" ON messages;
DROP POLICY IF EXISTS "Agencies can send messages" ON messages;
DROP POLICY IF EXISTS "Agencies can update messages" ON messages;
DROP POLICY IF EXISTS "authenticated_can_insert_messages" ON messages;
DROP POLICY IF EXISTS "authenticated_can_select_messages" ON messages;
DROP POLICY IF EXISTS "authenticated_can_update_messages" ON messages;

-- 3. 授予 anon 用户必要的权限（暂时允许匿名访问）
-- 注意：生产环境中应使用更严格的权限控制
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE ON TABLE messages TO anon;
GRANT SELECT ON TABLE users TO anon;
GRANT SELECT ON TABLE agencies TO anon;

-- 4. 验证权限授予
SELECT '=== anon 用户权限 ===' AS info;
SELECT 
    table_name,
    has_table_privilege('anon', table_name::regclass, 'SELECT') AS can_select,
    has_table_privilege('anon', table_name::regclass, 'INSERT') AS can_insert,
    has_table_privilege('anon', table_name::regclass, 'UPDATE') AS can_update,
    has_table_privilege('anon', table_name::regclass, 'DELETE') AS can_delete
FROM information_schema.tables 
WHERE table_schema = 'public'
AND table_name IN ('messages', 'users', 'agencies');

-- 5. 验证 RLS 状态
SELECT '=== RLS 状态 ===' AS info;
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables 
WHERE tablename = 'messages'
AND schemaname = 'public';

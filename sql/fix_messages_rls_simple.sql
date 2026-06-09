-- =============================================
-- 简单修复：禁用 messages 表的 RLS
-- 解决中介发送私信失败的问题
-- =============================================

-- 1. 禁用 messages 表的 RLS
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- 2. 删除所有可能存在的策略（使用更全面的列表）
DO $$
DECLARE
    pol RECORD;
BEGIN
    FOR pol IN 
        SELECT policyname FROM pg_policies WHERE tablename = 'messages'
    LOOP
        EXECUTE format('DROP POLICY IF EXISTS "%s" ON messages', pol.policyname);
        RAISE NOTICE 'Dropped policy: %', pol.policyname;
    END LOOP;
END $$;

-- 3. 再次确认删除所有策略
DROP POLICY IF EXISTS "Users can view own messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update received messages" ON messages;
DROP POLICY IF EXISTS "Agencies can view messages to their clients" ON messages;
DROP POLICY IF EXISTS "Agencies can send messages to their clients" ON messages;
DROP POLICY IF EXISTS "Agencies can view messages" ON messages;
DROP POLICY IF EXISTS "Agencies can send messages" ON messages;
DROP POLICY IF EXISTS "Agencies can update messages" ON messages;
DROP POLICY IF EXISTS "authenticated_can_insert_messages" ON messages;
DROP POLICY IF EXISTS "authenticated_can_select_messages" ON messages;
DROP POLICY IF EXISTS "authenticated_can_update_messages" ON messages;
DROP POLICY IF EXISTS "users_can_insert_messages" ON messages;
DROP POLICY IF EXISTS "users_can_select_messages" ON messages;
DROP POLICY IF EXISTS "users_can_update_messages" ON messages;
DROP POLICY IF EXISTS "allow_agency_select" ON messages;

-- 4. 授予 anon 用户必要的权限
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE ON TABLE messages TO anon;

-- 5. 验证结果
SELECT '=== messages 表 RLS 状态 ===' AS info;
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables 
WHERE tablename = 'messages'
AND schemaname = 'public';

SELECT '=== messages 表策略列表（应为空） ===' AS info;
SELECT policyname, cmd FROM pg_policies WHERE tablename = 'messages';

SELECT '=== anon 用户权限 ===' AS info;
SELECT 
    has_table_privilege('anon', 'messages', 'SELECT') AS can_select,
    has_table_privilege('anon', 'messages', 'INSERT') AS can_insert,
    has_table_privilege('anon', 'messages', 'UPDATE') AS can_update;
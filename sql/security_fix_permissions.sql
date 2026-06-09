-- =============================================
-- 安全修复：过度权限授予问题
-- 撤销 anon 用户的危险权限，实施最小权限原则
-- =============================================

-- 1. 撤销所有表的 DELETE 权限（最危险的操作）
DO $$
DECLARE
    tbl_name TEXT;
BEGIN
    FOR tbl_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('REVOKE DELETE ON TABLE %I FROM anon', tbl_name);
            RAISE NOTICE 'Revoked DELETE on %', tbl_name;
        EXCEPTION WHEN others THEN
            NULL;
        END;
    END LOOP;
END $$;

-- 2. 撤销敏感表的 UPDATE 权限
REVOKE UPDATE ON TABLE users FROM anon;
REVOKE UPDATE ON TABLE agencies FROM anon;
REVOKE UPDATE ON TABLE user_requirements FROM anon;
REVOKE UPDATE ON TABLE user_photos FROM anon;

-- 3. 撤销敏感表的 INSERT 权限
REVOKE INSERT ON TABLE users FROM anon;
REVOKE INSERT ON TABLE agencies FROM anon;
REVOKE INSERT ON TABLE user_requirements FROM anon;

-- 4. 撤销敏感表的 SELECT 权限（密码相关字段）
-- users 表只允许匿名用户查看基本公开信息
REVOKE SELECT ON TABLE users FROM anon;
GRANT SELECT (id, name, photos, gender, province, city, birthday, height, weight, education, occupation, income, marital_status, description, created_at) ON TABLE users TO anon;

-- agencies 表只允许匿名用户查看基本信息
REVOKE SELECT ON TABLE agencies FROM anon;
GRANT SELECT (id, name, phone, address, description, created_at) ON TABLE agencies TO anon;

-- 5. 设置正确的权限级别
-- 用户表 - 匿名用户只能读取公开字段
-- 用户表 - 认证用户可以读取自己的数据（通过 RLS）

-- 6. 创建严格的 RLS 策略（确保已有策略正确）
-- 用户表 RLS
DROP POLICY IF EXISTS "Users can view own profile" ON users;
CREATE POLICY "Users can view own profile" ON users
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Users can update own profile" ON users;
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- 中介表 RLS
DROP POLICY IF EXISTS "Agencies can view own profile" ON agencies;
CREATE POLICY "Agencies can view own profile" ON agencies
    FOR SELECT USING (auth.uid() = id);

DROP POLICY IF EXISTS "Agencies can update own profile" ON agencies;
CREATE POLICY "Agencies can update own profile" ON agencies
    FOR UPDATE USING (auth.uid() = id);

-- 7. 确保 RLS 已启用
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE agencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE match_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE agency_requests ENABLE ROW LEVEL SECURITY;

-- 8. 验证权限撤销结果
SELECT '=== anon 用户权限检查 ===' AS info;
SELECT 
    table_name,
    has_table_privilege('anon', table_name::regclass, 'SELECT') AS can_select,
    has_table_privilege('anon', table_name::regclass, 'INSERT') AS can_insert,
    has_table_privilege('anon', table_name::regclass, 'UPDATE') AS can_update,
    has_table_privilege('anon', table_name::regclass, 'DELETE') AS can_delete
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 9. 验证 RLS 状态
SELECT '=== RLS 状态检查 ===' AS info;
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

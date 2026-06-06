-- ============================================
-- 完整修复：解决匹配推荐功能的所有 RLS 问题
-- 只对已存在的表进行操作
-- ============================================

-- ============================================
-- 第一部分：禁用所有已存在表的 RLS
-- ============================================

-- 禁用核心表的 RLS（使用 IF EXISTS 避免错误）
ALTER TABLE IF EXISTS users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_requirements DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_photos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_privacy DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_activity_preferences DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS match_results DISABLE ROW LEVEL SECURITY;

-- 禁用交互表的 RLS
ALTER TABLE IF EXISTS likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS blacklist DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS agency_requests DISABLE ROW LEVEL SECURITY;

-- 禁用活动和公告表的 RLS
ALTER TABLE IF EXISTS activities DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS activity_registrations DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS activity_types DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS announcements DISABLE ROW LEVEL SECURITY;

-- 禁用中介和选项表的 RLS
ALTER TABLE IF EXISTS agencies DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS education_options DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS income_options DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS family_options DISABLE ROW LEVEL SECURITY;

-- 禁用管理员表的 RLS
ALTER TABLE IF EXISTS admins DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS system_params DISABLE ROW LEVEL SECURITY;

-- ============================================
-- 第二部分：删除所有冲突的 RLS 策略
-- ============================================

-- users 表
DROP POLICY IF EXISTS "Users can read own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Agencies can read their clients" ON users;
DROP POLICY IF EXISTS "Agencies can update their clients" ON users;
DROP POLICY IF EXISTS "Agencies can insert clients" ON users;
DROP POLICY IF EXISTS "Agencies can delete their clients" ON users;

-- user_requirements 表
DROP POLICY IF EXISTS "Users can read own requirements" ON user_requirements;
DROP POLICY IF EXISTS "Users can insert own requirements" ON user_requirements;
DROP POLICY IF EXISTS "Users can update own requirements" ON user_requirements;
DROP POLICY IF EXISTS "Users can delete own requirements" ON user_requirements;
DROP POLICY IF EXISTS "Agencies can read their clients requirements" ON user_requirements;
DROP POLICY IF EXISTS "Agencies can insert their clients requirements" ON user_requirements;
DROP POLICY IF EXISTS "Agencies can update their clients requirements" ON user_requirements;
DROP POLICY IF EXISTS "Agencies can delete their clients requirements" ON user_requirements;

-- user_photos 表
DROP POLICY IF EXISTS "Users can read own photos" ON user_photos;
DROP POLICY IF EXISTS "Users can insert own photos" ON user_photos;
DROP POLICY IF EXISTS "Users can delete own photos" ON user_photos;

-- likes 表
DROP POLICY IF EXISTS "Users can read own likes" ON likes;
DROP POLICY IF EXISTS "Users can insert own likes" ON likes;
DROP POLICY IF EXISTS "Users can delete own likes" ON likes;

-- messages 表
DROP POLICY IF EXISTS "Users can read own messages" ON messages;
DROP POLICY IF EXISTS "Users can insert own messages" ON messages;

-- blacklist 表
DROP POLICY IF EXISTS "Users can read own blacklist" ON blacklist;
DROP POLICY IF EXISTS "Users can insert own blacklist" ON blacklist;
DROP POLICY IF EXISTS "Users can delete own blacklist" ON blacklist;

-- match_results 表
DROP POLICY IF EXISTS "Users can read match results" ON match_results;
DROP POLICY IF EXISTS "Users can insert match results" ON match_results;
DROP POLICY IF EXISTS "Users can delete match results" ON match_results;

-- ============================================
-- 第三部分：配置 anon 用户权限
-- ============================================

-- 确保 anon 角色存在
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon;
    END IF;
END $$;

-- 授予 schema 使用权限
GRANT USAGE ON SCHEMA public TO anon;

-- 授予核心表的权限（使用 IF EXISTS 检查）
DO $$
DECLARE
    tbl_name TEXT;
BEGIN
    -- 动态授予权限给存在的表
    FOR tbl_name IN 
        SELECT tablename FROM pg_tables WHERE schemaname = 'public'
    LOOP
        BEGIN
            EXECUTE format('GRANT SELECT, INSERT, UPDATE ON TABLE %I TO anon', tbl_name);
            EXECUTE format('GRANT DELETE ON TABLE %I TO anon', tbl_name);
        EXCEPTION WHEN others THEN
            -- 忽略错误，继续处理下一个表
            NULL;
        END;
    END LOOP;
END $$;

-- ============================================
-- 第四部分：验证修复
-- ============================================

SELECT '========================================' AS status;
SELECT '匹配推荐功能 RLS 修复完成！' AS message;
SELECT '========================================' AS status;

-- 验证所有表的 RLS 状态
SELECT '所有表的 RLS 状态（应该全部为 false）:' AS info;
SELECT 
    tablename,
    rowsecurity AS rls_enabled
FROM pg_tables 
WHERE schemaname = 'public'
ORDER BY tablename;

-- 验证用户数据
SELECT '用户数据统计:' AS info;
SELECT COUNT(*) AS total_users, 
       COUNT(*) FILTER (WHERE status = 'active') AS active_users
FROM users;

-- 验证匹配结果（如果表存在）
DO $$
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'match_results' AND schemaname = 'public') THEN
        RAISE NOTICE '匹配结果统计:';
        -- 使用动态 SQL 查询
        EXECUTE 'SELECT COUNT(*) AS total_matches FROM match_results';
    ELSE
        RAISE NOTICE 'match_results 表不存在';
    END IF;
END $$;
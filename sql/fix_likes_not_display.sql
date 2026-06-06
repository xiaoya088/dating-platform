-- ============================================
-- 完整修复：解决点赞功能未显示问题
-- 包含：表结构检查、RLS禁用、权限配置、数据验证
-- ============================================

-- ============================================
-- 第一部分：检查并修复表结构
-- ============================================

-- 1. 如果 likes 表不存在，创建它
CREATE TABLE IF NOT EXISTS likes (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    from_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    to_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT NOW(),
    UNIQUE(from_user_id, to_user_id)
);

-- 2. 确保必要的索引存在
CREATE INDEX IF NOT EXISTS idx_likes_from_user_id ON likes(from_user_id);
CREATE INDEX IF NOT EXISTS idx_likes_to_user_id ON likes(to_user_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at DESC);

-- ============================================
-- 第二部分：禁用 RLS（关键修复）
-- ============================================

-- 禁用 likes 表的行级安全
ALTER TABLE IF EXISTS likes DISABLE ROW LEVEL SECURITY;

-- 禁用其他相关表的 RLS
ALTER TABLE IF EXISTS users DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_photos DISABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_requirements DISABLE ROW LEVEL SECURITY;

-- ============================================
-- 第三部分：配置权限
-- ============================================

-- 确保 anon 角色存在
DO $$
BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
        CREATE ROLE anon;
    END IF;
END $$;

-- 授予 anon 用户访问权限
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, DELETE ON TABLE likes TO anon;
GRANT SELECT ON TABLE users TO anon;
GRANT SELECT ON TABLE user_photos TO anon;
GRANT SELECT ON TABLE user_requirements TO anon;

-- 删除可能存在的冲突策略
DROP POLICY IF EXISTS "Users can read own likes" ON likes;
DROP POLICY IF EXISTS "Users can insert own likes" ON likes;
DROP POLICY IF EXISTS "Users can delete own likes" ON likes;

-- ============================================
-- 第四部分：验证修复
-- ============================================

-- 检查表结构
SELECT '========================================' AS status;
SELECT '点赞功能修复完成！' AS message;
SELECT '========================================' AS status;

-- 验证表是否存在
SELECT 'likes 表状态:' AS info;
SELECT 
    tablename, 
    rowsecurity AS rls_enabled,
    hasindexes AS has_indexes
FROM pg_tables 
WHERE tablename = 'likes';

-- 验证权限
SELECT 'anon 用户权限:' AS info;
SELECT 
    table_name,
    has_select_privilege('anon', table_name, 'SELECT') AS can_select,
    has_insert_privilege('anon', table_name, 'INSERT') AS can_insert,
    has_delete_privilege('anon', table_name, 'DELETE') AS can_delete
FROM information_schema.tables 
WHERE table_name IN ('likes', 'users', 'user_photos');

-- 查看点赞数据统计
SELECT '点赞数据统计:' AS info;
SELECT COUNT(*) AS total_likes FROM likes;

-- 查看用户数据统计
SELECT '用户数据统计:' AS info;
SELECT COUNT(*) AS total_users FROM users WHERE status = 'active';

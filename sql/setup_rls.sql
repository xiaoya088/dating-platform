-- ============================================
-- 婚恋红娘系统 RLS 权限设置脚本
-- 运行一次即可，以后不再需要设置
-- ============================================

-- 1. 启用 RLS（如果尚未启用）
ALTER TABLE IF EXISTS users ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_requirements ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS agencies ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS user_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS blacklist ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS activities ENABLE ROW LEVEL SECURITY;
ALTER TABLE IF EXISTS activity_registrations ENABLE ROW LEVEL SECURITY;

-- 2. 删除现有策略（如果存在）
DROP POLICY IF EXISTS "Users can read own profile" ON users;
DROP POLICY IF EXISTS "Users can update own profile" ON users;
DROP POLICY IF EXISTS "Agencies can read their clients" ON users;
DROP POLICY IF EXISTS "Agencies can update their clients" ON users;
DROP POLICY IF EXISTS "Agencies can insert clients" ON users;
DROP POLICY IF EXISTS "Agencies can delete their clients" ON users;

DROP POLICY IF EXISTS "Users can read own requirements" ON user_requirements;
DROP POLICY IF EXISTS "Users can insert own requirements" ON user_requirements;
DROP POLICY IF EXISTS "Users can update own requirements" ON user_requirements;
DROP POLICY IF EXISTS "Users can delete own requirements" ON user_requirements;
DROP POLICY IF EXISTS "Agencies can read their clients requirements" ON user_requirements;
DROP POLICY IF EXISTS "Agencies can insert their clients requirements" ON user_requirements;
DROP POLICY IF EXISTS "Agencies can update their clients requirements" ON user_requirements;
DROP POLICY IF EXISTS "Agencies can delete their clients requirements" ON user_requirements;

DROP POLICY IF EXISTS "Agencies can read own agency" ON agencies;
DROP POLICY IF EXISTS "Agencies can update own agency" ON agencies;

-- ============================================
-- users 表策略
-- ============================================

-- 允许用户读取自己的资料
CREATE POLICY "Users can read own profile" ON users
    FOR SELECT USING (auth.uid() = id);

-- 允许用户更新自己的资料
CREATE POLICY "Users can update own profile" ON users
    FOR UPDATE USING (auth.uid() = id);

-- 允许中介读取其录入客户的资料
CREATE POLICY "Agencies can read their clients" ON users
    FOR SELECT USING (agency_id = auth.uid());

-- 允许中介更新其录入客户的资料
CREATE POLICY "Agencies can update their clients" ON users
    FOR UPDATE USING (agency_id = auth.uid());

-- 允许中介插入新客户
CREATE POLICY "Agencies can insert clients" ON users
    FOR INSERT WITH CHECK (agency_id = auth.uid());

-- 允许中介删除其录入的客户
CREATE POLICY "Agencies can delete their clients" ON users
    FOR DELETE USING (agency_id = auth.uid());

-- ============================================
-- user_requirements 表策略
-- ============================================

-- 允许用户读写自己的择偶要求
CREATE POLICY "Users can read own requirements" ON user_requirements
    FOR SELECT USING (user_id = auth.uid());

CREATE POLICY "Users can insert own requirements" ON user_requirements
    FOR INSERT WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own requirements" ON user_requirements
    FOR UPDATE USING (user_id = auth.uid());

CREATE POLICY "Users can delete own requirements" ON user_requirements
    FOR DELETE USING (user_id = auth.uid());

-- 允许中介读写其录入客户的择偶要求
CREATE POLICY "Agencies can read their clients requirements" ON user_requirements
    FOR SELECT USING (
        user_id IN (SELECT id FROM users WHERE agency_id = auth.uid())
    );

CREATE POLICY "Agencies can insert their clients requirements" ON user_requirements
    FOR INSERT WITH CHECK (
        user_id IN (SELECT id FROM users WHERE agency_id = auth.uid())
    );

CREATE POLICY "Agencies can update their clients requirements" ON user_requirements
    FOR UPDATE USING (
        user_id IN (SELECT id FROM users WHERE agency_id = auth.uid())
    );

CREATE POLICY "Agencies can delete their clients requirements" ON user_requirements
    FOR DELETE USING (
        user_id IN (SELECT id FROM users WHERE agency_id = auth.uid())
    );

-- ============================================
-- agencies 表策略
-- ============================================

-- 允许中介读取自己的机构信息
CREATE POLICY "Agencies can read own agency" ON agencies
    FOR SELECT USING (id = auth.uid());

-- 允许中介更新自己的机构信息
CREATE POLICY "Agencies can update own agency" ON agencies
    FOR UPDATE USING (id = auth.uid());

-- ============================================
-- 验证设置
-- ============================================
SELECT 'RLS 策略设置完成!' AS status;
SELECT tablename, rowsecurity FROM pg_tables WHERE schemaname = 'public' AND rowsecurity = true;
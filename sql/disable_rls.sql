-- ============================================
-- 临时禁用 RLS（让功能先正常运行）
-- ============================================

-- 禁用所有表的 RLS
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_requirements DISABLE ROW LEVEL SECURITY;
ALTER TABLE agencies DISABLE ROW LEVEL SECURITY;
ALTER TABLE user_photos DISABLE ROW LEVEL SECURITY;
ALTER TABLE likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
ALTER TABLE blacklist DISABLE ROW LEVEL SECURITY;
ALTER TABLE activities DISABLE ROW LEVEL SECURITY;
ALTER TABLE activity_registrations DISABLE ROW LEVEL SECURITY;

-- 删除之前创建的策略
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

SELECT 'RLS 已禁用，功能可正常运行!' AS status;
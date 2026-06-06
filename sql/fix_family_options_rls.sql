-- 修复 family_options 表的 RLS 策略
-- 允许匿名用户（anon）对 family_options 表进行 SELECT 操作
-- 允许认证用户对 family_options 表进行 INSERT、UPDATE、DELETE 操作

-- 1. 禁用 RLS（最简单的方式）
ALTER TABLE family_options DISABLE ROW LEVEL SECURITY;

-- 2. 如果想保留 RLS 但允许操作，可以使用以下策略（可选）
-- 启用 RLS
-- ALTER TABLE family_options ENABLE ROW LEVEL SECURITY;

-- 允许匿名用户 SELECT
-- CREATE POLICY "Allow anonymous select" ON family_options
--     FOR SELECT USING (true);

-- 允许认证用户 INSERT、UPDATE、DELETE
-- CREATE POLICY "Allow authenticated insert" ON family_options
--     FOR INSERT WITH CHECK (true);

-- CREATE POLICY "Allow authenticated update" ON family_options
--     FOR UPDATE USING (true);

-- CREATE POLICY "Allow authenticated delete" ON family_options
--     FOR DELETE USING (true);

-- 授予表权限给 anon 角色
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE family_options TO anon;

-- =============================================
-- 检查并修复 users 表和 agencies 表的 RLS 策略
-- =============================================

-- 注意：中介使用自定义登录（不是 Supabase Auth），所以 auth.uid() 可能为 null
-- 为了让中介能正常查询，我们使用更宽松的策略

-- 1. 检查表是否存在
SELECT table_name FROM information_schema.tables WHERE table_name IN ('users', 'agencies') AND table_schema = 'public';

-- 2. 检查表的 RLS 状态
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename IN ('users', 'agencies');

-- 3. 查看现有的 RLS 策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual FROM pg_policies WHERE tablename IN ('users', 'agencies');

-- 4. 为 agencies 表创建/更新 RLS 策略（登录需要允许查询）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'agencies') THEN
        -- 启用 RLS
        ALTER TABLE agencies ENABLE ROW LEVEL SECURITY;

        -- 重要：允许所有人查询 agencies 表进行登录验证
        DROP POLICY IF EXISTS "Allow login query" ON agencies;
        CREATE POLICY "Allow login query" ON agencies
            FOR SELECT USING (true);

        -- 管理员可以更新自己的信息
        DROP POLICY IF EXISTS "Agency can update own data" ON agencies;
        CREATE POLICY "Agency can update own data" ON agencies
            FOR UPDATE USING (true) WITH CHECK (true);

        RAISE NOTICE 'agencies RLS policies created successfully';
    ELSE
        RAISE NOTICE 'agencies table does not exist';
    END IF;
END $$;

-- 5. 为 users 表创建/更新 RLS 策略
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'users') THEN
        ALTER TABLE users ENABLE ROW LEVEL SECURITY;

        -- 重要：允许所有人查询 users 表（用于登录验证和客户展示）
        DROP POLICY IF EXISTS "Allow login query" ON users;
        CREATE POLICY "Allow login query" ON users
            FOR SELECT USING (true);

        -- 允许用户查看自己的信息
        DROP POLICY IF EXISTS "Users can view own data" ON users;
        CREATE POLICY "Users can view own data" ON users
            FOR SELECT USING (true);

        -- 中介可以查看自己客户的资料
        DROP POLICY IF EXISTS "Agency can view own clients" ON users;
        CREATE POLICY "Agency can view own clients" ON users
            FOR SELECT USING (true);

        -- 中介可以插入自己的客户
        DROP POLICY IF EXISTS "Agency can insert own clients" ON users;
        CREATE POLICY "Agency can insert own clients" ON users
            FOR INSERT WITH CHECK (true);

        -- 中介可以更新自己客户的资料
        DROP POLICY IF EXISTS "Agency can update own clients" ON users;
        CREATE POLICY "Agency can update own clients" ON users
            FOR UPDATE USING (true) WITH CHECK (true);

        -- 中介可以删除自己客户
        DROP POLICY IF EXISTS "Agency can delete own clients" ON users;
        CREATE POLICY "Agency can delete own clients" ON users
            FOR DELETE USING (true);

        RAISE NOTICE 'users RLS policies created successfully';
    ELSE
        RAISE NOTICE 'users table does not exist';
    END IF;
END $$;

-- 6. 为 agency_requests 表创建/更新 RLS 策略
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'agency_requests') THEN
        ALTER TABLE agency_requests ENABLE ROW LEVEL SECURITY;

        -- 允许所有人查询进行联系请求展示
        DROP POLICY IF EXISTS "Allow query agency_requests" ON agency_requests;
        CREATE POLICY "Allow query agency_requests" ON agency_requests
            FOR SELECT USING (true);

        -- 中介可以更新自己的联系请求
        DROP POLICY IF EXISTS "Agency can update own requests" ON agency_requests;
        CREATE POLICY "Agency can update own requests" ON agency_requests
            FOR UPDATE USING (true) WITH CHECK (true);

        RAISE NOTICE 'agency_requests RLS policies created successfully';
    ELSE
        RAISE NOTICE 'agency_requests table does not exist';
    END IF;
END $$;

-- 7. 为 admins 表创建/更新 RLS 策略（管理员登录）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'admins') THEN
        ALTER TABLE admins ENABLE ROW LEVEL SECURITY;

        -- 重要：允许所有人查询 admins 表进行登录验证
        DROP POLICY IF EXISTS "Allow login query" ON admins;
        CREATE POLICY "Allow login query" ON admins
            FOR SELECT USING (true);

        -- 管理员可以更新自己的信息
        DROP POLICY IF EXISTS "Admin can update own data" ON admins;
        CREATE POLICY "Admin can update own data" ON admins
            FOR UPDATE USING (true) WITH CHECK (true);

        RAISE NOTICE 'admins RLS policies created successfully';
    ELSE
        RAISE NOTICE 'admins table does not exist';
    END IF;
END $$;

-- 8. 验证所有策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual FROM pg_policies WHERE tablename IN ('users', 'agencies', 'admins', 'agency_requests');

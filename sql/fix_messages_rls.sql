-- 检查 messages 表是否存在
SELECT table_name FROM information_schema.tables WHERE table_name = 'messages';

-- 检查 messages 表的 RLS 状态
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'messages';

-- 为 messages 表创建 RLS 策略（如果表存在且 RLS 已启用）
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_tables WHERE tablename = 'messages') THEN
        -- 启用 RLS
        ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

        -- 创建策略：用户可以查看自己发送或接收的消息
        -- 使用 auth.uid() 获取当前用户ID
        DROP POLICY IF EXISTS "Users can view own messages" ON messages;
        CREATE POLICY "Users can view own messages" ON messages
            FOR SELECT USING (
                from_user_id = auth.uid()
                OR to_user_id = auth.uid()
            );

        -- 创建策略：用户可以插入自己发送的消息
        DROP POLICY IF EXISTS "Users can send messages" ON messages;
        CREATE POLICY "Users can send messages" ON messages
            FOR INSERT WITH CHECK (from_user_id = auth.uid());

        -- 创建策略：用户可以更新自己接收的消息（标记已读）
        DROP POLICY IF EXISTS "Users can update received messages" ON messages;
        CREATE POLICY "Users can update received messages" ON messages
            FOR UPDATE USING (
                to_user_id = auth.uid()
            ) WITH CHECK (to_user_id = auth.uid());

        RAISE NOTICE 'messages RLS policies created successfully';
    ELSE
        RAISE NOTICE 'messages table does not exist';
    END IF;
END $$;

-- 验证 RLS 策略
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual FROM pg_policies WHERE tablename = 'messages';

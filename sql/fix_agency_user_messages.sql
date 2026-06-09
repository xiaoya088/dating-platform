-- =============================================
-- 修复中介与用户之间的消息传递问题
-- 允许中介和用户进行多轮私信
-- =============================================

-- 1. 禁用 messages 表的 RLS（如果已启用）
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- 2. 删除现有的 RLS 策略（如果存在）
DROP POLICY IF EXISTS "Users can view own messages" ON messages;
DROP POLICY IF EXISTS "Users can send messages" ON messages;
DROP POLICY IF EXISTS "Users can update received messages" ON messages;
DROP POLICY IF EXISTS "Agencies can view messages" ON messages;
DROP POLICY IF EXISTS "Agencies can send messages" ON messages;

-- 3. 重新启用 RLS
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;

-- 4. 创建新的 RLS 策略：用户可以查看自己发送或接收的消息
CREATE POLICY "Users can view own messages" ON messages
    FOR SELECT USING (
        from_user_id = auth.uid()
        OR to_user_id = auth.uid()
    );

-- 5. 创建策略：用户可以发送消息
CREATE POLICY "Users can send messages" ON messages
    FOR INSERT WITH CHECK (
        from_user_id = auth.uid()
    );

-- 6. 创建策略：用户可以更新自己接收的消息（标记已读）
CREATE POLICY "Users can update received messages" ON messages
    FOR UPDATE USING (
        to_user_id = auth.uid()
    ) WITH CHECK (
        to_user_id = auth.uid()
    );

-- 7. 创建策略：中介可以查看与自己客户相关的消息
--    中介可以查看：
--    - 自己发送的消息（from_user_id = 中介ID）
--    - 发送给自己的消息（to_user_id = 中介ID）
--    - 自己客户发送或接收的消息（通过 agency_id 关联）
CREATE POLICY "Agencies can view messages" ON messages
    FOR SELECT USING (
        -- 中介可以查看自己发送的消息
        from_user_id = auth.uid()
        -- 中介可以查看发送给自己的消息
        OR to_user_id = auth.uid()
        -- 中介可以查看自己客户发送的消息（客户作为发送方）
        OR EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = messages.from_user_id 
            AND users.agency_id = auth.uid()
        )
        -- 中介可以查看发送给自己客户的消息（客户作为接收方）
        OR EXISTS (
            SELECT 1 FROM users 
            WHERE users.id = messages.to_user_id 
            AND users.agency_id = auth.uid()
        )
    );

-- 8. 创建策略：中介可以发送消息
CREATE POLICY "Agencies can send messages" ON messages
    FOR INSERT WITH CHECK (
        -- 中介可以发送消息给任何人
        from_user_id = auth.uid()
    );

-- 9. 创建策略：中介可以更新消息（标记已读）
CREATE POLICY "Agencies can update messages" ON messages
    FOR UPDATE USING (
        to_user_id = auth.uid()
    ) WITH CHECK (
        to_user_id = auth.uid()
    );

-- 10. 创建索引优化消息查询
-- 删除可能存在的旧索引
DROP INDEX IF EXISTS idx_messages_from_user;
DROP INDEX IF EXISTS idx_messages_to_user;
DROP INDEX IF EXISTS idx_messages_from_to;
DROP INDEX IF EXISTS idx_messages_created_at;

-- 创建复合索引
CREATE INDEX idx_messages_from_user ON messages(from_user_id, created_at DESC);
CREATE INDEX idx_messages_to_user ON messages(to_user_id, created_at DESC);
CREATE INDEX idx_messages_from_to ON messages(from_user_id, to_user_id);
CREATE INDEX idx_messages_created_at ON messages(created_at DESC);

-- 11. 验证策略创建
SELECT '=== messages 表 RLS 策略 ===' AS info;
SELECT schemaname, tablename, policyname, permissive, cmd, qual 
FROM pg_policies 
WHERE tablename = 'messages'
ORDER BY cmd, policyname;

-- 12. 验证索引创建
SELECT '=== messages 表索引 ===' AS info;
SELECT indexname, indexdef FROM pg_indexes WHERE tablename = 'messages';

-- 13. 检查 RLS 状态
SELECT '=== RLS 状态 ===' AS info;
SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'messages';

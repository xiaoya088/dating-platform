-- 修复 messages 表以支持中介用户发送私信

-- 1. 查看当前messages表结构
SELECT * FROM information_schema.columns WHERE table_name = 'messages';

-- 2. 添加新字段标识发送者类型
ALTER TABLE messages 
    ADD COLUMN IF NOT EXISTS sender_type VARCHAR(20) DEFAULT 'user'; -- 'user' 或 'agency'

-- 3. 删除现有的外键约束（因为中介ID不在users表中）
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_from_user_id_fkey;

-- 4. 重新添加 to_user_id 的外键约束（保持不变，接收者必须是用户）
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_to_user_id_fkey;
ALTER TABLE messages 
    ADD CONSTRAINT messages_to_user_id_fkey 
    FOREIGN KEY (to_user_id) REFERENCES users(id) 
    ON DELETE CASCADE;

-- 5. 创建索引优化查询
CREATE INDEX IF NOT EXISTS idx_messages_from_user_id ON messages(from_user_id);
CREATE INDEX IF NOT EXISTS idx_messages_to_user_id ON messages(to_user_id);
CREATE INDEX IF NOT EXISTS idx_messages_sender_type ON messages(sender_type);

-- 6. 更新RLS策略以支持中介用户
DO $$
BEGIN
    -- 删除旧策略
    DROP POLICY IF EXISTS "Users can view own messages" ON messages;
    DROP POLICY IF EXISTS "Users can send messages" ON messages;
    DROP POLICY IF EXISTS "Users can update received messages" ON messages;
    
    -- 用户可以查看自己发送或接收的消息
    CREATE POLICY "Users can view own messages" ON messages
        FOR SELECT USING (
            from_user_id = auth.uid() OR to_user_id = auth.uid()
        );
    
    -- 用户可以发送消息
    CREATE POLICY "Users can send messages" ON messages
        FOR INSERT WITH CHECK (
            from_user_id = auth.uid() AND sender_type = 'user'
        );
    
    -- 用户可以更新自己接收的消息（标记已读）
    CREATE POLICY "Users can update received messages" ON messages
        FOR UPDATE USING (to_user_id = auth.uid());
    
    -- 中介可以查看与自己相关的消息（发送给其客户的消息）
    CREATE POLICY "Agencies can view messages to their clients" ON messages
        FOR SELECT USING (
            sender_type = 'agency' AND from_user_id = auth.uid()
            OR EXISTS (
                SELECT 1 FROM users 
                WHERE users.id = messages.to_user_id 
                AND users.agency_id = auth.uid()
            )
        );
    
    -- 中介可以发送消息给其客户
    CREATE POLICY "Agencies can send messages to their clients" ON messages
        FOR INSERT WITH CHECK (
            sender_type = 'agency' AND from_user_id = auth.uid()
            AND EXISTS (
                SELECT 1 FROM users 
                WHERE users.id = messages.to_user_id 
                AND users.agency_id = auth.uid()
            )
        );
        
    RAISE NOTICE 'messages RLS policies updated for agency support';
END $$;

-- 7. 验证修改
SELECT conname, conrelid::regclass, confrelid::regclass 
FROM pg_constraint 
WHERE conrelid = 'messages'::regclass AND contype = 'f';

SELECT schemaname, tablename, policyname, cmd FROM pg_policies WHERE tablename = 'messages';

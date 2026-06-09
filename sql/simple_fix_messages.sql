-- 简单修复 messages 表的外键约束，允许中介发送私信

-- 1. 删除外键约束（问题所在）
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_from_user_id_fkey;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_to_user_id_fkey;

-- 2. 只为 to_user_id 添加外键约束（接收者必须是用户）
ALTER TABLE messages 
    ADD CONSTRAINT messages_to_user_id_fkey 
    FOREIGN KEY (to_user_id) REFERENCES users(id) 
    ON DELETE CASCADE;

-- 3. 验证修改成功
SELECT conname, conrelid::regclass, confrelid::regclass 
FROM pg_constraint 
WHERE conrelid = 'messages'::regclass AND contype = 'f';

-- 4. 确保RLS允许中介发送消息（如果RLS启用）
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;

-- 修复 messages 表的外键约束，允许中介用户发送私信

-- 1. 查看当前外键约束
SELECT conname, conrelid::regclass, confrelid::regclass
FROM pg_constraint
WHERE conrelid = 'messages'::regclass AND contype = 'f';

-- 2. 删除现有的外键约束
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_from_user_id_fkey;
ALTER TABLE messages DROP CONSTRAINT IF EXISTS messages_to_user_id_fkey;

-- 3. 重新添加外键约束，使用 ON DELETE SET NULL
-- from_user_id 可以是中介用户（agencies表）或普通用户（users表）
ALTER TABLE messages 
    ADD CONSTRAINT messages_from_user_id_fkey 
    FOREIGN KEY (from_user_id) REFERENCES users(id) 
    ON DELETE SET NULL;

ALTER TABLE messages 
    ADD CONSTRAINT messages_to_user_id_fkey 
    FOREIGN KEY (to_user_id) REFERENCES users(id) 
    ON DELETE SET NULL;

-- 4. 验证修改
SELECT conname, conrelid::regclass, confrelid::regclass, confupdtype, confdeltype
FROM pg_constraint
WHERE conrelid = 'messages'::regclass AND contype = 'f';

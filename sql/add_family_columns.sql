-- 为 users 表添加家庭情况相关字段

-- 父母现状
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_parents_status VARCHAR(50);

-- 父母工作
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_parents_job VARCHAR(50);

-- 兄弟姐妹
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_siblings VARCHAR(50);

-- 原生家庭定居地
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_hometown VARCHAR(50);

-- 父母养老保障
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_pension VARCHAR(50);

-- 家庭经济状况
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_economic_status VARCHAR(50);

-- 家庭氛围
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_atmosphere VARCHAR(50);

-- 是否和父母同住
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_living_with_parents VARCHAR(50);

-- 家里对婚恋态度
ALTER TABLE users ADD COLUMN IF NOT EXISTS family_marriage_attitude VARCHAR(50);

-- 为这些字段创建索引（可选，根据查询需求）
CREATE INDEX IF NOT EXISTS idx_users_family_parents_status ON users(family_parents_status);
CREATE INDEX IF NOT EXISTS idx_users_family_parents_job ON users(family_parents_job);
CREATE INDEX IF NOT EXISTS idx_users_family_siblings ON users(family_siblings);
CREATE INDEX IF NOT EXISTS idx_users_family_hometown ON users(family_hometown);
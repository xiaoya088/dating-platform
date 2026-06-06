-- 创建家庭情况选项表
CREATE TABLE IF NOT EXISTS family_options (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    field_name VARCHAR(50) NOT NULL,
    option_value VARCHAR(50) NOT NULL,
    option_label VARCHAR(100) NOT NULL,
    sort_order INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT NOW()
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_family_options_field_name ON family_options(field_name);
CREATE INDEX IF NOT EXISTS idx_family_options_sort_order ON family_options(sort_order);

-- 禁用行级安全策略（允许前端直接访问）
ALTER TABLE family_options DISABLE ROW LEVEL SECURITY;

-- 授予表权限给 anon 角色
GRANT USAGE ON SCHEMA public TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE family_options TO anon;

-- 插入初始数据

-- 父母现状
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_parents_status', 'both_alive', '双亲健在', 1),
('family_parents_status', 'single_parent', '单亲', 2),
('family_parents_status', 'both_deceased', '父母已故', 3);

-- 父母工作
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_parents_job', 'farming', '务农', 1),
('family_parents_job', 'employed', '在职上班', 2),
('family_parents_job', 'retired', '退休', 3),
('family_parents_job', 'business', '个体经商', 4);

-- 兄弟姐妹
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_siblings', 'only_child', '独生', 1),
('family_siblings', 'has_brother_older', '有兄', 2),
('family_siblings', 'has_brother_younger', '有弟', 3),
('family_siblings', 'has_sister_older', '有姐', 4),
('family_siblings', 'has_sister_younger', '有妹', 5);

-- 原生家庭定居地
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_hometown', 'same_city', '和本人同城', 1),
('family_hometown', 'different_city', '异地老家', 2);

-- 父母养老保障
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_pension', 'has_pension', '有退休金社保', 1),
('family_pension', 'no_pension', '无养老保障', 2);

-- 家庭经济状况
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_economic_status', 'wealthy', '富贵人家', 1),
('family_economic_status', 'middle_class', '中产家庭', 2),
('family_economic_status', 'comfortable', '小康之家', 3),
('family_economic_status', 'slight_debt', '略有负债', 4);

-- 家庭氛围
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_atmosphere', 'traditional', '传统保守', 1),
('family_atmosphere', 'open', '开明随和', 2);

-- 是否和父母同住
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_living_with_parents', 'living_alone', '自住独居', 1),
('family_living_with_parents', 'living_with_parents', '和父母同住', 2),
('family_living_with_parents', 'living_nearby', '就近居住', 3);

-- 家里对婚恋态度
INSERT INTO family_options (field_name, option_value, option_label, sort_order) VALUES
('family_marriage_attitude', 'urgent', '催婚', 1),
('family_marriage_attitude', 'natural', '顺其自然', 2),
('family_marriage_attitude', 'no_interference', '不干涉', 3);
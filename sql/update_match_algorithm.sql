-- 匹配算法相关字段更新
-- 为 user_requirements 表添加重要程度字段

ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS age_importance VARCHAR(20) DEFAULT 'normal';
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS height_importance VARCHAR(20) DEFAULT 'normal';
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS education_importance VARCHAR(20) DEFAULT 'normal';
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS income_importance VARCHAR(20) DEFAULT 'normal';
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS marital_status_importance VARCHAR(20) DEFAULT 'normal';
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS province_importance VARCHAR(20) DEFAULT 'normal';
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS min_interest_overlap INTEGER DEFAULT 0;
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS min_activity_overlap INTEGER DEFAULT 0;
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS scheme_type VARCHAR(20) DEFAULT 'standard';
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS body_type VARCHAR(20);
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS smoking VARCHAR(20);
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS drinking VARCHAR(20);
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS personality TEXT[];
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS personality_importance VARCHAR(20) DEFAULT 'normal';
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS activities TEXT[];
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS values VARCHAR(20);
ALTER TABLE user_requirements ADD COLUMN IF NOT EXISTS province VARCHAR(50);

-- 为 users 表添加更多信息
ALTER TABLE users ADD COLUMN IF NOT EXISTS personality TEXT[];
ALTER TABLE users ADD COLUMN IF NOT EXISTS interests TEXT[];
ALTER TABLE users ADD COLUMN IF NOT EXISTS activity_types TEXT[];
ALTER TABLE users ADD COLUMN IF NOT EXISTS smoking VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS drinking VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS privacy_visibility VARCHAR(20) DEFAULT 'all';
ALTER TABLE users ADD COLUMN IF NOT EXISTS accept_pet VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS schedule VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS finance_view VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS live_with_parents VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS expected_children VARCHAR(20);
ALTER TABLE users ADD COLUMN IF NOT EXISTS self_description TEXT;

-- 重要程度枚举值说明:
-- 'must' = 必须满足 (硬性过滤)
-- 'very_important' = 非常重要 (权重1.5)
-- 'normal' = 一般 (权重1.0)
-- 'optional' = 可有可无 (权重0.5)

COMMENT ON COLUMN user_requirements.age_importance IS '年龄重要程度: must(必须满足)/very_important(非常重要)/normal(一般)/optional(可有可无)';
COMMENT ON COLUMN user_requirements.height_importance IS '身高重要程度: must/very_important/normal/optional';
COMMENT ON COLUMN user_requirements.education_importance IS '学历重要程度: must/very_important/normal/optional';
COMMENT ON COLUMN user_requirements.income_importance IS '收入重要程度: must/very_important/normal/optional';
COMMENT ON COLUMN user_requirements.marital_status_importance IS '婚姻状况重要程度: must/very_important/normal/optional';
COMMENT ON COLUMN user_requirements.province_importance IS '省份重要程度: must/very_important/normal/optional';
COMMENT ON COLUMN user_requirements.min_interest_overlap IS '最低兴趣重合数';
COMMENT ON COLUMN user_requirements.min_activity_overlap IS '最低活动重合数';
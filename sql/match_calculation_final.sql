-- =============================================
-- 婚恋匹配系统 - 数据库端匹配计算（最终修复版）
-- =============================================

-- 启用必要的扩展
CREATE EXTENSION IF NOT EXISTS pg_cron;
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =============================================
-- 1. 创建辅助函数
-- =============================================

-- 计算年龄函数
CREATE OR REPLACE FUNCTION calculate_age(birth_date DATE)
RETURNS INTEGER AS $$
BEGIN
    IF birth_date IS NULL THEN
        RETURN NULL;
    END IF;
    RETURN EXTRACT(YEAR FROM AGE(CURRENT_DATE, birth_date))::INTEGER;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 计算区间匹配分数
CREATE OR REPLACE FUNCTION calculate_interval_score(value INTEGER, min_val INTEGER, max_val INTEGER)
RETURNS INTEGER AS $$
BEGIN
    IF value IS NULL OR (min_val IS NULL AND max_val IS NULL) THEN
        RETURN 100;
    END IF;
    IF min_val IS NOT NULL AND value < min_val THEN
        RETURN 0;
    END IF;
    IF max_val IS NOT NULL AND value > max_val THEN
        RETURN 0;
    END IF;
    RETURN 100;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- 获取重要性权重
CREATE OR REPLACE FUNCTION get_importance_weight(importance VARCHAR)
RETURNS NUMERIC AS $$
BEGIN
    CASE importance
        WHEN 'must' THEN RETURN 2.0;
        WHEN 'important' THEN RETURN 1.5;
        WHEN 'normal' THEN RETURN 1.0;
        ELSE RETURN 1.0;
    END CASE;
END;
$$ LANGUAGE plpgsql IMMUTABLE;

-- =============================================
-- 2. 创建主匹配函数（基于实际表结构）
-- =============================================

DROP FUNCTION IF EXISTS calculate_single_match_score(UUID, UUID);

CREATE OR REPLACE FUNCTION calculate_single_match_score(p_user_id UUID, p_target_id UUID)
RETURNS TABLE (score INTEGER, filtered BOOLEAN, reasons TEXT[]) AS $$
DECLARE
    v_my_gender VARCHAR(10);
    v_my_birthday DATE;
    v_my_height INTEGER;
    v_my_education VARCHAR(50);
    v_my_marital_status VARCHAR(20);
    v_my_current_address VARCHAR(200);
    v_my_smoking VARCHAR(20);
    v_my_drinking VARCHAR(20);
    
    v_target_gender VARCHAR(10);
    v_target_birthday DATE;
    v_target_height INTEGER;
    v_target_education VARCHAR(50);
    v_target_marital_status VARCHAR(20);
    v_target_current_address VARCHAR(200);
    v_target_smoking VARCHAR(20);
    v_target_drinking VARCHAR(20);
    
    v_req_min_age INTEGER := 0;
    v_req_max_age INTEGER := 100;
    v_req_min_height INTEGER := 0;
    v_req_max_height INTEGER := 250;
    v_req_education TEXT[];
    v_req_marital_status TEXT[];
    v_req_province VARCHAR(50);
    v_req_smoking VARCHAR(20);
    v_req_drinking VARCHAR(20);
    v_req_age_importance VARCHAR(20) := 'normal';
    v_req_height_importance VARCHAR(20) := 'normal';
    v_req_education_importance VARCHAR(20) := 'normal';
    v_req_marital_importance VARCHAR(20) := 'normal';
    v_req_province_importance VARCHAR(20) := 'normal';
    
    v_target_req_min_age INTEGER := 0;
    v_target_req_max_age INTEGER := 100;
    v_target_req_min_height INTEGER := 0;
    v_target_req_max_height INTEGER := 250;
    v_target_req_education TEXT[];
    v_target_req_marital_status TEXT[];
    v_target_req_province VARCHAR(50);
    v_target_req_age_importance VARCHAR(20) := 'normal';
    v_target_req_height_importance VARCHAR(20) := 'normal';
    v_target_req_education_importance VARCHAR(20) := 'normal';
    v_target_req_marital_importance VARCHAR(20) := 'normal';
    v_target_req_province_importance VARCHAR(20) := 'normal';
    
    v_my_age INTEGER;
    v_target_age INTEGER;
    v_total_score NUMERIC := 0;
    v_total_weight NUMERIC := 0;
    v_result_score INTEGER;
    v_result_filtered BOOLEAN := FALSE;
    v_result_reasons TEXT[] := '{}'::TEXT[];
BEGIN
    -- 获取当前用户数据
    SELECT u.gender, u.birthday, u.height, u.education, u.marital_status, 
           u.current_address, u.smoking, u.drinking
    INTO v_my_gender, v_my_birthday, v_my_height, v_my_education, v_my_marital_status,
         v_my_current_address, v_my_smoking, v_my_drinking
    FROM users u
    WHERE u.id = p_user_id AND u.status = 'active';
    
    -- 获取目标用户数据
    SELECT u.gender, u.birthday, u.height, u.education, u.marital_status,
           u.current_address, u.smoking, u.drinking
    INTO v_target_gender, v_target_birthday, v_target_height, v_target_education, v_target_marital_status,
         v_target_current_address, v_target_smoking, v_target_drinking
    FROM users u
    WHERE u.id = p_target_id AND u.status = 'active';
    
    -- 检查用户是否存在
    IF v_my_gender IS NULL AND v_my_birthday IS NULL THEN
        RETURN QUERY SELECT 0, TRUE, ARRAY['无法获取当前用户数据'];
        RETURN;
    END IF;
    
    IF v_target_gender IS NULL AND v_target_birthday IS NULL THEN
        RETURN QUERY SELECT 0, TRUE, ARRAY['无法获取目标用户数据'];
        RETURN;
    END IF;
    
    -- 异性恋匹配：只匹配异性
    IF v_my_gender IS NOT NULL AND v_target_gender IS NOT NULL 
       AND v_my_gender = v_target_gender THEN
        RETURN QUERY SELECT 0, TRUE, ARRAY['性别相同，仅匹配异性'];
        RETURN;
    END IF;
    
    -- 获取当前用户的择偶要求（使用实际存在的字段）
    SELECT r.min_age, r.max_age, r.min_height, r.max_height,
           r.education, r.marital_status, r.province, r.smoking, r.drinking,
           COALESCE(r.age_importance, 'normal'), COALESCE(r.height_importance, 'normal'),
           COALESCE(r.education_importance, 'normal'), COALESCE(r.marital_importance, 'normal'),
           COALESCE(r.province_importance, 'normal')
    INTO v_req_min_age, v_req_max_age, v_req_min_height, v_req_max_height,
         v_req_education, v_req_marital_status, v_req_province, v_req_smoking, v_req_drinking,
         v_req_age_importance, v_req_height_importance, v_req_education_importance,
         v_req_marital_importance, v_req_province_importance
    FROM user_requirements r
    WHERE r.user_id = p_user_id AND r.scheme_type = 'standard';
    
    -- 获取目标用户的择偶要求
    SELECT r.min_age, r.max_age, r.min_height, r.max_height,
           r.education, r.marital_status, r.province,
           COALESCE(r.age_importance, 'normal'), COALESCE(r.height_importance, 'normal'),
           COALESCE(r.education_importance, 'normal'), COALESCE(r.marital_importance, 'normal'),
           COALESCE(r.province_importance, 'normal')
    INTO v_target_req_min_age, v_target_req_max_age, v_target_req_min_height, v_target_req_max_height,
         v_target_req_education, v_target_req_marital_status, v_target_req_province,
         v_target_req_age_importance, v_target_req_height_importance, v_target_req_education_importance,
         v_target_req_marital_importance, v_target_req_province_importance
    FROM user_requirements r
    WHERE r.user_id = p_target_id AND r.scheme_type = 'standard';
    
    -- 设置默认值
    v_req_min_age := COALESCE(v_req_min_age, 0);
    v_req_max_age := COALESCE(v_req_max_age, 100);
    v_req_min_height := COALESCE(v_req_min_height, 0);
    v_req_max_height := COALESCE(v_req_max_height, 250);
    
    v_target_req_min_age := COALESCE(v_target_req_min_age, 0);
    v_target_req_max_age := COALESCE(v_target_req_max_age, 100);
    v_target_req_min_height := COALESCE(v_target_req_min_height, 0);
    v_target_req_max_height := COALESCE(v_target_req_max_height, 250);
    
    -- 硬筛选：吸烟习惯（当前用户的要求）
    -- 注意：数据库中没有 smoking_importance 字段，这里简化处理
    IF v_req_smoking IS NOT NULL THEN
        IF v_target_smoking IS NULL OR v_target_smoking != v_req_smoking THEN
            RETURN QUERY SELECT 0, TRUE, ARRAY['吸烟习惯不符合要求'];
            RETURN;
        END IF;
    END IF;
    
    -- 硬筛选：饮酒习惯（当前用户的要求）
    IF v_req_drinking IS NOT NULL THEN
        IF v_target_drinking IS NULL OR v_target_drinking != v_req_drinking THEN
            RETURN QUERY SELECT 0, TRUE, ARRAY['饮酒习惯不符合要求'];
            RETURN;
        END IF;
    END IF;
    
    -- 计算年龄
    v_my_age := calculate_age(v_my_birthday);
    v_target_age := calculate_age(v_target_birthday);
    
    -- 年龄匹配（目标用户的要求）
    IF v_target_req_min_age > 0 OR v_target_req_max_age < 100 THEN
        v_total_score := v_total_score + calculate_interval_score(v_my_age, v_target_req_min_age, v_target_req_max_age) 
                         * get_importance_weight(v_target_req_age_importance);
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_age_importance);
    END IF;
    
    -- 身高匹配（目标用户的要求）
    IF v_target_req_min_height > 0 OR v_target_req_max_height < 250 THEN
        v_total_score := v_total_score + calculate_interval_score(v_my_height, v_target_req_min_height, v_target_req_max_height) 
                         * get_importance_weight(v_target_req_height_importance);
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_height_importance);
    END IF;
    
    -- 学历匹配（目标用户的要求）- education 是 TEXT[] 类型
    IF v_target_req_education IS NOT NULL AND array_length(v_target_req_education, 1) > 0 THEN
        IF v_my_education = ANY(v_target_req_education) THEN
            v_total_score := v_total_score + 100 * get_importance_weight(v_target_req_education_importance);
        END IF;
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_education_importance);
    END IF;
    
    -- 婚姻状况匹配（目标用户的要求）- marital_status 是 TEXT[] 类型
    IF v_target_req_marital_status IS NOT NULL AND array_length(v_target_req_marital_status, 1) > 0 THEN
        IF v_my_marital_status = ANY(v_target_req_marital_status) THEN
            v_total_score := v_total_score + 100 * get_importance_weight(v_target_req_marital_importance);
        END IF;
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_marital_importance);
    END IF;
    
    -- 地区匹配（目标用户的要求）
    IF v_target_req_province IS NOT NULL THEN
        IF v_my_current_address IS NOT NULL AND v_my_current_address LIKE '%' || v_target_req_province || '%' THEN
            v_total_score := v_total_score + 100 * get_importance_weight(v_target_req_province_importance);
        END IF;
        v_total_weight := v_total_weight + get_importance_weight(v_target_req_province_importance);
    END IF;
    
    -- 计算最终分数
    IF v_total_weight > 0 THEN
        v_result_score := ROUND(v_total_score / v_total_weight)::INTEGER;
    ELSE
        v_result_score := 50;
    END IF;
    
    RETURN QUERY SELECT v_result_score, v_result_filtered, v_result_reasons;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 3. 为单个用户计算所有匹配
-- =============================================

CREATE OR REPLACE FUNCTION calculate_matches_for_user(p_user_id UUID)
RETURNS VOID AS $$
DECLARE
    v_target_rec RECORD;
    v_score INTEGER;
    v_filtered BOOLEAN;
    v_reasons TEXT[];
BEGIN
    -- 删除旧的匹配结果
    DELETE FROM match_results WHERE user_id = p_user_id;

    -- 遍历所有其他活跃用户
    FOR v_target_rec IN SELECT id FROM users WHERE id != p_user_id AND status = 'active' LOOP
        -- 检查是否在黑名单中
        IF EXISTS (SELECT 1 FROM blacklist WHERE user_id = p_user_id AND blocked_user_id = v_target_rec.id) THEN
            CONTINUE;
        END IF;

        -- 计算匹配分数
        SELECT score, filtered, reasons INTO v_score, v_filtered, v_reasons
        FROM calculate_single_match_score(p_user_id, v_target_rec.id);

        -- 保存匹配结果
        INSERT INTO match_results (user_id, target_user_id, score, is_filtered, filter_reason, calculated_at)
        VALUES (p_user_id, v_target_rec.id, v_score, v_filtered, array_to_string(v_reasons, ', '), NOW());
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 4. 为所有用户计算匹配（批量计算）
-- =============================================

CREATE OR REPLACE FUNCTION calculate_all_matches()
RETURNS VOID AS $$
DECLARE
    v_user_id UUID;
BEGIN
    FOR v_user_id IN SELECT id FROM users WHERE status = 'active' LOOP
        PERFORM calculate_matches_for_user(v_user_id);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- =============================================
-- 5. 设置定时任务（每30分钟执行一次）
-- =============================================

DO $$
BEGIN
    PERFORM cron.unschedule('calculate_all_matches');
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END $$;

SELECT cron.schedule(
    'calculate_all_matches',
    '*/30 * * * *',
    'SELECT calculate_all_matches();'
);

-- =============================================
-- 6. 添加数据变更触发器
-- =============================================

CREATE OR REPLACE FUNCTION trigger_recalculate_user_matches()
RETURNS TRIGGER AS $$
BEGIN
    PERFORM calculate_matches_for_user(NEW.id);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS users_after_update_trigger ON users;
DROP TRIGGER IF EXISTS user_requirements_after_update_trigger ON user_requirements;

CREATE TRIGGER users_after_update_trigger
AFTER UPDATE ON users
FOR EACH ROW
WHEN (OLD.status = 'active' AND NEW.status = 'active')
EXECUTE FUNCTION trigger_recalculate_user_matches();

CREATE TRIGGER user_requirements_after_update_trigger
AFTER INSERT OR UPDATE ON user_requirements
FOR EACH ROW
EXECUTE FUNCTION trigger_recalculate_user_matches();

-- =============================================
-- 执行初始计算
-- =============================================
SELECT calculate_all_matches();

-- =============================================
-- 验证结果
-- =============================================
SELECT '匹配计算完成，当前匹配结果数量：' as info, COUNT(*) as total FROM match_results;

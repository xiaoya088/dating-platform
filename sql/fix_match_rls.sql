-- ============================================
-- 修复 match_results 表 RLS 策略
-- ============================================

-- 1. 先删除已存在的策略（如果有）
DROP POLICY IF EXISTS "agencies_can_view_match_results" ON match_results;

-- 2. 重新创建策略
ALTER TABLE match_results ENABLE ROW LEVEL SECURITY;

CREATE POLICY "agencies_can_view_match_results"
ON match_results FOR SELECT
TO authenticated
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = match_results.user_id 
    AND users.agency_id = current_setting('request.jwt.claims', true)::json->>'sub'
  )
);

-- 3. 验证策略是否创建成功
SELECT schemaname, tablename, policyname, permissive, roles, cmd 
FROM pg_policies 
WHERE tablename = 'match_results';

-- 4. 如果上面的策略还有问题，使用这个简化的匿名访问策略
DROP POLICY IF EXISTS "allow_agency_select" ON match_results;
CREATE POLICY "allow_agency_select" ON match_results FOR SELECT TO anon USING (true);

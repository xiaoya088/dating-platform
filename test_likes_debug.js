// 测试点赞功能的调试脚本
// 使用方法：在浏览器控制台中执行此脚本

async function testLikesFunctionality() {
    console.log('🚀 开始测试点赞功能...');
    
    // 1. 检查当前用户
    const userStr = sessionStorage.getItem('currentUser');
    console.log('📋 当前用户数据:', userStr);
    
    let currentUser = null;
    try {
        currentUser = JSON.parse(userStr);
        console.log('✅ 当前用户解析成功:', currentUser);
    } catch (e) {
        console.error('❌ 当前用户解析失败:', e);
        return;
    }
    
    if (!currentUser || !currentUser.id) {
        console.error('❌ 当前用户未登录或用户ID无效');
        return;
    }
    
    // 2. 检查 Supabase 客户端
    const supabase = getSupabase();
    console.log('🔌 Supabase 客户端:', supabase);
    
    if (!supabase) {
        console.error('❌ Supabase 客户端未初始化');
        return;
    }
    
    // 3. 测试数据库连接
    console.log('🔄 测试数据库连接...');
    try {
        const { data: testData, error: testError } = await supabase.from('users').select('id').limit(1);
        if (testError) {
            console.error('❌ 数据库连接失败:', testError.message);
            return;
        }
        console.log('✅ 数据库连接成功');
    } catch (e) {
        console.error('❌ 数据库连接异常:', e.message);
        return;
    }
    
    // 4. 测试查询点赞表
    console.log('🔄 测试查询点赞表...');
    try {
        const { data: likes, error } = await supabase
            .from('likes')
            .select('*')
            .limit(10);
        
        console.log('📊 点赞数据查询结果:', likes);
        console.log('❌ 错误信息:', error);
        
        if (error) {
            console.error('❌ 查询点赞表失败:', error.message);
            if (error.message.includes('RLS') || error.message.includes('security')) {
                console.error('⚠️ 可能是 RLS 策略问题，请执行 SQL 禁用 RLS');
            }
            if (error.message.includes('does not exist')) {
                console.error('⚠️ likes 表不存在');
            }
            return;
        }
        
        if (!likes || likes.length === 0) {
            console.log('ℹ️ 点赞表中暂无数据');
        } else {
            console.log('✅ 点赞表查询成功，共', likes.length, '条记录');
        }
    } catch (e) {
        console.error('❌ 查询点赞表异常:', e.message);
        return;
    }
    
    // 5. 测试查询当前用户的点赞
    console.log('🔄 测试查询当前用户的点赞...');
    try {
        const { data: myLikes, error } = await supabase
            .from('likes')
            .select('to_user_id, created_at')
            .eq('from_user_id', currentUser.id);
        
        console.log('📊 当前用户点赞记录:', myLikes);
        
        if (error) {
            console.error('❌ 查询当前用户点赞失败:', error.message);
            return;
        }
        
        if (!myLikes || myLikes.length === 0) {
            console.log('ℹ️ 当前用户暂无点赞记录');
        } else {
            console.log('✅ 当前用户有', myLikes.length, '条点赞记录');
        }
    } catch (e) {
        console.error('❌ 查询当前用户点赞异常:', e.message);
        return;
    }
    
    console.log('🎉 测试完成！');
}

// 执行测试
testLikesFunctionality();

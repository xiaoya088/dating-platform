let matchSupabaseClient = null;

function getSupabaseClient() {
    if (typeof supabase === 'undefined') {
        console.error('Supabase library not loaded');
        return null;
    }
    if (!matchSupabaseClient) {
        try {
            matchSupabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);
        } catch (e) {
            console.error('Failed to create Supabase client:', e);
            return null;
        }
    }
    return matchSupabaseClient;
}

function calculateAge(birthday) {
    if (!birthday) return null;
    const birth = new Date(birthday);
    const today = new Date();
    let age = today.getFullYear() - birth.getFullYear();
    const monthDiff = today.getMonth() - birth.getMonth();
    if (monthDiff < 0 || (monthDiff === 0 && today.getDate() < birth.getDate())) {
        age--;
    }
    return age;
}

function getImportanceWeight(importance) {
    const weights = {
        'must': 1000,
        'very_important': 1.5,
        'normal': 1.0,
        'optional': 0.5
    };
    return weights[importance] || 1.0;
}

function jaccardSimilarity(set1, set2) {
    if (!set1 || !set2 || set1.length === 0 || set2.length === 0) return 0;
    const intersection = set1.filter(x => set2.includes(x)).length;
    const union = set1.length + set2.length - intersection;
    return union > 0 ? intersection / union : 0;
}

function calculateIntervalScore(value, min, max, type) {
    if (value === null || value === undefined) return 0;
    
    let numValue = value;
    if (type === 'age') {
        numValue = calculateAge(value);
        if (numValue === null) return 0;
    }
    
    if (min !== null && min !== undefined && numValue < min) {
        const deviation = min - numValue;
        return Math.max(0, 100 - deviation * 10);
    }
    if (max !== null && max !== undefined && numValue > max) {
        const deviation = numValue - max;
        return Math.max(0, 100 - deviation * 10);
    }
    return 100;
}

function calculateCategoryScore(myValue, reqValues) {
    if (!myValue || !reqValues || reqValues.length === 0) return 0;
    if (reqValues.includes(myValue)) return 100;
    return 0;
}

function calculateMultiSelectScore(myValues, reqValues) {
    if (!myValues || !reqValues || myValues.length === 0 || reqValues.length === 0) return 0;
    return jaccardSimilarity(myValues, reqValues) * 100;
}

async function fetchUserData(userId) {
    const supabase = getSupabaseClient();
    if (!supabase) {
        console.error('Supabase client not available');
        return null;
    }

    const { data: user, error: userError } = await supabase
        .from('users')
        .select('*')
        .eq('id', userId)
        .single();

    if (userError || !user) {
        console.error('Error fetching user data:', userError);
        return null;
    }

    const { data: requirements, error: reqError } = await supabase
        .from('user_requirements')
        .select('*')
        .eq('user_id', userId)
        .eq('scheme_type', 'standard')
        .single();

    if (reqError) {
        console.warn('Error fetching requirements:', reqError);
    }

    const { data: photos, error: photosError } = await supabase
        .from('user_photos')
        .select('photo_url')
        .eq('user_id', userId)
        .order('created_at', { ascending: true });

    if (photosError) {
        console.warn('Error fetching photos:', photosError);
    }

    return enrichUserData(user, requirements || {}, photos ? photos.map(p => p.photo_url) : []);
}

function enrichUserData(user, requirements, photos) {
    const toArray = (val) => {
        if (!val) return [];
        if (Array.isArray(val)) return val;
        return val.split(',').filter(Boolean);
    };
    
    return {
        ...user,
        requirements: requirements,
        interests: toArray(user.interests),
        activity_types: toArray(user.activity_types),
        personality: toArray(user.personality),
        photos: photos || []
    };
}

async function fetchUsersDataBatch(userIds) {
    const supabase = getSupabaseClient();
    if (!supabase || !userIds || userIds.length === 0) {
        console.error('Supabase client not available or no user IDs provided');
        return {};
    }

    console.log(`批量获取 ${userIds.length} 个用户数据...`);
    
    const startTime = Date.now();
    
    const [usersResult, requirementsResult, photosResult] = await Promise.all([
        supabase.from('users').select('*').in('id', userIds),
        supabase.from('user_requirements').select('*').in('user_id', userIds).eq('scheme_type', 'standard'),
        supabase.from('user_photos').select('user_id, photo_url').in('user_id', userIds).order('created_at', { ascending: true })
    ]);

    const users = usersResult.data || [];
    const requirementsMap = new Map();
    (requirementsResult.data || []).forEach(req => {
        requirementsMap.set(req.user_id, req);
    });
    
    const photosMap = new Map();
    (photosResult.data || []).forEach(photo => {
        if (!photosMap.has(photo.user_id)) {
            photosMap.set(photo.user_id, []);
        }
        photosMap.get(photo.user_id).push(photo.photo_url);
    });

    const result = {};
    users.forEach(user => {
        result[user.id] = enrichUserData(
            user,
            requirementsMap.get(user.id) || {},
            photosMap.get(user.id) || []
        );
    });

    console.log(`批量获取完成，耗时 ${Date.now() - startTime}ms`);
    
    return result;
}

function hardFilter(myData, targetRequirements) {
    const myAge = calculateAge(myData.birthday);
    
    if (targetRequirements.age_importance === 'must') {
        if (targetRequirements.min_age && (myAge === null || myAge < targetRequirements.min_age)) {
            return { passed: false, reason: `年龄低于最低要求` };
        }
        if (targetRequirements.max_age && (myAge === null || myAge > targetRequirements.max_age)) {
            return { passed: false, reason: `年龄高于最高要求` };
        }
    }

    if (targetRequirements.height_importance === 'must') {
        if (targetRequirements.min_height && (!myData.height || myData.height < targetRequirements.min_height)) {
            return { passed: false, reason: `身高低于最低要求` };
        }
        if (targetRequirements.max_height && (!myData.height || myData.height > targetRequirements.max_height)) {
            return { passed: false, reason: `身高高于最高要求` };
        }
    }

    if (targetRequirements.education_importance === 'must' && targetRequirements.education) {
        const reqEdu = Array.isArray(targetRequirements.education) ? targetRequirements.education : targetRequirements.education.split(',').filter(Boolean);
        if (reqEdu.length > 0 && !reqEdu.includes(myData.education)) {
            return { passed: false, reason: `学历不符合要求` };
        }
    }

    if (targetRequirements.marital_importance === 'must' && targetRequirements.marital_status) {
        const reqMarital = Array.isArray(targetRequirements.marital_status) ? targetRequirements.marital_status : targetRequirements.marital_status.split(',').filter(Boolean);
        if (reqMarital.length > 0 && !reqMarital.includes(myData.marital_status)) {
            return { passed: false, reason: `婚姻状况不符合要求` };
        }
    }

    if (targetRequirements.province_importance === 'must' && targetRequirements.province) {
        if (!myData.current_address || !myData.current_address.includes(targetRequirements.province)) {
            return { passed: false, reason: `现居地不符合要求` };
        }
    }

    if (targetRequirements.smoking_importance === 'must' && targetRequirements.smoking) {
        if (!myData.smoking || myData.smoking !== targetRequirements.smoking) {
            return { passed: false, reason: `吸烟习惯不符合要求` };
        }
    }

    if (targetRequirements.drinking_importance === 'must' && targetRequirements.drinking) {
        if (!myData.drinking || myData.drinking !== targetRequirements.drinking) {
            return { passed: false, reason: `饮酒习惯不符合要求` };
        }
    }

    return { passed: true, reason: null };
}

function calculateWeightedScore(myData, targetRequirements) {
    let totalScore = 0;
    let totalWeight = 0;
    const details = [];

    const ageScore = calculateIntervalScore(myData.birthday, targetRequirements.min_age, targetRequirements.max_age, 'age');
    const ageWeight = getImportanceWeight(targetRequirements.age_importance);
    if (targetRequirements.min_age || targetRequirements.max_age) {
        totalScore += ageScore * ageWeight;
        totalWeight += ageWeight;
        details.push({
            condition: '年龄',
            score: ageScore,
            weight: ageWeight,
            reason: ageScore >= 100 ? '年龄完全匹配' : ageScore > 0 ? `年龄基本匹配` : '年龄不匹配'
        });
    }

    const heightScore = calculateIntervalScore(myData.height, targetRequirements.min_height, targetRequirements.max_height);
    const heightWeight = getImportanceWeight(targetRequirements.height_importance);
    if (targetRequirements.min_height || targetRequirements.max_height) {
        totalScore += heightScore * heightWeight;
        totalWeight += heightWeight;
        details.push({
            condition: '身高',
            score: heightScore,
            weight: heightWeight,
            reason: heightScore >= 100 ? '身高完全匹配' : heightScore > 0 ? `身高基本匹配` : '身高不匹配'
        });
    }

    if (targetRequirements.education) {
        const reqEdu = Array.isArray(targetRequirements.education) ? targetRequirements.education : targetRequirements.education.split(',').filter(Boolean);
        const eduScore = calculateCategoryScore(myData.education, reqEdu);
        const eduWeight = getImportanceWeight(targetRequirements.education_importance);
        totalScore += eduScore * eduWeight;
        totalWeight += eduWeight;
        details.push({
            condition: '学历',
            score: eduScore,
            weight: eduWeight,
            reason: eduScore >= 100 ? '学历完全匹配' : '学历不匹配'
        });
    }

    if (targetRequirements.marital_status) {
        const reqMarital = Array.isArray(targetRequirements.marital_status) ? targetRequirements.marital_status : targetRequirements.marital_status.split(',').filter(Boolean);
        const maritalScore = calculateCategoryScore(myData.marital_status, reqMarital);
        const maritalWeight = getImportanceWeight(targetRequirements.marital_importance);
        totalScore += maritalScore * maritalWeight;
        totalWeight += maritalWeight;
        details.push({
            condition: '婚姻状况',
            score: maritalScore,
            weight: maritalWeight,
            reason: maritalScore >= 100 ? '婚姻状况匹配' : '婚姻状况不匹配'
        });
    }

    if (targetRequirements.province) {
        const provinceScore = myData.current_address && myData.current_address.includes(targetRequirements.province) ? 100 : 0;
        const provinceWeight = getImportanceWeight(targetRequirements.province_importance);
        totalScore += provinceScore * provinceWeight;
        totalWeight += provinceWeight;
        details.push({
            condition: '现居地',
            score: provinceScore,
            weight: provinceWeight,
            reason: provinceScore >= 100 ? '现居地匹配' : '现居地不匹配'
        });
    }

    if (targetRequirements.min_income) {
        const myIncome = parseInt(myData.income) || 0;
        const reqIncome = parseInt(targetRequirements.min_income);
        let incomeScore = 0;
        if (myIncome >= reqIncome) {
            incomeScore = 100;
        } else if (myIncome >= reqIncome * 0.8) {
            incomeScore = 80;
        }
        totalScore += incomeScore * 1.0;
        totalWeight += 1.0;
        details.push({
            condition: '年收入',
            score: incomeScore,
            weight: 1.0,
            reason: incomeScore >= 100 ? '收入达标' : incomeScore >= 80 ? '收入接近要求' : '收入不达标'
        });
    }

    if (targetRequirements.personality) {
        const reqPersonality = Array.isArray(targetRequirements.personality) ? targetRequirements.personality : targetRequirements.personality.split(',').filter(Boolean);
        const personalityScore = calculateMultiSelectScore(myData.personality, reqPersonality);
        totalScore += personalityScore * 1.0;
        totalWeight += 1.0;
        details.push({
            condition: '性格',
            score: personalityScore,
            weight: 1.0,
            reason: personalityScore >= 80 ? '性格高度匹配' : personalityScore >= 50 ? '性格部分匹配' : '性格匹配度较低'
        });
    }

    if (targetRequirements.smoking_importance && targetRequirements.smoking_importance !== 'optional' && targetRequirements.smoking) {
        const smokingScore = myData.smoking && myData.smoking === targetRequirements.smoking ? 100 : 0;
        const smokingWeight = getImportanceWeight(targetRequirements.smoking_importance);
        totalScore += smokingScore * smokingWeight;
        totalWeight += smokingWeight;
        details.push({
            condition: '吸烟',
            score: smokingScore,
            weight: smokingWeight,
            reason: smokingScore >= 100 ? '吸烟习惯匹配' : '吸烟习惯不匹配'
        });
    }

    if (targetRequirements.drinking_importance && targetRequirements.drinking_importance !== 'optional' && targetRequirements.drinking) {
        const drinkingScore = myData.drinking && myData.drinking === targetRequirements.drinking ? 100 : 0;
        const drinkingWeight = getImportanceWeight(targetRequirements.drinking_importance);
        totalScore += drinkingScore * drinkingWeight;
        totalWeight += drinkingWeight;
        details.push({
            condition: '饮酒',
            score: drinkingScore,
            weight: drinkingWeight,
            reason: drinkingScore >= 100 ? '饮酒习惯匹配' : '饮酒习惯不匹配'
        });
    }

    const normalizedScore = totalWeight > 0 ? totalScore / totalWeight : 0;
    return { score: normalizedScore, details };
}

function applyInterestCorrection(baseScore, myInterests, targetRequirements) {
    if (!myInterests || myInterests.length === 0) return { score: baseScore, bonus: 0, reason: '无兴趣标签' };
    
    let bonus = 0;
    const minOverlap = parseInt(targetRequirements.min_interest_overlap) || 2;
    
    const targetInterests = targetRequirements.interests ? (Array.isArray(targetRequirements.interests) ? targetRequirements.interests : targetRequirements.interests.split(',').filter(Boolean)) : [];
    const commonInterests = myInterests.filter(i => targetInterests.includes(i));
    const overlapCount = commonInterests.length;
    
    bonus = Math.min(overlapCount * 2, 10);
    
    let adjustedScore = baseScore + bonus;
    
    if (overlapCount < minOverlap) {
        adjustedScore *= 0.5;
        return { 
            score: adjustedScore, 
            bonus: bonus,
            penalty: '兴趣重合不足',
            reason: `兴趣重合${overlapCount}项，未达最低${minOverlap}项要求，总分减半`,
            commonInterests 
        };
    }
    
    return { 
        score: adjustedScore, 
        bonus: bonus, 
        reason: `兴趣重合${overlapCount}项，每项+2分，共+${bonus}分`,
        commonInterests 
    };
}

function applyActivityBonus(scoreWithInterest, myActivities, targetRequirements) {
    if (!myActivities || myActivities.length === 0) return { score: scoreWithInterest.score, bonus: 0, reason: '无活动偏好' };
    
    let bonus = 0;
    const minOverlap = parseInt(targetRequirements.min_activity_overlap) || 1;
    
    const reqActivities = targetRequirements.activities ? (Array.isArray(targetRequirements.activities) ? targetRequirements.activities : targetRequirements.activities.split(',').filter(Boolean)) : [];
    const commonActivities = myActivities.filter(a => reqActivities.includes(a));
    const overlapCount = commonActivities.length;
    
    bonus = Math.min(overlapCount * 3, 15);
    
    let adjustedScore = scoreWithInterest.score + bonus;
    
    if (overlapCount < minOverlap) {
        adjustedScore *= 0.7;
        return { 
            score: adjustedScore, 
            bonus: bonus,
            penalty: '活动重合不足',
            reason: `活动重合${overlapCount}项，未达最低${minOverlap}项要求，总分减30%`,
            commonActivities 
        };
    }
    
    return { 
        score: adjustedScore, 
        bonus: bonus, 
        reason: `活动重合${overlapCount}项，每项+3分，共+${bonus}分`,
        commonActivities 
    };
}

async function calculateMatchScore(userId, targetId) {
    const [myData, targetData] = await Promise.all([
        fetchUserData(userId),
        fetchUserData(targetId)
    ]);

    if (!myData || !targetData) {
        return { score: 0, filtered: true, reasons: ['无法获取用户数据'] };
    }

    // 异性恋匹配：只匹配异性
    if (myData.gender && targetData.gender && myData.gender === targetData.gender) {
        return { score: 0, filtered: true, reasons: ['性别相同，仅匹配异性'] };
    }

    const myFilterResult = hardFilter(myData, targetData.requirements);
    const targetFilterResult = hardFilter(targetData, myData.requirements);

    if (!myFilterResult.passed || !targetFilterResult.passed) {
        return { 
            score: 0, 
            filtered: true, 
            reasons: [
                myFilterResult.reason,
                targetFilterResult.reason
            ].filter(Boolean)
        };
    }

    const myScoreResult = await calculateWeightedScore(myData, targetData.requirements);
    const targetScoreResult = await calculateWeightedScore(targetData, myData.requirements);

    const myInterestResult = applyInterestCorrection(myScoreResult.score, myData.interests, targetData.requirements);
    const targetInterestResult = applyInterestCorrection(targetScoreResult.score, targetData.interests, myData.requirements);

    const myActivityResult = applyActivityBonus(myInterestResult, myData.activity_types, targetData.requirements);
    const targetActivityResult = applyActivityBonus(targetInterestResult, targetData.activity_types, myData.requirements);

    const aToBScore = Math.min(100, myActivityResult.score);
    const bToAScore = Math.min(100, targetActivityResult.score);
    
    const finalScore = Math.round((aToBScore + bToAScore) / 2);

    const allReasons = [];
    if (myInterestResult.commonInterests && myInterestResult.commonInterests.length > 0) {
        allReasons.push(`共同兴趣：${myInterestResult.commonInterests.join('、')}`);
    }
    if (myActivityResult.commonActivities && myActivityResult.commonActivities.length > 0) {
        allReasons.push(`共同活动偏好：${myActivityResult.commonActivities.join('、')}`);
    }
    myScoreResult.details.forEach(d => {
        if (d.score >= 80) allReasons.push(d.reason);
    });

    return {
        score: finalScore,
        filtered: false,
        aToB: { score: Math.round(aToBScore), details: myScoreResult.details },
        bToA: { score: Math.round(bToAScore), details: targetScoreResult.details },
        reasons: allReasons,
        displayReasons: allReasons.slice(0, 3),
        interestBonus: myInterestResult.bonus,
        activityBonus: myActivityResult.bonus
    };
}

function getUserType(user, targetData) {
    if (!user.agency_id) {
        return 'normal';
    }
    return user.agency_info_public ? 'agency_public' : 'agency_private';
}

async function findMatches(userId, options = {}) {
    const startTime = Date.now();
    const {
        minScore = 0,
        maxResults = 50,
        gender = null,
        city = null,
        forceRefresh = false
    } = options;

    if (MATCH_CONFIG.useCacheFirst && !forceRefresh) {
        console.log('优先使用缓存匹配结果...');
        const cachedMatches = await getCachedMatches(userId);
        
        if (cachedMatches.length > 0) {
            const filtered = filterCachedMatches(cachedMatches, { minScore, maxResults, gender, city });
            console.log(`从缓存获取匹配结果 ${filtered.length} 条，耗时 ${Date.now() - startTime}ms`);
            return filtered;
        }
        
        console.log('缓存为空，回退到实时计算');
    }

    if (!MATCH_CONFIG.enableRealTimeCalculation) {
        console.log('实时计算已禁用，返回空结果');
        return [];
    }

    const supabase = getSupabaseClient();
    if (!supabase) {
        throw new Error('Supabase客户端未初始化');
    }

    console.log('开始实时计算匹配...');

    const myData = await fetchUserData(userId);
    if (!myData) throw new Error('无法获取当前用户数据');

    let query = supabase
        .from('users')
        .select('*')
        .eq('status', 'active')
        .neq('id', userId);

    if (gender) {
        query = query.eq('gender', gender);
    } else if (myData.gender) {
        query = query.eq('gender', myData.gender === '男' ? '女' : '男');
    }

    if (city) {
        query = query.eq('city', city);
    }

    const { data: candidates, error } = await query;
    if (error) {
        console.error('查询候选用户失败:', error);
        throw error;
    }

    if (!candidates || candidates.length === 0) {
        return [];
    }

    const { data: blocked } = await supabase
        .from('blacklist')
        .select('blocked_user_id')
        .eq('user_id', userId);

    const blockedIds = blocked?.map(b => b.blocked_user_id) || [];
    const filteredCandidates = candidates.filter(c => !blockedIds.includes(c.id));

    const candidateIds = filteredCandidates.map(c => c.id);
    const usersDataMap = await fetchUsersDataBatch(candidateIds);

    const results = [];
    for (const candidate of filteredCandidates) {
        const targetData = usersDataMap[candidate.id];
        if (!targetData) continue;

        if (myData.gender && targetData.gender && myData.gender === targetData.gender) {
            continue;
        }

        const myFilterResult = hardFilter(myData, targetData.requirements);
        const targetFilterResult = hardFilter(targetData, myData.requirements);

        if (!myFilterResult.passed || !targetFilterResult.passed) {
            continue;
        }

        const myScoreResult = calculateWeightedScore(myData, targetData.requirements);
        const targetScoreResult = calculateWeightedScore(targetData, myData.requirements);

        const myInterestResult = applyInterestCorrection(myScoreResult.score, myData.interests, targetData.requirements);
        const targetInterestResult = applyInterestCorrection(targetScoreResult.score, targetData.interests, myData.requirements);

        const myActivityResult = applyActivityBonus(myInterestResult, myData.activity_types, targetData.requirements);
        const targetActivityResult = applyActivityBonus(targetInterestResult, targetData.activity_types, myData.requirements);

        const aToBScore = Math.min(100, myActivityResult.score);
        const bToAScore = Math.min(100, targetActivityResult.score);
        const finalScore = Math.round((aToBScore + bToAScore) / 2);

        if (finalScore < minScore) {
            continue;
        }

        const allReasons = [];
        if (myInterestResult.commonInterests && myInterestResult.commonInterests.length > 0) {
            allReasons.push(`共同兴趣：${myInterestResult.commonInterests.join('、')}`);
        }
        if (myActivityResult.commonActivities && myActivityResult.commonActivities.length > 0) {
            allReasons.push(`共同活动偏好：${myActivityResult.commonActivities.join('、')}`);
        }
        myScoreResult.details.forEach(d => {
            if (d.score >= 80) allReasons.push(d.reason);
        });

        results.push({
            user: targetData,
            score: finalScore,
            filtered: false,
            aToB: { score: Math.round(aToBScore), details: myScoreResult.details },
            bToA: { score: Math.round(bToAScore), details: targetScoreResult.details },
            reasons: allReasons,
            displayReasons: allReasons.slice(0, 3),
            interestBonus: myInterestResult.bonus,
            activityBonus: myActivityResult.bonus,
            userType: getUserType(targetData, myData)
        });
    }

    results.sort((a, b) => {
        if (b.score >= 70 && a.score < 70) return 1;
        if (a.score >= 70 && b.score < 70) return -1;
        return b.score - a.score;
    });

    const validMatches = results.slice(0, maxResults);
    console.log(`实时匹配计算完成，有效匹配数: ${validMatches.length}，总耗时: ${Date.now() - startTime}ms`);
    
    return validMatches;
}

function filterCachedMatches(cachedMatches, options) {
    const { minScore = 0, maxResults = 50, gender = null, city = null } = options;
    
    let filtered = cachedMatches.filter(m => {
        if (m.score < minScore) return false;
        if (gender && m.user && m.user.gender !== gender) return false;
        if (city && m.user && m.user.city !== city) return false;
        return true;
    });

    filtered.sort((a, b) => {
        if (b.score >= 70 && a.score < 70) return 1;
        if (a.score >= 70 && b.score < 70) return -1;
        return b.score - a.score;
    });

    return filtered.slice(0, maxResults).map(m => ({
        user: m.user,
        score: m.score,
        filtered: false,
        aToB: m.aToB,
        bToA: m.bToA,
        reasons: [],
        displayReasons: [],
        interestBonus: 0,
        activityBonus: 0,
        userType: getUserType(m.user, {}),
        matchTime: m.matchTime
    }));
}

async function getMatchDetails(userId, targetId) {
    const [myData, targetData] = await Promise.all([
        fetchUserData(userId),
        fetchUserData(targetId)
    ]);

    if (!myData || !targetData) {
        throw new Error('无法获取用户数据');
    }

    const matchResult = await calculateMatchScore(userId, targetId);

    return {
        ...matchResult,
        user: targetData,
        myProfile: {
            age: calculateAge(myData.birthday),
            height: myData.height,
            education: myData.education,
            income: myData.income,
            maritalStatus: myData.marital_status,
            city: myData.current_address,
            interests: myData.interests,
            activities: myData.activity_types,
            personality: myData.personality
        },
        targetProfile: {
            age: calculateAge(targetData.birthday),
            height: targetData.height,
            education: targetData.education,
            income: targetData.income,
            maritalStatus: targetData.marital_status,
            city: targetData.current_address,
            interests: targetData.interests,
            activities: targetData.activity_types,
            personality: targetData.personality
        },
        userType: getUserType(myData, targetData),
        agency: targetData.agency_id ? { id: targetData.agency_id, name: targetData.agency_name } : null
    };
}

function formatMatchCard(match, currentUserGender) {
    const { user, score, reasons, userType } = match;
    const age = calculateAge(user.birthday);

    let displayInfo = {};
    let actions = [];
    let badge = '';

    if (userType === 'normal' || userType === 'agency_public') {
        displayInfo = {
            name: user.name || '匿名用户',
            avatar: user.photos?.[0] || user.avatar_url || 'https://via.placeholder.com/100',
            age: age || '?',
            height: user.height || '?',
            city: user.current_address || '',
            education: user.education || '',
            declaration: user.declaration || '',
            income: user.income || '',
            marital: user.marital_status || '',
            occupation: user.occupation || ''
        };
        actions = [
            { type: 'primary', label: '点赞', onClick: `likeUser('${user.id}')` },
            { type: 'secondary', label: '私信', onClick: `sendMessage('${user.id}')` }
        ];
        if (userType === 'agency_public' && user.agency_name) {
            badge = `<span class="badge badge-info">由${user.agency_name}提供</span>`;
        }
    } else if (userType === 'agency_private') {
        displayInfo = {
            name: '******',
            avatar: user.photos?.[0] || user.avatar_url || 'https://via.placeholder.com/100',
            age: age || '?',
            height: '***',
            city: '***',
            education: user.education || '',
            declaration: '部分信息已隐藏'
        };
        actions = [
            { type: 'primary', label: '联系中介', onClick: `requestAgencyContact('${user.id}')` }
        ];
        badge = `<span class="badge badge-warning">需通过中介联系</span>`;
    }

    return {
        displayInfo,
        actions,
        badge,
        score,
        reasons
    };
}

if (typeof module !== 'undefined' && module.exports) {
    module.exports = {
        calculateMatchScore,
        findMatches,
        getMatchDetails,
        formatMatchCard,
        fetchUserData,
        calculateAge,
        checkUnreadMessages,
        initMessageNotification
    };
} else {
    window.findMatches = findMatches;
    window.calculateMatchScore = calculateMatchScore;
    window.getMatchDetails = getMatchDetails;
    window.formatMatchCard = formatMatchCard;
    window.fetchUserData = fetchUserData;
    window.calculateAge = calculateAge;
    window.checkUnreadMessages = checkUnreadMessages;
    window.initMessageNotification = initMessageNotification;
}

let notificationInterval = null;
let lastCheckedTime = null;

async function checkUnreadMessages(userId) {
    const supabase = getSupabaseClient();
    if (!supabase || !userId) return 0;
    
    try {
        const { data, error } = await supabase
            .from('messages')
            .select('id, from_user_id, to_user_id, created_at')
            .eq('to_user_id', userId)
            .eq('is_read', false);
        
        if (error) {
            console.error('检查未读消息失败:', error);
            return 0;
        }
        
        const count = data?.length || 0;
        updateMessageBadge(count);
        
        if (count > 0 && lastCheckedTime) {
            const newMessages = data.filter(m => new Date(m.created_at) > lastCheckedTime);
            if (newMessages.length > 0) {
                showBrowserNotification('💕 新私信', `您有 ${count} 条未读私信`);
            }
        }
        
        lastCheckedTime = new Date();
        return count;
    } catch (e) {
        console.error('检查未读消息异常:', e);
        return 0;
    }
}

function updateMessageBadge(count) {
    const badge = document.getElementById('msgBadge');
    if (!badge) return;
    
    if (count > 0) {
        badge.textContent = count > 99 ? '99+' : count;
        badge.style.display = 'inline';
    } else {
        badge.style.display = 'none';
    }
}

function showBrowserNotification(title, body) {
    if (!('Notification' in window)) {
        console.log('浏览器不支持通知');
        return;
    }
    
    if (Notification.permission === 'granted') {
        new Notification(title, {
            body: body,
            icon: '💕',
            tag: 'hongniang-message'
        });
    } else if (Notification.permission !== 'denied') {
        Notification.requestPermission().then(permission => {
            if (permission === 'granted') {
                new Notification(title, {
                    body: body,
                    icon: '💕',
                    tag: 'hongniang-message'
                });
            }
        });
    }
}

function initMessageNotification(userId) {
    if (!userId) return;
    
    if (notificationInterval) {
        clearInterval(notificationInterval);
    }
    
    checkUnreadMessages(userId);
    
    notificationInterval = setInterval(() => {
        checkUnreadMessages(userId);
    }, 30000);
}

async function saveMatchResult(userId, targetUserId, matchResult) {
    const supabase = getSupabaseClient();
    if (!supabase) return;
    
    try {
        const data = {
            user_id: userId,
            target_user_id: targetUserId,
            score: matchResult.score || 0,
            a_to_b_score: matchResult.aToB?.score,
            b_to_a_score: matchResult.bToA?.score,
            reasons: matchResult.reasons || [],
            common_interests: matchResult.commonInterests || [],
            common_activities: matchResult.commonActivities || [],
            calculated_at: new Date().toISOString(),
            is_filtered: matchResult.filtered || false,
            filter_reason: matchResult.filtered ? (matchResult.reasons?.[0] || null) : null
        };
        
        const { error } = await supabase
            .from('match_results')
            .upsert(data, { 
                onConflict: 'user_id,target_user_id',
                ignoreDuplicates: false
            });
        
        if (error) {
            console.error('保存匹配结果失败:', error);
        } else {
            console.log('匹配结果已保存:', targetUserId, '分数:', data.score);
        }
    } catch (e) {
        console.error('保存匹配结果异常:', e);
    }
}

async function getCachedMatches(userId) {
    const supabase = getSupabaseClient();
    if (!supabase) return [];
    
    try {
        const { data, error } = await supabase
            .from('match_results')
            .select('*')
            .eq('user_id', userId)
            .eq('is_filtered', false)
            .order('score', { ascending: false })
            .limit(100);
        
        if (error) {
            console.error('获取缓存匹配失败:', error);
            return [];
        }
        
        if (!data || data.length === 0) {
            console.log('没有找到缓存的匹配结果，请确保数据库已执行 calculate_all_matches()');
            return [];
        }
        
        const targetIds = data.map(m => m.target_user_id);
        
        const { data: users, error: usersError } = await supabase
            .from('users')
            .select('*')
            .in('id', targetIds)
            .eq('status', 'active');
        
        if (usersError) {
            console.error('获取用户数据失败:', usersError);
            return [];
        }
        
        const userMap = {};
        users?.forEach(u => userMap[u.id] = u);
        
        return data.map(row => ({
            userId: row.target_user_id,
            score: row.score,
            aToB: { score: row.a_to_b_score },
            bToA: { score: row.b_to_a_score },
            user: userMap[row.target_user_id],
            matchTime: row.calculated_at
        }));
    } catch (e) {
        console.error('getCachedMatches 错误:', e);
        return [];
    }
}

async function calculateAndCacheMatches(userId, options = {}) {
    const supabase = getSupabaseClient();
    if (!supabase) return [];
    
    console.log('开始计算并缓存匹配结果:', userId);
    
    try {
        const myData = await fetchUserData(userId);
        if (!myData) throw new Error('无法获取当前用户数据');
        
        const { data: candidates } = await supabase
            .from('users')
            .select('*')
            .eq('status', 'active')
            .neq('id', userId);
        
        if (!candidates) return [];
        
        const { data: blocked } = await supabase
            .from('blacklist')
            .select('blocked_user_id')
            .eq('user_id', userId);
        
        const blockedIds = blocked?.map(b => b.blocked_user_id) || [];
        const filteredCandidates = candidates.filter(c => !blockedIds.includes(c.id));
        
        const savePromises = filteredCandidates.map(async (candidate) => {
            try {
                const matchResult = await calculateMatchScore(userId, candidate.id);
                await saveMatchResult(userId, candidate.id, matchResult);
                return matchResult;
            } catch (e) {
                console.error(`计算匹配失败 ${candidate.id}:`, e);
                return null;
            }
        });
        
        await Promise.all(savePromises);
        console.log('匹配结果缓存完成');
        
        return getCachedMatches(userId);
    } catch (e) {
        console.error('计算并缓存匹配失败:', e);
        return [];
    }
}

async function calculateMatchesForAllUsers() {
    const supabase = getSupabaseClient();
    if (!supabase) {
        console.error('Supabase 未初始化');
        return;
    }
    
    console.log('开始为所有用户计算匹配结果...');
    
    try {
        const { data: allUsers, error: usersError } = await supabase
            .from('users')
            .select('id')
            .eq('status', 'active');
        
        if (usersError) {
            console.error('获取用户列表失败:', usersError);
            return;
        }
        
        if (!allUsers || allUsers.length === 0) {
            console.log('没有活跃用户');
            return;
        }
        
        console.log(`共有 ${allUsers.length} 位活跃用户需要计算匹配`);
        
        for (const user of allUsers) {
            try {
                console.log(`正在为用户 ${user.id} 计算匹配...`);
                await calculateAndCacheMatches(user.id);
            } catch (e) {
                console.error(`为用户 ${user.id} 计算匹配失败:`, e);
            }
        }
        
        console.log('所有用户的匹配计算完成！');
    } catch (e) {
        console.error('批量计算匹配失败:', e);
    }
}

let matchCalculationInterval = null;

const MATCH_CONFIG = {
    useCacheFirst: true,
    enableRealTimeCalculation: false,
    cacheTtlMinutes: 60,
    periodicIntervalMinutes: 60
};

function setMatchConfig(config) {
    Object.assign(MATCH_CONFIG, config);
    console.log('匹配配置已更新:', MATCH_CONFIG);
}

function startPeriodicMatchCalculation(userId, intervalMinutes = MATCH_CONFIG.periodicIntervalMinutes, forAllUsers = true) {
    if (matchCalculationInterval) {
        clearInterval(matchCalculationInterval);
    }
    
    console.log(`开始定期匹配计算，间隔 ${intervalMinutes} 分钟${forAllUsers ? '（为所有用户计算）' : ''}`);
    
    if (forAllUsers) {
        calculateMatchesForAllUsers();
    } else {
        calculateAndCacheMatches(userId);
    }
    
    matchCalculationInterval = setInterval(() => {
        console.log('执行定期匹配计算...');
        if (forAllUsers) {
            calculateMatchesForAllUsers();
        } else {
            calculateAndCacheMatches(userId);
        }
    }, intervalMinutes * 60 * 1000);
}

function stopPeriodicMatchCalculation() {
    if (matchCalculationInterval) {
        clearInterval(matchCalculationInterval);
        matchCalculationInterval = null;
        console.log('已停止定期匹配计算');
    }
}

if (typeof module === 'undefined') {
    window.initMessageNotification = initMessageNotification;
    window.getCachedMatches = getCachedMatches;
    window.calculateAndCacheMatches = calculateAndCacheMatches;
    window.calculateMatchesForAllUsers = calculateMatchesForAllUsers;
    window.startPeriodicMatchCalculation = startPeriodicMatchCalculation;
    window.stopPeriodicMatchCalculation = stopPeriodicMatchCalculation;
    window.MATCH_CONFIG = MATCH_CONFIG;
    window.setMatchConfig = setMatchConfig;
}
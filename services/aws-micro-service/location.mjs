import * as https from 'https';
import * as querystring from 'querystring';

// --- NAVER API 설정 (환경 변수에서 로드) ---
const NAVER_CLIENT_ID = process.env.NAVER_CLIENT_ID;
const NAVER_CLIENT_SECRET = process.env.NAVER_CLIENT_SECRET;
const NAVER_LOCAL_SEARCH_URL_HOST = process.env.NAVER_LOCAL_SEARCH_URL_HOST ?? "openapi.naver.com";
const NAVER_LOCAL_SEARCH_URL_PATH = process.env.NAVER_LOCAL_SEARCH_URL_PATH ?? "/v1/search/local.json";
const DEFAULT_POST_NUMBER = process.env.DEFAULT_POST_NUMBER ?? "30303";

// ... (removeHtmlTags 및 createErrorResponse 함수는 동일합니다.)

function removeHtmlTags(text) {
    if (typeof text !== 'string') return '';
    return text.replace(/<[^>]*>?/gm, '');
}

function createErrorResponse(statusCode, message, detail) {
    return {
        statusCode: statusCode,
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify({
            status: statusCode,
            message: message,
            detail: detail
        }, null, 2)
    };
}

/**
 * AWS Lambda 메인 핸들러 함수 (ES Module export)
 */
export const handler = async (event) => {
    if (!NAVER_CLIENT_ID || !NAVER_CLIENT_SECRET) {
        console.error("NAVER API credentials missing. Set NAVER_CLIENT_ID and NAVER_CLIENT_SECRET.");
        return createErrorResponse(500, "환경 변수 오류", "NAVER API 자격증명이 설정되지 않았습니다.");
    }
    // 1. 'q' (검색어) 쿼리 파라미터 추출
    const queryParameters = event.queryStringParameters;
    
    if (!queryParameters || !queryParameters.q) {
        return createErrorResponse(400, "잘못된 요청", "검색어(q) 파라미터가 누락되었거나 비어 있습니다.");
    }
    
    const search_query = queryParameters.q;

    // 2. 네이버 API 요청 옵션 설정
    const naverQueryParams = {
        query: search_query,
        display: 5,
        start: 1,
        sort: 'random'
    };
    
    // querystring.stringify 사용
    const naverRequestOptions = {
        hostname: NAVER_LOCAL_SEARCH_URL_HOST,
        path: `${NAVER_LOCAL_SEARCH_URL_PATH}?${querystring.stringify(naverQueryParams)}`,
        method: 'GET',
        headers: {
            'X-Naver-Client-Id': NAVER_CLIENT_ID,
            'X-Naver-Client-Secret': NAVER_CLIENT_SECRET
        }
    };
    
    // 3. 네이버 API 호출
    let naverResult;
    try {
        naverResult = await new Promise((resolve, reject) => {
            const req = https.request(naverRequestOptions, (res) => {
                let data = '';
                
                if (res.statusCode !== 200) {
                    res.on('data', (chunk) => { data += chunk; });
                    res.on('end', () => {
                        try {
                            const errorDetail = JSON.parse(data);
                            reject({ 
                                statusCode: res.statusCode, 
                                message: "네이버 API 오류", 
                                detail: JSON.stringify(errorDetail) 
                            });
                        } catch (e) {
                            reject({ 
                                statusCode: res.statusCode, 
                                message: "네이버 API 오류", 
                                detail: `HTTP ${res.statusCode} 응답` 
                            });
                        }
                    });
                    return;
                }
                
                res.on('data', (chunk) => {
                    data += chunk;
                });

                res.on('end', () => {
                    try {
                        resolve(JSON.parse(data));
                    } catch (e) {
                        reject({ statusCode: 500, message: "JSON 파싱 오류", detail: e.message });
                    }
                });
            });

            req.on('error', (e) => {
                reject({ statusCode: 500, message: "외부 API 호출 실패", detail: e.message });
            });
            
            req.end();
        });
    } catch (error) {
        console.error("Naver API Call Error:", error);
        return createErrorResponse(error.statusCode || 500, error.message || "서버 오류", error.detail || "외부 API 처리 중 오류 발생");
    }

    // 4. 데이터 변환 (이 부분은 동일)
    const transformed_locations = [];
    
    for (const item of naverResult.items || []) {
        const longitude = parseFloat(item.mapx) / 10000000;
        const latitude = parseFloat(item.mapy) / 10000000;

        const location_data = {
            latitude: latitude,
            longitude: longitude,
            location: removeHtmlTags(item.title),
            address: item.address ? item.address.trim() : '',
            roadAddress: item.roadAddress ? item.roadAddress.trim() : '',
            post_number: DEFAULT_POST_NUMBER
        };
        transformed_locations.push(location_data);
    }

    // 5. 최종 응답
    const response_body = {
        status: 200,
        message: "지도 검색 성공",
        data: {
            locations: transformed_locations
        }
    };
    
    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json'
        },
        body: JSON.stringify(response_body, null, 2)
    };
};
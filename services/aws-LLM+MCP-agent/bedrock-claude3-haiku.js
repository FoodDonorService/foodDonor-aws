// index.js (Test Version)

import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";

// 사용할 모델 ID 정의 (Claude 3 Haiku)
const MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0"; 
const client = new BedrockRuntimeClient({ region: "ap-northeast-2" });

/**
 * Bedrock 연결 테스트 및 간단한 메뉴 추천 추론을 수행하는 핸들러 함수
 */
export const handler = async (event) => {
    // --- 1. 테스트용 입력 데이터 ---
    const recipientMemo = "저는 땅콩 알레르기가 있습니다.";
    const availableItems = ["보쌈 정식", "땅콩 쿠키", "참치 샐러드", "크림빵"];

    // --- 2. 시스템 및 사용자 프롬프트 구성 ---
    const systemPrompt = `당신은 AI 매칭 시스템입니다. 수혜자의 안전(알레르기)을 최우선으로 고려해, 가용 품목 중 가장 적합한 메뉴 하나만 추천하세요. 불가능하면 '추천 불가'를 반환하세요.`;
    
    const userPrompt = `수혜자 메모: "${recipientMemo}". 가용 품목: [${availableItems.join(', ')}]. 추천 메뉴 하나와 추천 이유(10자 이내)를 JSON 형식으로 반환하세요.`;

    // --- 3. 모델 요청 본문 생성 ---
    const body = JSON.stringify({
        anthropic_version: "bedrock-2023-05-31",
        messages: [
            { role: 'user', content: userPrompt }
        ],
        system: systemPrompt,
        max_tokens: 100, // 테스트를 위해 출력 토큰 제한
        temperature: 0.1, // 정밀한 판단을 위해 낮은 온도 설정
    });

    try {
        // --- 4. Bedrock API 호출 ---
        const command = new InvokeModelCommand({
            body,
            modelId: MODEL_ID,
            contentType: 'application/json',
            accept: 'application/json',
        });
        const response = await client.send(command);
        
        // --- 5. 응답 파싱 및 반환 ---
        const responseBody = JSON.parse(new TextDecoder().decode(response.body));
        
        // 응답 구조 검증
        if (!responseBody.content || !Array.isArray(responseBody.content) || responseBody.content.length === 0) {
            throw new Error('Invalid response structure from Bedrock');
        }
        
        const recommendationText = responseBody.content[0].text;

        return {
            statusCode: 200,
            body: JSON.stringify({
                status: "success",
                message: "Bedrock 연결 및 추천 테스트 완료",
                recommendation: recommendationText
            }),
        };

    } catch (error) {
        console.error("Bedrock API 호출 오류:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: "AI 서비스 호출 실패", details: error.message }),
        };
    }
};
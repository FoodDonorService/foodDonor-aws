// AWS SDK v3 모듈
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand, UpdateCommand, GetCommand, ScanCommand, BatchGetCommand } from "@aws-sdk/lib-dynamodb";
import { BedrockRuntimeClient, InvokeModelCommand } from "@aws-sdk/client-bedrock-runtime";
import { randomUUID } from "crypto";
// --- 클라이언트 초기화 ---
const ddbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);
const bedrockClient = new BedrockRuntimeClient({ region: "ap-northeast-2" });

// 환경 변수 (하드코딩)
const MATCH_TABLE_NAME = "task";
const RECIPIENT_TABLE_NAME = "recipient";
const VOLUNTEER_MATCH_TABLE_NAME = "volunteer_match";
const LLM_MODEL_ID = "anthropic.claude-3-haiku-20240307-v1:0";
const AWS_REGION = "ap-northeast-2";

// 하버사인 공식을 사용한 거리 계산 (미터 단위)
function calculateDistance(lat1, lon1, lat2, lon2) {
    const R = 6371000; // 지구 반경 (미터)
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLon = (lon2 - lon1) * Math.PI / 180;
    const a = 
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
        Math.sin(dLon / 2) * Math.sin(dLon / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    return R * c; // 미터 단위
}

// 공통 응답 포맷 (status, message, data)
function createApiResponse(status, message, data = null) {
    // status에 따라 statusCode 결정
    let statusCode = 200;
    if (status === "error" || status === "Unauthorized") {
        statusCode = status === "Unauthorized" ? 401 : 500;
    } else if (status === "NOT_FOUND") {
        statusCode = 404;
    } else if (status === "FAILED") {
        statusCode = 500;
    }
    
    const responsePayload = { status, message, data };
    
    return {
        statusCode: statusCode,
        headers: {
            "Access-Control-Allow-Origin": "*",
            "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
            "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT,DELETE"
        },
        body: JSON.stringify(responsePayload),
    };
}

/**
 * 메인 핸들러 (3-way 라우터 역할)
 */
export const handler = async (event) => {

    // --- 분기 1: Flow 2 (SQS 트리거 - 비동기 작업 실행) ---
    // (*** 여기가 "절충안"으로 수정된 부분 1 ***)
    if (event.Records) {
        console.log("Handling SQS Trigger (Async Job - Flow 2)");
        
        for (const record of event.Records) {
            let task_id = null; // 에러 처리에서 사용하기 위해 밖에서 선언
            try {
                console.log("Processing SQS record:", JSON.stringify(record));
                
                // 6. SQS 메시지 파싱
                const message = JSON.parse(record.body);
                console.log("Parsed message:", JSON.stringify(message));
                
                // 구조 분해 할당으로 변수 선언 및 할당
                const { 
                    task_id: parsedTaskId, 
                    volunteer_id, 
                    donation_id, 
                    latitude, 
                    longitude, 
                    donation_name 
                } = message;
                
                // task_id는 이미 외부에서 선언되었으므로 할당
                task_id = parsedTaskId;

                if (!task_id) {
                    throw new Error("task_id is missing from SQS message");
                }

                console.log(`Processing task_id: ${task_id}`);

                // 7. Match DB에 'PROCESSING' 기록
                const matchItem = {
                    task_id: task_id,
                    volunteer_id: volunteer_id,
                    donation_id: donation_id,
                    status: "PROCESSING",
                    createdAt: new Date().toISOString(),
                };
                await ddbDocClient.send(new PutCommand({
                    TableName: MATCH_TABLE_NAME,
                    Item: matchItem,
                }));
                console.log(`Task ${task_id} set to PROCESSING`);

                // 8 & 9. 수혜자 DB (DynamoDB) 거리순 상위 5명 선택
                // DynamoDB는 지리적 쿼리를 직접 지원하지 않으므로, 모든 recipient를 스캔하고 거리 계산
                const scanCommand = new ScanCommand({
                    TableName: RECIPIENT_TABLE_NAME
                });
                const allRecipients = await ddbDocClient.send(scanCommand);
                console.log(`Found ${allRecipients.Items?.length || 0} total recipients`);
                
                // 모든 recipient의 거리 계산 및 정렬
                const recipientsWithDistance = (allRecipients.Items || [])
                    .filter(recipient => recipient.latitude && recipient.longitude)
                    .map(recipient => {
                        const distance = calculateDistance(
                            latitude, longitude,
                            parseFloat(recipient.latitude),
                            parseFloat(recipient.longitude)
                        );
                        return { ...recipient, distance };
                    })
                    .sort((a, b) => a.distance - b.distance) // 거리순 정렬
                    .slice(0, 5); // 상위 5명 선택 (5명보다 적을 수도 있음)

                console.log(`Selected top ${recipientsWithDistance.length} recipients by distance`);

                // 10. LLM에 전송 (거리순 상위 5명 전달, 최대 2명 선택)
                
                // (A) LLM이 '읽을' 정보 (모든 정보 포함)
                const recipientsForLLM = recipientsWithDistance.map(b => ({
                    id: b.recipient_id,
                    name: b.name,
                    phone_number: b.phone_number,
                    address: b.address,
                    post_number: b.post_number,
                    notes: b.notes
                }));

                // (B) LLM이 '반환할' 형식 (ID와 이유만, 최대 2명, 0명일 수도 있음)
                const systemPrompt = `당신은 AI 매칭 시스템입니다. 기부 물품과 수혜자의 notes를 고려하여 가장 적합한 수혜자를 추천하세요. 적합한 수혜자가 없으면 빈 배열을 반환하세요.`;
                
                const userPrompt = `다음과 같은 기부 물품과 거리순 상위 수혜자 목록이 있습니다.
[기부 정보]
음식: ${donation_name}
[수혜자 목록 (JSON)]
${JSON.stringify(recipientsForLLM)}

[작업]
위 '수혜자 목록' 중에서 '기부 정보'와 'notes'를 고려하여 
가장 적합한 수혜자를 최대 2명까지 추천해 주세요.
적합한 수혜자가 없으면 빈 배열 []을 반환하세요.
응답은 반드시 다음 JSON 형식의 '배열'로만 반환해 주세요.
[
  {
    "id": "(선택한 수혜자의 id)",
    "reason_by_mcp": "(추천 이유)"
  },
  ...
]
(최대 2명, 0명일 수도 있음)`;

                console.log(`Calling Bedrock LLM for task ${task_id}`);
                
                // bedrock-claude3-haiku.js와 동일한 구조로 변경
                const body = JSON.stringify({
                    anthropic_version: "bedrock-2023-05-31",
                    messages: [
                        { role: "user", content: userPrompt }
                    ],
                    system: systemPrompt,
                    max_tokens: 1000,
                    temperature: 0.1, // 정밀한 판단을 위해 낮은 온도 설정
                });
                
                const bedrockResponse = await bedrockClient.send(new InvokeModelCommand({
                    body,
                    modelId: LLM_MODEL_ID,
                    contentType: "application/json",
                    accept: "application/json",
                }));

                // (llmResult = "[{\"id\": \"...\", \"reason_by_mcp\": \"...\"}]" 또는 "[]")
                const llmResultText = JSON.parse(new TextDecoder().decode(bedrockResponse.body)).content[0].text;
                console.log(`LLM raw response for task ${task_id}:`, llmResultText);
                
                // LLM 결과 파싱 (빈 배열일 수도 있음)
                let llmResult;
                try {
                    // LLM이 반환한 텍스트를 JSON으로 파싱
                    llmResult = JSON.parse(llmResultText);
                    // 배열이 아니거나 null인 경우 빈 배열로 처리
                    if (!Array.isArray(llmResult)) {
                        console.warn(`LLM result is not an array, converting to empty array. Value:`, llmResult);
                        llmResult = [];
                    }
                } catch (parseError) {
                    console.warn(`Failed to parse LLM result for task ${task_id}, treating as empty:`, parseError);
                    console.warn(`LLM raw text:`, llmResultText);
                    llmResult = [];
                }

                console.log(`LLM parsed result for task ${task_id}:`, JSON.stringify(llmResult));

                // 11. Match DB에 결과 저장 (수정: 'ID + 이유' 배열 저장, 빈 배열일 수도 있음)
                await ddbDocClient.send(new UpdateCommand({
                    TableName: MATCH_TABLE_NAME,
                    Key: { task_id: task_id },
                    UpdateExpression: "SET #status = :status, #recList = :recList",
                    ExpressionAttributeNames: { 
                        "#status": "status", 
                        "#recList": "recommended_list" // (ID와 이유가 담긴 가벼운 JSON)
                    },
                    ExpressionAttributeValues: { 
                        ":status": "COMPLETED", 
                        ":recList": JSON.stringify(llmResult) // 빈 배열일 수도 있음
                    },
                }));
                console.log(`Task ${task_id} completed successfully`);
                
            } catch (error) {
                console.error(`Error processing SQS record for task ${task_id || 'unknown'}:`, error);
                console.error("Error stack:", error.stack);
                console.error("Error details:", JSON.stringify(error, Object.getOwnPropertyNames(error)));
                
                // task_id가 있으면 상태를 FAILED로 업데이트
                if (task_id) {
                    try {
                        await ddbDocClient.send(new UpdateCommand({
                            TableName: MATCH_TABLE_NAME,
                            Key: { task_id: task_id },
                            UpdateExpression: "SET #status = :status, #error = :error",
                            ExpressionAttributeNames: { 
                                "#status": "status",
                                "#error": "error_message"
                            },
                            ExpressionAttributeValues: { 
                                ":status": "FAILED", 
                                ":error": error.message || String(error)
                            },
                        }));
                        console.log(`Task ${task_id} marked as FAILED`);
                    } catch (updateError) {
                        console.error(`Failed to update task ${task_id} status to FAILED:`, updateError);
                    }
                }
            }
        }
        return; // SQS는 응답 불필요
    }

    // --- API Gateway 요청 처리 (분기 2 & 3) ---
    const httpMethod = event.requestContext?.http?.method;
    const path = event.requestContext?.http?.path;
    const cognito_id = event.requestContext?.authorizer?.jwt?.claims?.sub;
    const email = event.requestContext?.authorizer?.jwt?.claims?.email;

    try {
        // --- 분기 2: POST /recipient/profile (1.2.8 수혜자 프로필 생성) ---
        // (*** 여기가 "절충안"으로 수정된 부분 2 ***)
        if (httpMethod === 'POST' && path === '/recipient/profile') {
            
            if (!cognito_id) { 
                return createApiResponse("error", "Unauthorized");
            }

            const body = JSON.parse(event.body);

            // DynamoDB에 수혜자 프로필 저장
            const newRecipient = {
                recipient_id: cognito_id, // PK
                email: email,
                name: body.name,
                phone_number: body.phone_number,
                address: body.address,
                post_number: body.post_number,
                notes: body.notes,
                latitude: parseFloat(body.latitude),
                longitude: parseFloat(body.longitude),
                role: "RECIPIENT",
                created_at: new Date().toISOString()
            };

            await ddbDocClient.send(new PutCommand({
                TableName: RECIPIENT_TABLE_NAME,
                Item: newRecipient
            }));

            // 1.2.8 명세서 응답 반환
            return createApiResponse("success", "수혜자 프로필이 성공적으로 생성되었습니다.", {
                recipient_id: cognito_id, // 명세서 기준 필드명
                email: newRecipient.email,
                name: newRecipient.name,
                // ... (newRecipient의 모든 필드) ...
                latitude: body.latitude,
                longitude: body.longitude,
                notes: newRecipient.notes,
                role: newRecipient.role,
                created_at: newRecipient.created_at
            });
        }
        // --- [신규] 분기 3: POST /recipient/accept/{task_id} (1.2.11 수혜자 선택) ---
        else if (httpMethod === 'POST' && path.startsWith('/recipient/accept/')) {
            console.log("Handling POST /recipient/accept/{task_id} (Select Recipient)");
            
            if (!cognito_id) { // Volunteer must be logged in
                return createApiResponse("error", "Unauthorized");
            }

            // 1. 파라미터 추출
            const task_id = event.pathParameters.task_id;
            const body = JSON.parse(event.body);
            const { recipient_id } = body; // 선택된 수혜자
            const volunteer_id = cognito_id; // 요청한 자원봉사자

            if (!recipient_id) {
                return createApiResponse("error", "recipient_id is required in the body.");
            }

            // 2. 검증을 위해 현재 작업(task) 조회
            const getResult = await ddbDocClient.send(new GetCommand({
                TableName: MATCH_TABLE_NAME,
                Key: { task_id: task_id }
            }));

            if (!getResult.Item) {
                return createApiResponse("NOT_FOUND", "Task not found");
            }
            const task = getResult.Item;

            // 3. 권한 검증 (작업을 요청한 봉사자 본인인지)
            if (task.volunteer_id !== volunteer_id) {
                return createApiResponse("error", "You are not authorized to accept this task.");
            }

            // 4. 상태 검증 (COMPLETED 상태인지)
            if (task.status !== "COMPLETED") {
                return createApiResponse("error", "This task is not yet completed.");
            }
            
            // 5. (추가 검증) 선택한 recipient_id가 추천 목록에 있는지 확인
            const recommendedList = JSON.parse(task.recommended_list || "[]");
            const isValidChoice = recommendedList.some(item => item.id === recipient_id);
            
            if (!isValidChoice) {
                 return createApiResponse("error", "The selected recipient_id was not part of the recommended list.");
            }

            // 6. [NEW LOGIC] 'volunteer_match' DB에 새 항목 생성
            // (task 테이블은 더 이상 'CONFIRMED'로 업데이트하지 않음)
            const match_id = randomUUID(); // 새 PK 생성
            const matchItem = {
                match_id: match_id,           // PK
                task_id: task_id,           // FK
                donation_id: task.donation_id,  // FK (task 테이블에서 가져옴)
                volunteer_id: volunteer_id, // FK (선택한 봉사자)
                recipient_id: recipient_id, // FK (선택된 수혜자)
                status: "CONFIRMED",      // 이 레코드의 상태
                confirmed_at: new Date().toISOString()
            };

            await ddbDocClient.send(new PutCommand({
                TableName: VOLUNTEER_MATCH_TABLE_NAME, // "volunteer_match" 테이블
                Item: matchItem
            }));

            // 7. 명세서대로 성공 응답 반환
            return createApiResponse("success", "매칭이 성공적으로 확정되었습니다.", {
                match_id: match_id,
                task_id: task_id,
                recipient_id: recipient_id
            });
        }
        // --- 분기 4: GET /recipient/tasks/{task_id} (Flow 3: 결과 조회) ---
        // (*** 여기가 "절충안"으로 수정된 부분 3 ***)
        else if (httpMethod === 'GET' && path.startsWith('/recipient/tasks/')) {
            console.log("Handling GET /recipient/tasks/{task_id} (Polling - Flow 3)");
            const task_id = event.pathParameters.task_id;

            // 1. (DynamoDB 조회) 'match' 테이블에서 'ID + 이유' 배열 가져오기
            const result = await ddbDocClient.send(new GetCommand({
                TableName: MATCH_TABLE_NAME,
                Key: { task_id: task_id }
            }));

            if (!result.Item) {
                return createApiResponse("NOT_FOUND", "Task not found");
            }

            const { status, recommended_list, error_message } = result.Item;

            if (status === "FAILED") {
                // 작업 실패 시 에러 메시지 반환
                return createApiResponse("FAILED", error_message || "매칭 작업 중 오류가 발생했습니다.");
            }

            if (status === "COMPLETED") {
                
                // 2. (DynamoDB 결과 파싱) 
                // recommendedList = [{"id": "cognito-id-A", "reason_by_mcp": "..."}, ...] 또는 []
                const recommendedList = JSON.parse(recommended_list || "[]");
                
                // 0명인 경우 (적합한 수혜자가 없음)
                if (!recommendedList || recommendedList.length === 0) {
                    return createApiResponse("COMPLETED", "적합한 수혜자가 없습니다.", {
                        recommended_recipients: []
                    });
                }
                
                const recipientIds = recommendedList.map(item => item.id);

                // 3. (DynamoDB 2차 조회) ID 목록으로 최신 프로필 정보 조회
                // BatchGetCommand로 여러 recipient 조회
                const keys = recipientIds.map(id => ({ recipient_id: id }));
                const batchGetCommand = new BatchGetCommand({
                    RequestItems: {
                        [RECIPIENT_TABLE_NAME]: {
                            Keys: keys
                        }
                    }
                });
                const batchResponse = await ddbDocClient.send(batchGetCommand);
                const recipientProfiles = batchResponse.Responses[RECIPIENT_TABLE_NAME] || [];

                // 4. (데이터 조립) DynamoDB 결과를 Map으로 변환 (빠른 조립용)
                const profileMap = new Map();
                for (const profile of recipientProfiles) {
                    profileMap.set(profile.recipient_id, profile);
                }

                // 5. (데이터 병합) DynamoDB(이유)와 DynamoDB(정보)를 합치기
                const finalResponseData = recommendedList.map(item => {
                    const profile = profileMap.get(item.id);
                    return {
                        recipient_id: item.id,
                        recipient_name: profile ? profile.name : "N/A",
                        phone_number: profile ? profile.phone_number : "N/A",
                        recipient_post_number: profile ? profile.post_number : "N/A",
                        recipient_address: profile ? profile.address : "N/A",
                        reason_by_mcp: item.reason_by_mcp // DynamoDB에서 가져온 이유
                    };
                });

                // 6. (최종 응답 반환) 1.2.10 명세서에 맞게 반환
                return createApiResponse("COMPLETED", "매칭작업이 완료되었습니다.", {
                    recommended_recipients: finalResponseData 
                });
                
            } else {
                // (Flow 3: Case 1) 아직 처리 중
                return createApiResponse("PROCESSING", "매칭 작업이 아직 처리 중입니다.");
            }
        }

        return createApiResponse("NOT_FOUND", "경로를 찾을 수 없습니다.");

    } catch (error) {
        console.error("Error in match-service (API):", error);
        if (error.name === "ConditionalCheckFailedException") { // DynamoDB 중복 키 에러
            return createApiResponse("error", "Profile already exists for this user.");
        }
        return createApiResponse("error", `Internal Server Error: ${error.message}`);
    }
};
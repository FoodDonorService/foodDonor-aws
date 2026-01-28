// handler.js
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import {
  DynamoDBDocumentClient,
  PutCommand,
  QueryCommand,
  UpdateCommand,
  GetCommand,
  ScanCommand,
} from "@aws-sdk/lib-dynamodb";
import { randomUUID } from "crypto";

// 환경 변수 (하드코딩) - 다른 Lambda와 동일한 패턴
const client = new DynamoDBClient({ region: "ap-northeast-2" });
const ddbDocClient = DynamoDBDocumentClient.from(client);

const VOLUNTEER_TABLE_NAME = "volunteer";
const GSI_VOLUNTEER_COGNITO = "cognito_id-index"; // ✅ 확인됨: volunteer 테이블의 GSI
const DONATION_TABLE_NAME = "donation";
const GSI_DONATION_STATUS = "status-index"; // ✅ 확인됨: donation 테이블의 GSI
const VOLUNTEER_MATCH_TABLE_NAME = "volunteer_match";
const GSI_MATCH_VOLUNTEER = "volunteer_id-index"; // ✅ 확인됨: volunteer_match 테이블의 GSI
const TASK_TABLE_NAME = "task";

const apiResponse = (statusCode, body) => ({
  statusCode,
  headers: {
    "Content-Type": "application/json",
    "Access-Control-Allow-Origin": "*",
  },
  body: JSON.stringify(body),
});

// 공통: Cognito JWT 클레임 추출 (REST v1 / HTTP API v2 모두 지원)
function getClaims(event) {
  const authorizer = event.requestContext?.authorizer;
  // HTTP API(v2): authorizer.jwt.claims
  // REST API(v1): authorizer.claims
  return authorizer?.jwt?.claims || authorizer?.claims || null;
}

// 헬퍼: Cognito ID로 내 Volunteer ID 찾기
// GSI가 없을 수 있으므로 Scan + FilterExpression 사용
async function getVolunteerIdByCognito(cognitoId) {
  if (!cognitoId) {
    console.warn("getVolunteerIdByCognito: cognitoId is null or undefined");
    return null;
  }
  
  try {
    // 먼저 GSI로 시도 (cognito_id-index 사용)
    const queryParams = {
      TableName: VOLUNTEER_TABLE_NAME,
      IndexName: GSI_VOLUNTEER_COGNITO,
      KeyConditionExpression: "cognito_id = :c_id",
      ExpressionAttributeValues: { ":c_id": cognitoId }
    };
    console.log(`Querying GSI ${GSI_VOLUNTEER_COGNITO} with cognitoId: ${cognitoId}`);
    const queryResult = await ddbDocClient.send(new QueryCommand(queryParams));
    if (queryResult.Items && queryResult.Items.length > 0) {
      return queryResult.Items[0].volunteer_id;
    }
  } catch (queryError) {
    // GSI가 없거나 에러 발생 시 Scan으로 폴백
    console.log(`GSI query failed, falling back to Scan: ${queryError.message}`);
  }
  
  // Scan + FilterExpression으로 폴백
  const scanParams = {
    TableName: VOLUNTEER_TABLE_NAME,
    FilterExpression: "cognito_id = :c_id",
    ExpressionAttributeValues: { ":c_id": cognitoId }
  };
  const scanResult = await ddbDocClient.send(new ScanCommand(scanParams));
  return scanResult.Items && scanResult.Items.length > 0 
    ? scanResult.Items[0].volunteer_id 
    : null;
}

/**
 * 1.2.7 자원봉사자 프로필 생성
 */
export const createProfile = async (event) => {
  try {
    const method =
      event.requestContext?.http?.method || // HTTP API (v2)
      event.httpMethod; // REST API (v1)

    // CORS preflight 안전 처리
    if (method === "OPTIONS") {
      return apiResponse(200, {
        status: "success",
        message: "CORS preflight OK",
        data: null,
      });
    }

    const body = JSON.parse(event.body);
    const { name, phone_number } = body;
    const claims = getClaims(event);
    const cognitoId = claims?.sub;

    if (!name || !phone_number || !cognitoId) {
      return apiResponse(400, { message: "필수 정보가 누락되었습니다." });
    }

    const existingId = await getVolunteerIdByCognito(cognitoId);
    if (existingId) {
      return apiResponse(409, { message: "이미 프로필이 존재합니다." });
    }

    const newVolunteerId = randomUUID();
    const newProfile = {
      volunteer_id: newVolunteerId,
      cognito_id: cognitoId,
      name,
      phone_number,
      status: "ACTIVE",
      created_at: new Date().toISOString(),
    };

    await ddbDocClient.send(new PutCommand({ TableName: VOLUNTEER_TABLE_NAME, Item: newProfile }));
    
    return apiResponse(201, newProfile);

  } catch (error) {
    console.error("프로필 생성 오류:", error);
    return apiResponse(500, { message: "서버 오류", error: error.message });
  }
};

/**
 * 1.2.8 등록된 기부 목록 조회
 */
export const getDonationList = async (event) => {
  try {
    const method =
      event.requestContext?.http?.method || // HTTP API (v2)
      event.httpMethod; // REST API (v1)

    if (method === "OPTIONS") {
      return apiResponse(200, {
        status: "success",
        message: "CORS preflight OK",
        data: null,
      });
    }

    // PDF 명세서 기준 'pending' 상태인 기부 조회
    // GSI가 없을 수 있으므로 먼저 Query 시도, 실패 시 Scan으로 폴백
    let data;
    try {
      const params = {
        TableName: DONATION_TABLE_NAME,
        IndexName: GSI_DONATION_STATUS,
        KeyConditionExpression: "#status = :status_val",
        ExpressionAttributeNames: { "#status": "status" },
        ExpressionAttributeValues: {
          ":status_val": "pending" 
        },
      };
      data = await ddbDocClient.send(new QueryCommand(params));
    } catch (queryError) {
      // GSI가 없거나 에러 발생 시 Scan으로 폴백
      console.log(`GSI query failed, falling back to Scan: ${queryError.message}`);
      const scanParams = {
        TableName: DONATION_TABLE_NAME,
        FilterExpression: "#status = :status_val",
        ExpressionAttributeNames: { "#status": "status" },
        ExpressionAttributeValues: {
          ":status_val": "pending"
        },
      };
      data = await ddbDocClient.send(new ScanCommand(scanParams));
    }

    return apiResponse(200, {
      status: "success",
      message: "등록된 기부 목록 조회 성공",
      data: { donation_list: data.Items }
    });

  } catch (error) {
    console.error("기부 목록 조회 오류:", error);
    return apiResponse(500, { message: "서버 오류", error: error.message });
  }
};

/**
 * 1.2.11 자신의 봉사 내역 조회 (핵심 수정)
 * volunteer_match를 기준으로 donation과 task 정보를 합쳐서 반환
 */
export const getTaskHistory = async (event) => {
  try {
    const method =
      event.requestContext?.http?.method || // HTTP API (v2)
      event.httpMethod; // REST API (v1)

    if (method === "OPTIONS") {
      return apiResponse(200, {
        status: "success",
        message: "CORS preflight OK",
        data: null,
      });
    }

    const claims = getClaims(event);
    const cognitoId = claims?.sub;
    const myVolunteerId = await getVolunteerIdByCognito(cognitoId);

    if (!myVolunteerId) {
      return apiResponse(404, { message: "봉사자 프로필을 찾을 수 없습니다." });
    }

    // 1. volunteer_match 테이블에서 내 매칭 기록 조회
    // GSI가 없을 수 있으므로 먼저 Query 시도, 실패 시 Scan으로 폴백
    let matches = [];
    try {
      const matchQuery = {
        TableName: VOLUNTEER_MATCH_TABLE_NAME,
        IndexName: GSI_MATCH_VOLUNTEER,
        KeyConditionExpression: "volunteer_id = :v_id",
        ExpressionAttributeValues: { ":v_id": myVolunteerId }
      };
      const queryResult = await ddbDocClient.send(new QueryCommand(matchQuery));
      matches = queryResult.Items || [];
    } catch (queryError) {
      // GSI가 없거나 에러 발생 시 Scan으로 폴백
      console.log(`GSI query failed, falling back to Scan: ${queryError.message}`);
      const scanParams = {
        TableName: VOLUNTEER_MATCH_TABLE_NAME,
        FilterExpression: "volunteer_id = :v_id",
        ExpressionAttributeValues: { ":v_id": myVolunteerId }
      };
      const scanResult = await ddbDocClient.send(new ScanCommand(scanParams));
      matches = scanResult.Items || [];
    }

    if (!matches || matches.length === 0) {
      return apiResponse(200, {
        status: "success",
        message: "봉사 내역이 없습니다.",
        data: { task_list: [] }
      });
    }

    // 2. 상세 정보 병합 (Application-side Join)
    // 각 매칭 건에 대해 donation 테이블과 task 테이블의 정보를 가져옴
    const detailedTasks = await Promise.all(matches.map(async (match) => {
      let donationInfo = {};
      let taskInfo = {};

      // 기부 정보 조회 (음식 이름, 카테고리 등)
      if (match.donation_id) {
        const donationRes = await ddbDocClient.send(new GetCommand({
          TableName: DONATION_TABLE_NAME,
          Key: { donation_id: match.donation_id }
        }));
        donationInfo = donationRes.Item || {};
      }

      // 태스크 정보 조회 (현재 진행 상태 등)
      if (match.task_id) {
        const taskRes = await ddbDocClient.send(new GetCommand({
          TableName: TASK_TABLE_NAME,
          Key: { task_id: match.task_id }
        }));
        taskInfo = taskRes.Item || {};
      }

      // 3. PDF 명세서 1.2.11 Response Body 형식에 맞춰 데이터 구성
      return {
        task_id: match.task_id,
        match_id: match.match_id,
        status: taskInfo.status || match.status, // task 테이블의 상태를 우선
        
        // Donation 테이블에서 가져온 정보
        donation_id: match.donation_id,
        donation_item_name: donationInfo.item_name || "정보 없음",
        donation_category: donationInfo.category || "정보 없음",
        donation_quantity: donationInfo.quantity || 0,
        donation_expiration_date: donationInfo.expiration_date || "",
        
        // (추가 가능) Recipient 정보 등은 recipient-service와 연동하거나
        // match 테이블에 recipient_name이 스냅샷으로 저장되어 있다면 사용
        recipient_id: match.recipient_id,
        
        confirmed_at: match.confirmed_at
      };
    }));

    return apiResponse(200, {
      status: "success",
      message: "봉사 내역 조회 성공",
      data: { task_list: detailedTasks }
    });

  } catch (error) {
    console.error("봉사 내역 조회 오류:", error);
    return apiResponse(500, { message: "서버 오류", error: error.message });
  }
};

/**
 * 1.2.10 (혹은 1.2.12) 봉사 완료 처리
 * Table: task (status 업데이트)
 */
export const completeTask = async (event) => {
  try {
    const method =
      event.requestContext?.http?.method || // HTTP API (v2)
      event.httpMethod; // REST API (v1)

    if (method === "OPTIONS") {
      return apiResponse(200, {
        status: "success",
        message: "CORS preflight OK",
        data: null,
      });
    }

    const taskId = event.pathParameters.taskId; 
    const body = JSON.parse(event.body);
    const claims = getClaims(event);
    const cognitoId = claims?.sub;

    if (body.status !== "COMPLETED") {
      return apiResponse(400, { message: "status는 'COMPLETED'여야 합니다." });
    }

    const getParams = {
      TableName: TASK_TABLE_NAME,
      Key: { task_id: taskId },
    };
    const { Item: task } = await ddbDocClient.send(new GetCommand(getParams));

    if (!task) {
      return apiResponse(404, { message: "해당 작업을 찾을 수 없습니다." });
    }

    const myVolunteerId = await getVolunteerIdByCognito(cognitoId);
    
    // 본인 확인
    if (task.volunteer_id !== myVolunteerId) {
      return apiResponse(403, { message: "이 작업에 대한 권한이 없습니다." });
    }

    // 상태 업데이트
    const updateParams = {
      TableName: TASK_TABLE_NAME,
      Key: { task_id: taskId },
      UpdateExpression: "SET #status = :status, completed_at = :completed_at",
      ExpressionAttributeNames: { "#status": "status" },
      ExpressionAttributeValues: {
        ":status": "COMPLETED",
        ":completed_at": new Date().toISOString()
      },
      ReturnValues: "ALL_NEW"
    };

    const { Attributes } = await ddbDocClient.send(new UpdateCommand(updateParams));

    return apiResponse(200, {
      status: "COMPLETED",
      message: "봉사가 완료되었습니다.",
      data: Attributes
    });

  } catch (error) {
    console.error("봉사 완료 처리 오류:", error);
    return apiResponse(500, { message: "서버 오류", error: error.message });
  }
};

// === 메인 핸들러 (라우터) ===
// Lambda 핸들러를 "volunteer.handler" 로 설정하면
// 이 함수 하나로 volunteer 관련 모든 API를 처리할 수 있습니다.
export const handler = async (event) => {
  console.log("EVENT:", JSON.stringify(event));

  // 공통 메서드 / 경로 처리 (REST v1 / HTTP API v2 모두 지원)
  const method =
    event.requestContext?.http?.method || // HTTP API (v2)
    event.httpMethod; // REST API (v1)

  let path =
    event.requestContext?.http?.path || // HTTP API (v2)
    event.path; // REST API (v1)

  // Trailing slash 제거 (예: /volunteer/profile/ -> /volunteer/profile)
  if (path && path.endsWith("/") && path.length > 1) {
    path = path.slice(0, -1);
  }

  console.log(`[Volunteer] Method: ${method}, Path: ${path}`);

  // CORS preflight 공통 처리
  if (method === "OPTIONS") {
    return apiResponse(200, {
      status: "success",
      message: "CORS preflight OK",
      data: null,
    });
  }

  try {
    // 1) 자원봉사자 프로필 생성: POST /v0/volunteer/profile
    if (method === "POST" && path.endsWith("/volunteer/profile")) {
      return await createProfile(event);
    }

    // 2) 등록된 기부 목록 조회:
    //    GET /v0/volunteer/donations 또는 /v0/volunteer/donationList 둘 다 지원
    if (
      method === "GET" &&
      (path.endsWith("/volunteer/donations") ||
        path.endsWith("/volunteer/donationList"))
    ) {
      return await getDonationList(event);
    }

    // 3) 자신의 봉사 내역 조회: GET /v0/volunteer/tasks
    if (method === "GET" && path.endsWith("/volunteer/tasks")) {
      return await getTaskHistory(event);
    }

    // 4) 봉사 완료 처리:
    //    POST 또는 PUT /v0/volunteer/tasks/{taskId}
    if (
      (method === "POST" || method === "PUT") &&
      path.includes("/volunteer/tasks/")
    ) {
      // pathParameters에 taskId가 없으면 path에서 추출해서 보완
      if (!event.pathParameters?.taskId) {
        const segments = path.split("/");
        const taskId = segments[segments.length - 1];
        event = {
          ...event,
          pathParameters: { ...(event.pathParameters || {}), taskId },
        };
      }
      return await completeTask(event);
    }

    // 매칭되는 라우트가 없는 경우
    console.warn(`[Volunteer] No route matched for: ${method} ${path}`);
    return apiResponse(404, {
      status: "error",
      message: `경로를 찾을 수 없습니다. (${method} ${path})`,
    });
  } catch (error) {
    console.error("[Volunteer] Unhandled error:", error);
    return apiResponse(500, {
      status: "error",
      message: "서버 오류",
      error: error.message,
    });
  }
};
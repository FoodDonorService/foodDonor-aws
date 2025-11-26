// AWS SDK v3 (ES Module) 임포트
import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, PutCommand, GetCommand, QueryCommand, ScanCommand } from "@aws-sdk/lib-dynamodb";
import { SQSClient, SendMessageCommand } from "@aws-sdk/client-sqs";
import { AthenaClient, StartQueryExecutionCommand, GetQueryExecutionCommand, GetQueryResultsCommand } from "@aws-sdk/client-athena";
import { randomUUID } from "crypto"; // 내장 crypto 모듈에서 UUID 생성기 임포트

// --- AWS 클라이언트 초기화 ---
// 리전(region)은 Lambda 실행 환경에서 자동으로 설정됩니다.
const ddbClient = new DynamoDBClient({});
const ddbDocClient = DynamoDBDocumentClient.from(ddbClient);
const sqsClient = new SQSClient({});
const athenaClient = new AthenaClient({});

// --- 환경 변수 (하드코딩) ---
const DONOR_PROFILE_TABLE = "donor"; // 기부자 = Restaurant이므로 이 테이블에 restaurants 정보 모두 저장
const DONATION_TABLE = "donation";
const DONATION_MATCH_QUEUE_URL = "https://sqs.ap-northeast-2.amazonaws.com/436471025878/food-donor-match-queue-v1"; // SQS 큐 URL
const ATHENA_DATABASE = "food_donor_db"; // Athena 데이터베이스
const ATHENA_WORKGROUP = "primary"; // Athena 워크그룹
const ATHENA_OUTPUT_LOCATION = "s3://food-donor-athena-results-v1/"; // S3 출력 위치

// === 1. 기부자 프로필 생성 (회원가입) ===
// POST /donor/profile
async function createDonorProfile(body, authorizerClaims) {
  try {
    // Cognito Authorizer가 검증한 토큰에서 사용자 정보(sub, email) 추출
    const donor_id = authorizerClaims.sub; // Cognito가 발급한 고유 ID (PK)
    const email = authorizerClaims.email;
    const { name } = body; // post_number, address, phone_number는 restaurants 데이터에서만 가져옴

    const createdAt = new Date().toISOString();

    const profileItem = {
      donor_id: donor_id,
      email: email,
      name: name,
      created_at: createdAt
    };

    // 🆕 기부자 = Restaurant이므로, name(음식점명)으로 Athena에서 restaurants 데이터 조회하여 기부자 프로필에 저장
    try {
      const restaurantData = await findAndSaveRestaurant(name);
      if (restaurantData) {
        console.log(`Restaurant data found: ${JSON.stringify(restaurantData)}`);
        // restaurants 데이터의 모든 필드를 기부자 프로필에 저장
        profileItem.id = restaurantData.id; // restaurants의 id
        profileItem.post_number = restaurantData.post_number || null; // restaurants 데이터에서만 가져옴
        profileItem.address = restaurantData.address || null; // restaurants 데이터에서만 가져옴
        profileItem.phone_number = restaurantData.phone_number || null; // restaurants 데이터에서만 가져옴
        
        // longitude와 latitude는 문자열이므로 숫자로 변환 (빈 문자열이나 null 체크)
        const longitude = parseFloat(restaurantData.longitude);
        const latitude = parseFloat(restaurantData.latitude);
        console.log(`Parsed coordinates - longitude: ${longitude}, latitude: ${latitude}, original: ${restaurantData.longitude}, ${restaurantData.latitude}`);
        if (!isNaN(longitude) && !isNaN(latitude)) {
          profileItem.longitude = longitude;
          profileItem.latitude = latitude;
          console.log(`Coordinates saved to profile: ${longitude}, ${latitude}`);
        } else {
          console.warn(`Invalid coordinates - longitude: ${restaurantData.longitude}, latitude: ${restaurantData.latitude}`);
        }
        
        profileItem.type = restaurantData.type; // 위생업태명
        profileItem.district = restaurantData.district; // 구 이름
        profileItem.partition_date = restaurantData.partition_date; // 파티션 날짜
      } else {
        console.warn(`No restaurant data found for name: ${name}`);
      }
    } catch (error) {
      console.warn("Restaurant matching failed (non-critical):", error.message);
      // restaurants 매칭 실패는 프로필 생성을 막지 않음
    }

    // DynamoDB에 프로필 저장 (restaurants 데이터 포함)
    const command = new PutCommand({
      TableName: DONOR_PROFILE_TABLE,
      Item: profileItem,
    });
    await ddbDocClient.send(command);

    // 명세서와 동일한 응답 반환
    return createResponse(200, {
      status: "success",
      message: "기부자 프로필이 성공적으로 생성되었습니다.",
      data: profileItem
    });

  } catch (error) {
    console.error("Error creating donor profile:", error);
    return createResponse(500, { status: "error", message: "서버 오류", detail: error.message });
  }
}

// === 2. 기부 등록 ===
// POST /donor/donation
async function createDonation(body, authorizerClaims) {
  try {
    const donor_id = authorizerClaims.sub;
    const { category, item_name, quantity, expiration_date } = body;

    // donation_id 생성 (UUID 사용)
    const donation_id = randomUUID();

    // 기부 등록 시, 기부자의 위치 정보(주소)가 필요 (1.2.9 로직을 위해)
    // 1. 기부자 프로필 조회
    const profile = await getDonorProfile(donor_id);
    if (!profile) {
      return createResponse(404, { status: "error", message: "기부자 프로필을 찾을 수 없습니다." });
    }

    // 2. 프로필에 저장된 좌표 정보 사용 (restaurants 데이터에서 가져온 값)
    // 숫자로 변환하여 체크 (문자열이나 빈 값도 체크)
    console.log(`Profile data: ${JSON.stringify({ longitude: profile.longitude, latitude: profile.latitude })}`);
    const longitude = parseFloat(profile.longitude);
    const latitude = parseFloat(profile.latitude);
    console.log(`Parsed coordinates from profile - longitude: ${longitude}, latitude: ${latitude}`);
    
    if (isNaN(longitude) || isNaN(latitude)) {
      console.error(`Invalid coordinates in profile - longitude: ${profile.longitude}, latitude: ${profile.latitude}`);
      return createResponse(400, { 
        status: "error", 
        message: "기부자 프로필에 위치 정보(위도/경도)가 없습니다. restaurants 데이터가 매칭되지 않았을 수 있습니다." 
      });
    }

    // 3. 가장 가까운 오전 9시, 오후 1시 2개를 수령시간으로 설정
    const pickupTimes = getNextPickupTimes();
    
    const donationItem = {
      donation_id: donation_id,
      donor_id: donor_id,       // GSI 파티션 키
      category: category,
      item_name: item_name,
      quantity: quantity,
      expiration_date: expiration_date,
      status: "PENDING", // 기부 등록 시 초기 상태
      created_at: new Date().toISOString(),
      latitude: latitude,
      longitude: longitude,
      pickup_times: pickupTimes // 수령 가능한 시간 배열 (ISO 8601 형식)
    };

    // DynamoDB에 기부 내역 저장
    const command = new PutCommand({
      TableName: DONATION_TABLE,
      Item: donationItem,
    });
    await ddbDocClient.send(command);

    // 명세서와 동일한 응답 반환
    return createResponse(200, {
      status: "success",
      message: "기부 품목이 성공적으로 등록되었습니다.",
      data: {
        donation_id: donation_id // 생성된 숫자 ID 반환
      }
    });

  } catch (error) {
    console.error("Error creating donation:", error);
    return createResponse(500, { status: "error", message: "서버 오류", detail: error.message });
  }
}


// === 3. 자원봉사자 → 등록된 기부 목록 조회 ===
// GET /donor/donationList
async function getDonationList(authorizerClaims) {
  try {
    // 모든 등록된 기부 목록 조회 (status가 PENDING인 것만)
    const command = new ScanCommand({
      TableName: DONATION_TABLE,
      FilterExpression: "#status = :status",
      ExpressionAttributeNames: {
        "#status": "status"
      },
      ExpressionAttributeValues: {
        ":status": "PENDING"
      }
    });
    
    const { Items } = await ddbDocClient.send(command);
    
    // 현재 시간 기준 가장 가까운 수령시간 계산
    const currentPickupTime = getCurrentPickupTime();
    
    // 해당 수령시간에 해당하는 donation만 필터링
    const filteredItems = Items.filter(item => {
      if (!item.pickup_times || !Array.isArray(item.pickup_times)) {
        return false;
      }
      // pickup_times 배열에 현재 수령시간이 포함되어 있는지 확인
      return item.pickup_times.includes(currentPickupTime);
    });
    
    // 명세서 형식에 맞게 데이터 가공 (restaurant 정보 포함)
    const donation_list = await Promise.all(filteredItems.map(async (item) => {
      // donor(restaurant) 정보 조회
      const donorInfo = await getDonorProfile(item.donor_id);
      
      return {
        donation_id: item.donation_id,
        restaurant_name: donorInfo?.name || null,
        restaurant_post_number: donorInfo?.post_number || null,
        restaurant_address: donorInfo?.address || null,
        donation_item_name: item.item_name,
        donation_category: item.category,
        donation_quantity: item.quantity,
        donation_expiration_date: item.expiration_date,
        status: item.status?.toLowerCase() || "pending"
      };
    }));
    
    // 명세서와 동일한 응답 반환
    return createResponse(200, {
      status: "success",
      message: "등록된 기부 목록 조회 성공",
      data: {
        donation_list: donation_list
      }
    });

  } catch (error) {
    console.error("Error getting donation list:", error);
    return createResponse(500, { status: "error", message: "서버 오류", detail: error.message });
  }
}

// === 4. 기부자 → 자신의 기부 내역 조회 ===
// GET /donor/donorList
async function getMyDonationList(authorizerClaims) {
  try {
    const donor_id = authorizerClaims.sub;

    // GSI가 없으므로 Scan으로 전체 테이블을 스캔하고 donor_id로 필터링
    const command = new ScanCommand({
      TableName: DONATION_TABLE,
      FilterExpression: "donor_id = :donor_id",
      ExpressionAttributeValues: {
        ":donor_id": donor_id
      }
    });
    
    const { Items } = await ddbDocClient.send(command);
    
    // 명세서 형식에 맞게 데이터 가공
    const donation_list = Items.map(item => ({
      category: item.category,
      item_name: item.item_name,
      quantity: item.quantity,
      status: item.status
    }));
    
    // 명세서와 동일한 응답 반환
    return createResponse(200, {
      status: "success",
      message: "기부 내역을 성공적으로 조회했습니다.",
      data: {
        donation_list: donation_list
      }
    });

  } catch (error) {
    console.error("Error getting my donation list:", error);
    return createResponse(500, { status: "error", message: "서버 오류", detail: error.message });
  }
}

// === 5. 자원봉사자 → 봉사할 음식점 선택 (SQS) ===
// POST /donor/tasks
async function requestDonationTask(body, authorizerClaims) {
  try {
    // 요청자는 '자원봉사자'
    const volunteer_id = authorizerClaims.sub;
    const { donation_id } = body; // 예: 11 (숫자)

    // 1. 작업 ID (UUID) 생성
    const task_id = randomUUID();

    // 2. DynamoDB에서 기부(Donation) 정보 조회 (위치 정보를 얻기 위해)
    const getCommand = new GetCommand({
      TableName: DONATION_TABLE,
      Key: {
        donation_id: donation_id // PK로 조회 (숫자)
      }
    });
    const { Item: donation } = await ddbDocClient.send(getCommand);

    if (!donation) {
      return createResponse(404, { status: "error", message: "해당 기부 건을 찾을 수 없습니다." });
    }

    // 3. SQS 메시지 생성 (명세서 로직 기반)
    const sqsMessageBody = {
      task_id: task_id,
      volunteer_id: volunteer_id, // 이 작업을 요청한 봉사자 ID
      donation_id: donation.donation_id,
      latitude: donation.latitude || null,
      longitude: donation.longitude || null,
      donation_name: donation.item_name
    };

    // 4. SQS 큐로 메시지 전송
    const sqsCommand = new SendMessageCommand({
      QueueUrl: DONATION_MATCH_QUEUE_URL,
      MessageBody: JSON.stringify(sqsMessageBody),
    });
    await sqsClient.send(sqsCommand);

    // 5. 명세서에 따라 즉시 202 (Accepted) 응답 반환
    const responseBody = {
      task_id: task_id,
      status: "PENDING",
      message: "매칭 작업을 SQS에 전달했습니다. 3초 후 GET /recipient/tasks/{task_id}로 결과를 조회하세요."
    };
    
    // 202 상태 코드는 'body'만 반환 (명세서 기준)
    return createResponse(202, responseBody);

  } catch (error) {
    console.error("Error requesting donation task:", error);
    return createResponse(500, { status: "error", message: "서버 오류", detail: error.message });
  }
}

// === 헬퍼 함수 ===

// 공통 응답 생성기
function createResponse(statusCode, body) {
  return {
    statusCode: statusCode,
    headers: {
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Headers": "Content-Type,Authorization,X-Amz-Date,X-Api-Key,X-Amz-Security-Token",
      "Access-Control-Allow-Methods": "OPTIONS,POST,GET,PUT,DELETE"
    },
    body: JSON.stringify(body)
  };
}

// 헬퍼: 기부자 프로필 조회
async function getDonorProfile(donor_id) {
  const command = new GetCommand({
    TableName: DONOR_PROFILE_TABLE,
    Key: { donor_id: donor_id }
  });
  const { Item } = await ddbDocClient.send(command);
  return Item;
}

// 헬퍼: 가장 가까운 오전 9시, 오후 1시 2개 반환
function getNextPickupTimes() {
  const now = new Date();
  const today = new Date(now);
  today.setHours(0, 0, 0, 0);
  
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  // 오늘과 내일의 9시, 13시 생성
  const candidates = [
    new Date(today.getTime() + 9 * 60 * 60 * 1000), // 오늘 9시
    new Date(today.getTime() + 13 * 60 * 60 * 1000), // 오늘 13시
    new Date(tomorrow.getTime() + 9 * 60 * 60 * 1000), // 내일 9시
    new Date(tomorrow.getTime() + 13 * 60 * 60 * 1000) // 내일 13시
  ];
  
  // 현재 시간 이후의 시간만 필터링하고 정렬
  const futureTimes = candidates
    .filter(time => time > now)
    .sort((a, b) => a - b)
    .slice(0, 2); // 가장 가까운 2개만 선택
  
  // ISO 8601 형식으로 변환
  return futureTimes.map(time => time.toISOString());
}

// 헬퍼: 현재 시간 기준 가장 가까운 수령시간 계산
function getCurrentPickupTime() {
  const now = new Date();
  const today = new Date(now);
  today.setHours(0, 0, 0, 0);
  
  const tomorrow = new Date(today);
  tomorrow.setDate(tomorrow.getDate() + 1);
  
  // 오늘과 내일의 9시, 13시 생성
  const candidates = [
    new Date(today.getTime() + 9 * 60 * 60 * 1000), // 오늘 9시
    new Date(today.getTime() + 13 * 60 * 60 * 1000), // 오늘 13시
    new Date(tomorrow.getTime() + 9 * 60 * 60 * 1000), // 내일 9시
    new Date(tomorrow.getTime() + 13 * 60 * 60 * 1000) // 내일 13시
  ];
  
  // 현재 시간 이후의 가장 가까운 시간 찾기
  const nextTime = candidates
    .filter(time => time > now)
    .sort((a, b) => a - b)[0];
  
  return nextTime ? nextTime.toISOString() : null;
}


// 헬퍼: Athena에서 restaurants 조회 및 매칭
async function findAndSaveRestaurant(restaurantName) {
  try {
    // NFD/NFC 정규화 (자소 분리 문제 해결)
    const normalizedName = restaurantName.normalize('NFC');
    
    // 입력값의 공백을 제거하고, 쿼리에도 trim()과 lower()를 적용
    const escapedName = normalizedName.replace(/'/g, "''").trim();
    
    // 🚨 [최종 수정] 타임스탬프 주석을 추가하여 Athena 캐시를 강제로 무시합니다.
    // 쿼리가 매번 달라지므로 Athena는 S3를 다시 스캔할 수밖에 없습니다.
    const cacheBuster = `/* ${new Date().toISOString()} */`;
    
    const query = `SELECT id, name, post_number, address, phone_number, longitude, latitude, type, partition_date, district 
                   FROM "${ATHENA_DATABASE}"."restaurants" 
                   WHERE lower(trim(name)) LIKE lower('%${escapedName}%') 
                   ${cacheBuster}
                   LIMIT 1`;
    
    console.log(`Executing CACHE-BUSTING Athena query (using timestamp)`);
    console.log(`Query: ${query}`);
    
    const startCommand = new StartQueryExecutionCommand({
      QueryString: query,
      QueryExecutionContext: {
        Database: ATHENA_DATABASE
      },
      ResultConfiguration: {
        OutputLocation: ATHENA_OUTPUT_LOCATION
      },
      WorkGroup: ATHENA_WORKGROUP
    });
    
    const startResponse = await athenaClient.send(startCommand);
    const queryExecutionId = startResponse.QueryExecutionId;
    
    if (!queryExecutionId) {
      throw new Error("Failed to start Athena query");
    }
    
    // 쿼리 완료 대기 (최대 30초)
    let queryStatus = "RUNNING";
    let attempts = 0;
    const maxAttempts = 30; 
    
    while (queryStatus === "RUNNING" && attempts < maxAttempts) {
      await new Promise(resolve => setTimeout(resolve, 1000)); // 1초 대기
      
      const statusCommand = new GetQueryExecutionCommand({
        QueryExecutionId: queryExecutionId
      });
      
      const statusResponse = await athenaClient.send(statusCommand);
      queryStatus = statusResponse.QueryExecution?.Status?.State;
      
      // 실패 상태인 경우 에러 정보 로깅
      if (queryStatus === "FAILED" || queryStatus === "CANCELLED") {
        const errorMessage = statusResponse.QueryExecution?.Status?.StateChangeReason || "Unknown error";
        const errorDetails = statusResponse.QueryExecution?.Status?.AthenaError;
        console.error(`Athena query failed - Status: ${queryStatus}, Reason: ${errorMessage}`, errorDetails);
        throw new Error(`Athena query failed with status: ${queryStatus}. Reason: ${errorMessage}`);
      }
      
      attempts++;
    }
    
    if (queryStatus !== "SUCCEEDED") {
      const statusCommand = new GetQueryExecutionCommand({
        QueryExecutionId: queryExecutionId
      });
      const statusResponse = await athenaClient.send(statusCommand);
      const errorMessage = statusResponse.QueryExecution?.Status?.StateChangeReason || "Unknown error";
      console.error(`Athena query failed - Status: ${queryStatus}, Reason: ${errorMessage}`);
      throw new Error(`Athena query failed with status: ${queryStatus}. Reason: ${errorMessage}`);
    }
    
    // 🚨 [수정] MaxResults를 2로 변경 (헤더 1줄 + 데이터 1줄)
    const resultsCommand = new GetQueryResultsCommand({
      QueryExecutionId: queryExecutionId,
      MaxResults: 2
    });
    
    const resultsResponse = await athenaClient.send(resultsCommand);
    
    // 결과 파싱
    if (!resultsResponse.ResultSet?.Rows || resultsResponse.ResultSet.Rows.length < 2) {
      console.warn(`No restaurant found with name: ${restaurantName} (normalized: ${normalizedName})`);
      console.log(`ResultSet rows count: ${resultsResponse.ResultSet?.Rows?.length || 0}`);
      return null;
    }
    
    // 첫 번째 행은 헤더, 두 번째 행이 데이터
    const headerRow = resultsResponse.ResultSet.Rows[0].Data;
    const dataRow = resultsResponse.ResultSet.Rows[1].Data;
    
    const restaurant = {};
    headerRow.forEach((header, index) => {
      const columnName = header.VarCharValue;
      const value = dataRow[index]?.VarCharValue || null;
      restaurant[columnName] = value;
    });
    
    console.log(`Found restaurant: ${JSON.stringify(restaurant)}`);
    
    // 기부자 = Restaurant이므로 별도 테이블에 저장하지 않고, 
    // 기부자 프로필에 직접 저장됨 (createDonorProfile에서 처리)
    
    return restaurant;
    
  } catch (error) {
    console.error("Error finding restaurant from Athena:", error);
    throw error;
  }
}


// === 메인 핸들러 (라우터) ===
export const handler = async (event) => {
  console.log("Received event:", JSON.stringify(event, null, 2));

  // API Gateway 프록시 통합에서 라우팅 정보 추출
  const method = event.httpMethod;
  const path = event.resource; // API Gateway에 설정된 리소스 경로 (예: /donor/profile)
  
  // 'event.body'는 문자열이므로 JSON으로 파싱
  const body = event.body ? JSON.parse(event.body) : {};

  // Cognito Authorizer가 전달한 사용자 클레임 (JWT 페이로드)
  // 'claims'가 없으면 인증 실패
  const authorizerClaims = event.requestContext?.authorizer?.claims;
  
  if (!authorizerClaims) {
      return createResponse(401, { status: "error", message: "인증되지 않은 요청입니다." });
  }
  
  // --- 라우팅 ---
  try {
    if (method === "POST" && path === "/donor/profile") {
      return await createDonorProfile(body, authorizerClaims);
    }

    if (method === "POST" && path === "/donor/donation") {
      return await createDonation(body, authorizerClaims);
    }
    
    if (method === "GET" && path === "/donor/donationList") {
      return await getDonationList(authorizerClaims);
    }
    
    if (method === "GET" && path === "/donor/donorList") {
      return await getMyDonationList(authorizerClaims);
    }
    
    if (method === "POST" && path === "/donor/tasks") {
      return await requestDonationTask(body, authorizerClaims);
    }
    
    // 일치하는 라우트 없음
    return createResponse(404, { status: "error", message: "경로를 찾을 수 없습니다 (Not Found)." });

  } catch (error) {
    console.error("Unhandled error in handler:", error);
    return createResponse(500, { status: "error", message: "핸들러에서 처리되지 않은 오류 발생", detail: error.message });
  }
};
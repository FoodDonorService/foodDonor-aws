import { DynamoDBClient } from "@aws-sdk/client-dynamodb";
import { DynamoDBDocumentClient, GetCommand } from "@aws-sdk/lib-dynamodb";

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

// 공통 응답 포맷 (status, message, data)
function createApiResponse(status, message, data = null) {
  // status에 따라 statusCode 결정
  let statusCode = 200;
  if (status === "error" || status === "Unauthorized") {
    statusCode = status === "Unauthorized" ? 401 : 500;
  } else if (status === "NOT_FOUND") {
    statusCode = 404;
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

export const handler = async (event) => {
  console.log("Event Received:", JSON.stringify(event));

  try {
    // 1. API Gateway Authorizer에서 Cognito 정보 추출
    const authorizer = event.requestContext?.authorizer;
    const claims = authorizer?.jwt?.claims || authorizer?.claims;

    if (!claims) {
      return createApiResponse("Unauthorized", "인증 토큰 정보가 없습니다 (Unauthorized).");
    }

    const cognitoId = claims.sub; // Cognito 고유 ID
    const email = claims.email;   // 이메일

    // 2. 3개 테이블 병렬 조회
    const [donorResult, volunteerResult, recipientResult] = await Promise.all([
      findUserInTable("donor", "donor_id", cognitoId),
      findUserInTable("volunteer", "volunteer_id", cognitoId),
      findUserInTable("recipient", "recipient_id", cognitoId),
    ]);

    // 3. 결과 확인 및 역할 할당
    let foundUser = null;
    let role = "";

    if (donorResult) {
      foundUser = donorResult;
      role = "donor";
    } else if (volunteerResult) {
      foundUser = volunteerResult;
      role = "volunteer";
    } else if (recipientResult) {
      foundUser = recipientResult;
      role = "recipient";
    }

    // 4. 결과 반환 (status, message, data 구조)
    if (foundUser) {
      const userData = {
        id: cognitoId,
        email: email,
        name: foundUser.name,
        role: role,
        // 필요시 추가 정보 (address 등)도 여기에 포함
        // ...foundUser 
      };

      return createApiResponse("success", "사용자 프로필을 성공적으로 조회했습니다.", userData);

    } else {
      // 3개 테이블 어디에도 없는 경우
      return createApiResponse("NOT_FOUND", "해당 계정으로 생성된 프로필이 존재하지 않습니다.");
    }

  } catch (error) {
    console.error("Error:", error);
    return createApiResponse("error", "서버 내부 오류가 발생했습니다.", { error: error.message });
  }
};

// 헬퍼 함수: 특정 테이블 조회
async function findUserInTable(tableName, pkName, id) {
  const params = {
    TableName: tableName,
    Key: { [pkName]: id },
  };

  try {
    const command = new GetCommand(params);
    const result = await docClient.send(command);
    return result.Item || null;
  } catch (error) {
    console.error(`Error querying ${tableName}:`, error);
    return null; 
  }
}

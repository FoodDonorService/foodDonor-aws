# Food Donor Platform - Infrastructure as Code

> AWS 서버리스 아키텍처를 Terraform으로 관리하는 인프라 레포지토리

## 📋 프로젝트 개요

이 레포지토리는 **Food Donor Platform**의 AWS 인프라를 Terraform으로 정의하고 관리합니다. 다른 AWS 계정의 콘솔로 만든 레거시 인프라를 **Former2**로 리버스 엔지니어링한 후, 배포 가능한 Terraform 코드로 리팩토링했습니다.

### 🎯 주요 특징

- **Infrastructure as Code**: 모든 AWS 리소스를 Terraform으로 정의
- **모듈화된 구조**: 재사용 가능한 모듈로 구성 (storage, database, compute, integration, security)
- **서버리스 아키텍처**: Lambda, DynamoDB, S3, API Gateway 등 서버리스 서비스 활용
- **State 관리**: S3 + DynamoDB Backend로 State 파일 관리 및 락킹
- **로컬 소스 코드**: Lambda 함수 소스 코드를 로컬에서 관리 (`services/` 폴더)

### 📦 레포지토리 구조

이 레포지토리는 **인프라 코드**를 관리합니다. 애플리케이션 소스 코드는 현재 `services/` 폴더에 포함되어 있지만, **추후 별도 레포지토리로 분리하여 CI/CD 파이프라인을 구축할 예정**입니다.

```
foodDonor-aws/                    # 인프라 레포지토리 (현재)
├── 📄 Terraform 인프라 파일
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── provider.tf
│   └── backend.tf
├── 📁 modules/                   # 재사용 가능한 모듈
│   ├── storage/                  # S3 Buckets
│   ├── database/                 # DynamoDB & Glue
│   ├── compute/                  # Lambda Functions
│   ├── integration/              # API Gateway & SQS
│   └── security/                 # IAM & Cognito
├── 📁 services/                  # Lambda 소스 코드 (추후 분리 예정)
│   ├── aws-micro-service/
│   ├── aws-batch-process-pipeline/
│   └── aws-LLM+MCP-agent/
├── 📁 docs/                      # 인프라 문서
└── 📁 scripts/                   # 유틸리티 스크립트
```

### 🚀 빠른 시작

```bash
# 1. Terraform 초기화
terraform init

# 2. 배포 계획 확인
terraform plan

# 3. 인프라 배포
terraform apply
```

자세한 배포 가이드는 [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md)를 참고하세요.

### 🔮 향후 계획

#### Phase 1: 레포지토리 분리 및 CI/CD 구축 (예정)
- **레포지토리 분리**
  - `foodDonor-aws` (현재): Terraform 인프라 코드만 관리
  - `food-donor-services` (신규): Lambda 함수 소스 코드 관리
- **GitHub Actions CI/CD 파이프라인**
  - Lambda 함수 자동 배포 (코드 변경 시)
  - Terraform 인프라 자동 배포 (인프라 변경 시)
  - 환경별 배포 전략 (dev → staging → prod)
  - 테스트 자동화 및 보안 스캔

자세한 내용은 [CI/CD 구축 이슈](.github/ISSUE_TEMPLATE/cicd-pipeline-setup.md)를 참고하세요.

---

## 📚 인프라 아키텍처

### 기술 스택
- **컴퓨팅**: AWS Lambda (Serverless)
- **데이터베이스**: Amazon DynamoDB
- **스토리지**: Amazon S3
- **데이터 처리**: AWS Glue, Amazon Athena
- **AI/ML**: Amazon Bedrock (Claude 3 Haiku)
- **메시징**: Amazon SQS
- **인증**: Amazon Cognito
- **API**: Amazon API Gateway

### 프로젝트 구조 상세

#### 디렉토리 설명

**루트 디렉토리**: Infrastructure as Code (IaC)
- Terraform을 사용한 AWS 리소스 정의 및 관리
- 모듈화된 구조로 재사용성과 유지보수성 향상
- S3 + DynamoDB Backend로 State 관리 및 락킹

**`modules/`**: 재사용 가능한 Terraform 모듈
- `storage/`: S3 버킷 관리 (frontend, raw_data, processed_data, athena_results, terraform_state)
- `database/`: DynamoDB 테이블 및 Glue ETL Job
- `compute/`: Lambda 함수 정의 및 배포
- `integration/`: API Gateway 및 SQS 큐
- `security/`: IAM 역할/정책 및 Cognito User Pool

**`services/`**: Lambda 함수 소스 코드 (⚠️ 추후 별도 레포지토리로 분리 예정)
- `aws-micro-service/`: 마이크로서비스 Lambda 함수들 (donor, recipient, volunteer, user, location)
- `aws-batch-process-pipeline/`: 데이터 파이프라인 (ingest-trigger, glue-processor)
- `aws-LLM+MCP-agent/`: AI/ML 서비스 (Bedrock LLM)

**`docs/`**: 인프라 문서
- 배포 가이드, Backend 설정, 프로젝트 구조 등

자세한 내용은 [`docs/PROJECT_STRUCTURE.md`](docs/PROJECT_STRUCTURE.md)를 참고하세요.

---

## 2. 아키텍처 다이어그램

### 2.1 시스템 아키텍처
<img width="1313" height="873" alt="image" src="https://github.com/user-attachments/assets/9107f9c9-dc4c-43f3-a17b-be50ef8f950a" />


### 2.2 매치 시퀀스 다이어그램
<img width="2022" height="1480" alt="image" src="https://github.com/user-attachments/assets/00352303-2045-4738-a106-008ef647b99f" />

---

## 3. 인프라 구조 상세

#### 2.2.1 인프라 구조 (Terraform) - 루트 디렉토리

**모듈 구조**:
- **storage**: S3 버킷 관리 (frontend, raw_data, processed_data, athena_results, public_data, terraform_state)
- **database**: DynamoDB 테이블 (donor, recipient, volunteer, donation, volunteer_match, task) 및 Glue ETL Job
- **compute**: Lambda 함수들 (donor-service, recipient-service, volunteer-service, user-service, location-service, ingest-trigger)
- **integration**: API Gateway (HTTP API), SQS 큐 (match-queue)
- **security**: IAM 역할/정책, Cognito User Pool

**리소스 간 의존성**:
```
API Gateway → Lambda Functions → DynamoDB/S3/SQS
Lambda Functions → IAM Roles → AWS Services
Glue Job → S3 (raw_data) → S3 (processed_data) → Athena
SQS → Lambda (recipient-service) → Bedrock → DynamoDB
```

#### 2.2.2 애플리케이션 구조 (Lambda Functions)

**서비스별 책임**:
- **donor-service**: 기부자 프로필 CRUD, 기부 등록/조회, Athena 쿼리
- **recipient-service**: 수혜자 프로필 CRUD, SQS 트리거 처리, Bedrock LLM 매칭
- **volunteer-service**: 자원봉사자 프로필 CRUD, 봉사 내역 조회
- **user-service**: 사용자 역할 조회 (3개 테이블 병렬 조회)
- **location-service**: 네이버 지도 API 프록시
- **ingest-trigger**: EventBridge 스케줄러 트리거, 공공데이터 수집, Glue Job 실행

**데이터 흐름**:
```
1. 기부 등록: donor-service → DynamoDB (donation)
2. 매칭 요청: volunteer-service → SQS (match-queue)
3. 매칭 처리: SQS → recipient-service → Bedrock → DynamoDB (task)
4. 데이터 수집: EventBridge → ingest-trigger → S3 (raw_data) → Glue → S3 (processed_data)
5. 데이터 조회: donor-service → Athena → S3 (processed_data)
```

### 3.1 모듈 구조

**리소스 간 의존성**:
```
API Gateway → Lambda Functions → DynamoDB/S3/SQS
Lambda Functions → IAM Roles → AWS Services
Glue Job → S3 (raw_data) → S3 (processed_data) → Athena
SQS → Lambda (recipient-service) → Bedrock → DynamoDB
```

**서비스별 책임**:
- **donor-service**: 기부자 프로필 CRUD, 기부 등록/조회, Athena 쿼리
- **recipient-service**: 수혜자 프로필 CRUD, SQS 트리거 처리, Bedrock LLM 매칭
- **volunteer-service**: 자원봉사자 프로필 CRUD, 봉사 내역 조회
- **user-service**: 사용자 역할 조회 (3개 테이블 병렬 조회)
- **location-service**: 네이버 지도 API 프록시
- **ingest-trigger**: EventBridge 스케줄러 트리거, 공공데이터 수집, Glue Job 실행

---

## 4. 주요 서비스 구현 상세

### 4.1 기부자 서비스 (Donor Service)

#### 3.1.1 개요
기부자(음식점)의 프로필 생성, 기부 품목 등록, 기부 내역 조회 등의 기능을 제공합니다.

#### 3.1.2 주요 기능

**1) 기부자 프로필 생성**
```javascript
// donor.mjs - createDonorProfile 함수 일부
async function createDonorProfile(body, authorizerClaims) {
  const donor_id = authorizerClaims?.sub; // Cognito 고유 ID
  const email = authorizerClaims?.email;
  const { name } = body;

  const profileItem = {
    donor_id: donor_id,
    email: email,
    name: name,
    created_at: new Date().toISOString()
  };

  // Athena에서 restaurants 데이터 조회하여 프로필에 저장
  const restaurantData = await findAndSaveRestaurant(name);
  if (restaurantData) {
    profileItem.id = restaurantData.id;
    profileItem.post_number = restaurantData.post_number;
    profileItem.address = restaurantData.address;
    profileItem.phone_number = restaurantData.phone_number;
    profileItem.longitude = parseFloat(restaurantData.longitude);
    profileItem.latitude = parseFloat(restaurantData.latitude);
    profileItem.type = restaurantData.type;
    profileItem.district = restaurantData.district;
  }

  // DynamoDB에 저장
  const command = new PutCommand({
    TableName: DONOR_PROFILE_TABLE,
    Item: profileItem,
  });
  await ddbDocClient.send(command);

  return createResponse(200, {
    status: "success",
    message: "기부자 프로필이 성공적으로 생성되었습니다.",
    data: profileItem
  });
}
```

**설명**: 
- Cognito 인증을 통해 사용자 정보를 추출합니다.
- 음식점 이름으로 Athena에서 기존 음식점 데이터를 조회하여 프로필에 통합합니다.
- 위치 정보(위도/경도)를 포함하여 저장합니다.

**2) 기부 등록**
```javascript
// donor.mjs - createDonation 함수 일부
async function createDonation(body, authorizerClaims) {
  const donor_id = authorizerClaims.sub;
  const { category, item_name, quantity, expiration_date } = body;
  const donation_id = randomUUID();

  // 기부자 프로필에서 위치 정보 조회
  const profile = await getDonorProfile(donor_id);
  const longitude = parseFloat(profile.longitude);
  const latitude = parseFloat(profile.latitude);

  // 가장 가까운 수령시간 계산 (오전 9시, 오후 1시)
  const pickupTimes = getNextPickupTimes();
  
  const donationItem = {
    donation_id: donation_id,
    donor_id: donor_id,
    category: category,
    item_name: item_name,
    quantity: quantity,
    expiration_date: expiration_date,
    status: "PENDING",
    created_at: new Date().toISOString(),
    latitude: latitude,
    longitude: longitude,
    pickup_times: pickupTimes
  };

  await ddbDocClient.send(new PutCommand({
    TableName: DONATION_TABLE,
    Item: donationItem,
  }));

  return createResponse(200, {
    status: "success",
    message: "기부 품목이 성공적으로 등록되었습니다.",
    data: { donation_id: donation_id }
  });
}
```

**설명**:
- 기부 품목 정보와 함께 위치 정보를 저장합니다.
- 수령 가능한 시간을 자동으로 계산하여 저장합니다.

**3) 기부 목록 조회**
```javascript
// donor.mjs - getDonationList 함수 일부
async function getDonationList(authorizerClaims) {
  // PENDING 상태인 기부만 조회
  const command = new ScanCommand({
    TableName: DONATION_TABLE,
    FilterExpression: "#status = :status",
    ExpressionAttributeNames: { "#status": "status" },
    ExpressionAttributeValues: { ":status": "PENDING" }
  });
  
  const { Items } = await ddbDocClient.send(command);
  
  // 현재 시간 기준 가장 가까운 수령시간에 해당하는 기부만 필터링
  const currentPickupTime = getCurrentPickupTime();
  const filteredItems = Items.filter(item => {
    return item.pickup_times.includes(currentPickupTime);
  });
  
  // 기부자 정보와 병합하여 반환
  const donation_list = await Promise.all(filteredItems.map(async (item) => {
    const donorInfo = await getDonorProfile(item.donor_id);
    return {
      donation_id: item.donation_id,
      restaurant_name: donorInfo?.name || null,
      restaurant_address: donorInfo?.address || null,
      donation_item_name: item.item_name,
      donation_category: item.category,
      donation_quantity: item.quantity,
      donation_expiration_date: item.expiration_date,
      status: item.status?.toLowerCase() || "pending"
    };
  }));
  
  return createResponse(200, {
    status: "success",
    message: "등록된 기부 목록 조회 성공",
    data: { donation_list: donation_list }
  });
}
```

**설명**:
- PENDING 상태인 기부만 조회합니다.
- 현재 시간 기준 가장 가까운 수령시간에 해당하는 기부만 필터링합니다.
- 기부자 정보를 조회하여 함께 반환합니다.

---

### 4.2 수혜자 서비스 (Recipient Service)

#### 3.2.1 개요
수혜자 프로필 관리 및 AI 기반 매칭 시스템을 제공합니다. SQS를 통한 비동기 매칭 처리와 Bedrock LLM을 활용한 수혜자 추천 기능을 포함합니다.

#### 3.2.2 주요 기능

**1) 수혜자 프로필 생성**
```javascript
// recipient.mjs - POST /recipient/profile
if (httpMethod === 'POST' && path.endsWith('/recipient/profile')) {
  const newRecipient = {
    recipient_id: cognito_id, // PK
    email: email,
    name: body.name,
    phone_number: body.phone_number,
    address: body.address,
    post_number: body.post_number,
    notes: body.notes, // 알레르기 정보 등
    latitude: parseFloat(body.latitude),
    longitude: parseFloat(body.longitude),
    role: "RECIPIENT",
    created_at: new Date().toISOString()
  };

  await ddbDocClient.send(new PutCommand({
    TableName: RECIPIENT_TABLE_NAME,
    Item: newRecipient
  }));

  return createApiResponse("success", "수혜자 프로필이 성공적으로 생성되었습니다.", newRecipient);
}
```

**설명**:
- 수혜자의 기본 정보와 위치 정보를 저장합니다.
- `notes` 필드에 알레르기 정보 등을 저장하여 매칭 시 활용합니다.

**2) 매칭 요청 (SQS 전송)**
```javascript
// donor.mjs - requestDonationTask 함수
async function requestDonationTask(body, authorizerClaims) {
  const volunteer_id = authorizerClaims.sub;
  const { donation_id } = body;
  const task_id = randomUUID();

  // 기부 정보 조회
  const { Item: donation } = await ddbDocClient.send(new GetCommand({
    TableName: DONATION_TABLE,
    Key: { donation_id: donation_id }
  }));

  // SQS 메시지 생성
  const sqsMessageBody = {
    task_id: task_id,
    volunteer_id: volunteer_id,
    donation_id: donation.donation_id,
    latitude: donation.latitude,
    longitude: donation.longitude,
    donation_name: donation.item_name
  };

  // SQS 큐로 메시지 전송
  await sqsClient.send(new SendMessageCommand({
    QueueUrl: DONATION_MATCH_QUEUE_URL,
    MessageBody: JSON.stringify(sqsMessageBody),
  }));

  return createResponse(202, {
    status: "success",
    message: "매칭 작업을 SQS에 전달했습니다.",
    data: {
      task_id: task_id,
      status: "PENDING"
    }
  });
}
```

**설명**:
- 자원봉사자가 기부를 선택하면 SQS 큐에 매칭 작업을 전송합니다.
- 비동기 처리를 위해 202 (Accepted) 응답을 즉시 반환합니다.

**3) SQS 트리거 - 매칭 처리 (AI 기반)**
```javascript
// recipient.mjs - SQS 트리거 처리
if (event.Records) {
  for (const record of event.Records) {
    const message = JSON.parse(record.body);
    const { task_id, volunteer_id, donation_id, latitude, longitude, donation_name } = message;

    // Match DB에 'PROCESSING' 기록
    await ddbDocClient.send(new PutCommand({
      TableName: MATCH_TABLE_NAME,
      Item: {
        task_id: task_id,
        volunteer_id: volunteer_id,
        donation_id: donation_id,
        status: "PROCESSING",
        createdAt: new Date().toISOString(),
      }
    }));

    // 거리순 상위 5명의 수혜자 선택
    const allRecipients = await ddbDocClient.send(new ScanCommand({
      TableName: RECIPIENT_TABLE_NAME
    }));

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
      .sort((a, b) => a.distance - b.distance)
      .slice(0, 5);

    // LLM에 전송하여 최적 수혜자 추천
    const recipientsForLLM = recipientsWithDistance.map(b => ({
      id: b.recipient_id,
      name: b.name,
      phone_number: b.phone_number,
      address: b.address,
      post_number: b.post_number,
      notes: b.notes
    }));

    const systemPrompt = `당신은 AI 매칭 시스템입니다. 기부 물품과 수혜자의 notes를 고려하여 가장 적합한 수혜자를 추천하세요.`;
    
    const userPrompt = `다음과 같은 기부 물품과 거리순 상위 수혜자 목록이 있습니다.
[기부 정보]
음식: ${donation_name}
[수혜자 목록 (JSON)]
${JSON.stringify(recipientsForLLM)}

위 '수혜자 목록' 중에서 '기부 정보'와 'notes'를 고려하여 
가장 적합한 수혜자를 최대 2명까지 추천해 주세요.`;

    // Bedrock LLM 호출
    const body = JSON.stringify({
      anthropic_version: "bedrock-2023-05-31",
      messages: [{ role: "user", content: userPrompt }],
      system: systemPrompt,
      max_tokens: 1000,
      temperature: 0.1,
    });

    const bedrockResponse = await bedrockClient.send(new InvokeModelCommand({
      body,
      modelId: LLM_MODEL_ID,
      contentType: "application/json",
      accept: "application/json",
    }));

    const llmResultText = JSON.parse(new TextDecoder().decode(bedrockResponse.body)).content[0].text;
    const llmResult = JSON.parse(llmResultText);

    // Match DB에 결과 저장
    await ddbDocClient.send(new UpdateCommand({
      TableName: MATCH_TABLE_NAME,
      Key: { task_id: task_id },
      UpdateExpression: "SET #status = :status, #recList = :recList",
      ExpressionAttributeNames: { 
        "#status": "status", 
        "#recList": "recommended_list"
      },
      ExpressionAttributeValues: { 
        ":status": "COMPLETED", 
        ":recList": JSON.stringify(llmResult)
      },
    }));
  }
}
```

**설명**:
- SQS 메시지를 받아 비동기로 매칭 작업을 처리합니다.
- 하버사인 공식을 사용하여 거리순으로 상위 5명의 수혜자를 선정합니다.
- Amazon Bedrock의 Claude 3 Haiku 모델을 사용하여 기부 품목과 수혜자의 notes(알레르기 정보 등)를 고려하여 최적의 수혜자를 추천합니다.
- 결과를 DynamoDB에 저장합니다.

**4) 매칭 결과 조회**
```javascript
// recipient.mjs - GET /recipient/tasks/{task_id}
if (httpMethod === 'GET' && path.includes('/recipient/tasks/')) {
  const task_id = path.split('/').pop();
  
  const result = await ddbDocClient.send(new GetCommand({
    TableName: MATCH_TABLE_NAME,
    Key: { task_id: task_id }
  }));

  const { status, recommended_list } = result.Item;

  if (status === "COMPLETED") {
    const recommendedList = JSON.parse(recommended_list || "[]");
    
    if (recommendedList.length === 0) {
      return createApiResponse("COMPLETED", "적합한 수혜자가 없습니다.", {
        recommended_recipients: []
      });
    }
    
    // 수혜자 상세 정보 조회
    const recipientIds = recommendedList.map(item => item.id);
    const batchGetCommand = new BatchGetCommand({
      RequestItems: {
        [RECIPIENT_TABLE_NAME]: {
          Keys: recipientIds.map(id => ({ recipient_id: id }))
        }
      }
    });
    const batchResponse = await ddbDocClient.send(batchGetCommand);
    const recipientProfiles = batchResponse.Responses[RECIPIENT_TABLE_NAME] || [];

    // 데이터 병합
    const finalResponseData = recommendedList.map(item => {
      const profile = recipientProfiles.find(p => p.recipient_id === item.id);
      return {
        recipient_id: item.id,
        recipient_name: profile ? profile.name : "N/A",
        phone_number: profile ? profile.phone_number : "N/A",
        recipient_address: profile ? profile.address : "N/A",
        reason_by_mcp: item.reason_by_mcp // LLM이 제공한 추천 이유
      };
    });

    return createApiResponse("COMPLETED", "매칭작업이 완료되었습니다.", {
      recommended_recipients: finalResponseData
    });
  } else {
    return createApiResponse("PROCESSING", "매칭 작업이 아직 처리 중입니다.");
  }
}
```

**설명**:
- 폴링 방식으로 매칭 결과를 조회합니다.
- COMPLETED 상태일 경우 추천된 수혜자 목록과 LLM이 제공한 추천 이유를 반환합니다.

---

### 4.3 자원봉사자 서비스 (Volunteer Service)

#### 3.3.1 개요
자원봉사자의 프로필 관리, 기부 목록 조회, 봉사 내역 조회 등의 기능을 제공합니다.

#### 3.3.2 주요 기능

**1) 자원봉사자 프로필 생성**
```javascript
// volunteer.mjs - createProfile 함수
export const createProfile = async (event) => {
  const body = JSON.parse(event.body);
  const { name, phone_number } = body;
  const claims = getClaims(event);
  const cognitoId = claims?.sub;

  const newVolunteerId = randomUUID();
  const newProfile = {
    volunteer_id: newVolunteerId,
    cognito_id: cognitoId,
    name,
    phone_number,
    status: "ACTIVE",
    created_at: new Date().toISOString(),
  };

  await ddbDocClient.send(new PutCommand({ 
    TableName: VOLUNTEER_TABLE_NAME, 
    Item: newProfile 
  }));
  
  return apiResponse(201, newProfile);
};
```

**2) 봉사 내역 조회**
```javascript
// volunteer.mjs - getTaskHistory 함수
export const getTaskHistory = async (event) => {
  const claims = getClaims(event);
  const cognitoId = claims?.sub;
  const myVolunteerId = await getVolunteerIdByCognito(cognitoId);

  // volunteer_match 테이블에서 내 매칭 기록 조회
  const matchQuery = {
    TableName: VOLUNTEER_MATCH_TABLE_NAME,
    IndexName: GSI_MATCH_VOLUNTEER,
    KeyConditionExpression: "volunteer_id = :v_id",
    ExpressionAttributeValues: { ":v_id": myVolunteerId }
  };
  const queryResult = await ddbDocClient.send(new QueryCommand(matchQuery));
  const matches = queryResult.Items || [];

  // 상세 정보 병합 (Application-side Join)
  const detailedTasks = await Promise.all(matches.map(async (match) => {
    // 기부 정보 조회
    const donationRes = await ddbDocClient.send(new GetCommand({
      TableName: DONATION_TABLE_NAME,
      Key: { donation_id: match.donation_id }
    }));

    // 태스크 정보 조회
    const taskRes = await ddbDocClient.send(new GetCommand({
      TableName: TASK_TABLE_NAME,
      Key: { task_id: match.task_id }
    }));

    return {
      task_id: match.task_id,
      match_id: match.match_id,
      status: taskRes.Item?.status || match.status,
      donation_id: match.donation_id,
      donation_item_name: donationRes.Item?.item_name || "정보 없음",
      donation_category: donationRes.Item?.category || "정보 없음",
      recipient_id: match.recipient_id,
      confirmed_at: match.confirmed_at
    };
  }));

  return apiResponse(200, {
    status: "success",
    message: "봉사 내역 조회 성공",
    data: { task_list: detailedTasks }
  });
};
```

**설명**:
- GSI를 사용하여 자원봉사자의 매칭 기록을 조회합니다.
- Application-side Join을 통해 donation과 task 정보를 병합하여 반환합니다.

---

### 4.4 사용자 서비스 (User Service)

#### 3.4.1 개요
Cognito 인증 정보를 기반으로 사용자의 역할(donor, volunteer, recipient)을 조회합니다.

#### 3.4.2 주요 기능

```javascript
// user.mjs - handler 함수
export const handler = async (event) => {
  const authorizer = event.requestContext?.authorizer;
  const claims = authorizer?.jwt?.claims || authorizer?.claims;
  const cognitoId = claims.sub;
  const email = claims.email;

  // 3개 테이블 병렬 조회
  const [donorResult, volunteerResult, recipientResult] = await Promise.all([
    findUserInTable("donor", "donor_id", cognitoId),
    findVolunteerByCognitoId(cognitoId), // GSI 사용
    findUserInTable("recipient", "recipient_id", cognitoId),
  ]);

  // 결과 확인 및 역할 할당
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

  if (foundUser) {
    return createApiResponse("success", "사용자 프로필을 성공적으로 조회했습니다.", {
      id: cognitoId,
      email: email,
      name: foundUser.name,
      role: role,
    });
  } else {
    return createApiResponse("NOT_FOUND", "해당 계정으로 생성된 프로필이 존재하지 않습니다.");
  }
};
```

**설명**:
- Cognito ID를 사용하여 donor, volunteer, recipient 테이블을 병렬로 조회합니다.
- 가장 먼저 매칭되는 테이블의 역할을 사용자에게 할당합니다.

---

### 4.5 위치 서비스 (Location Service)

#### 3.5.1 개요
네이버 지도 API를 연동하여 위치 검색 기능을 제공합니다.

#### 3.5.2 주요 기능

```javascript
// location.mjs - handler 함수
export const handler = async (event) => {
  const queryParameters = event.queryStringParameters;
  const search_query = queryParameters.q;

  // 네이버 API 요청
  const naverQueryParams = {
    query: search_query,
    display: 5,
    start: 1,
    sort: 'random'
  };
  
  const naverRequestOptions = {
    hostname: NAVER_LOCAL_SEARCH_URL_HOST,
    path: `${NAVER_LOCAL_SEARCH_URL_PATH}?${querystring.stringify(naverQueryParams)}`,
    method: 'GET',
    headers: {
      'X-Naver-Client-Id': NAVER_CLIENT_ID,
      'X-Naver-Client-Secret': NAVER_CLIENT_SECRET
    }
  };

  // 네이버 API 호출
  const naverResult = await new Promise((resolve, reject) => {
    const req = https.request(naverRequestOptions, (res) => {
      let data = '';
      res.on('data', (chunk) => { data += chunk; });
      res.on('end', () => {
        resolve(JSON.parse(data));
      });
    });
    req.on('error', reject);
    req.end();
  });

  // 데이터 변환
  const transformed_locations = naverResult.items.map(item => ({
    latitude: parseFloat(item.mapy) / 10000000,
    longitude: parseFloat(item.mapx) / 10000000,
    location: removeHtmlTags(item.title),
    address: item.address ? item.address.trim() : '',
    roadAddress: item.roadAddress ? item.roadAddress.trim() : '',
    post_number: DEFAULT_POST_NUMBER
  }));

  return {
    statusCode: 200,
    body: JSON.stringify({
      status: 200,
      message: "지도 검색 성공",
      data: { locations: transformed_locations }
    })
  };
};
```

**설명**:
- 네이버 지도 API를 호출하여 위치 검색 결과를 가져옵니다.
- 좌표 변환 및 데이터 정제를 수행하여 반환합니다.

---

## 5. 데이터 파이프라인 구현

### 5.1 데이터 수집 (Ingest Trigger)

#### 4.1.1 개요
서울시 공공데이터 포털 API에서 음식점 데이터를 수집하여 S3에 저장합니다.

#### 4.1.2 주요 기능

```javascript
// ingest-trigger.js - handler 함수
export const handler = async (event, context) => {
  // service_key는 EventBridge 스케줄러의 입력으로 전달되며, 
  // 실제 운영 환경에서는 AWS Secrets Manager나 환경 변수로 관리 권장
  const { district_name: DISTRICT, service_key: SERVICE_KEY, api_endpoint: API_ENDPOINT } = event;
  const today = new Date().toISOString().split('T')[0];
  const s3KeyPrefix = `raw_data/${DISTRICT}/${today}/`;

  // 1. 전체 데이터 개수 확인
  const countCheckUrl = `${API_BASE_URL}/${SERVICE_KEY}/json/${API_ENDPOINT}/1/1/`;
  const countResponse = await fetch(countCheckUrl);
  const countData = await countResponse.json();
  const totalCount = countData[Object.keys(countData).find(key => key !== 'RESULT')]?.list_total_count;

  // 2. 데이터 스트리밍 및 S3에 분할 저장 (1000건씩)
  let startIndex = 1;
  let partIndex = 1;

  while (startIndex <= totalCount) {
    const endIndex = Math.min(startIndex + MAX_BATCH_SIZE - 1, totalCount);
    const apiUrl = `${API_BASE_URL}/${SERVICE_KEY}/json/${API_ENDPOINT}/${startIndex}/${endIndex}/`;
    const response = await fetch(apiUrl);

    // S3 멀티파트 업로드
    const partS3Key = `${s3KeyPrefix}part_${partIndex.toString().padStart(5, '0')}.json`;
    const parallelUploads3 = new Upload({
      client: s3Client,
      params: {
        Bucket: S3_RAW_BUCKET,
        Key: partS3Key,
        Body: response.body, // 스트림을 직접 전달
        ContentType: 'application/json'
      },
      partSize: 1024 * 1024 * 5, // 5MB 단위
      queueSize: 4
    });

    await parallelUploads3.done();
    startIndex = endIndex + 1;
    partIndex++;
  }

  // 3. Glue ETL Job 실행 트리거
  const glueS3InputPath = `s3://${S3_RAW_BUCKET}/${s3KeyPrefix}`;
  const glueParams = {
    JobName: GLUE_JOB_NAME,
    Arguments: {
      '--S3_INPUT_PATH': glueS3InputPath,
      '--DISTRICT_NAME': DISTRICT,
      '--EXECUTION_DATE': today
    }
  };

  const glueResponse = await glueClient.send(new StartJobRunCommand(glueParams));

  return {
    statusCode: 200,
    body: JSON.stringify({
      message: 'Data ingestion and streaming completed successfully',
      district: DISTRICT,
      glueJobRunId: glueResponse.JobRunId
    })
  };
};
```

**설명**:
- 서울시 공공데이터 API에서 데이터를 1000건씩 배치로 가져옵니다.
- 메모리 효율성을 위해 스트리밍 방식으로 S3에 저장합니다.
- 데이터 수집 완료 후 Glue ETL Job을 자동으로 트리거합니다.

---

### 5.2 데이터 처리 (Glue ETL)

#### 4.2.1 개요
AWS Glue를 사용하여 원본 데이터를 정제하고 Parquet 형식으로 변환하여 저장합니다.

#### 4.2.2 주요 기능

```python
# glue-processor.py
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_INPUT_PATH', 'DISTRICT_NAME', 'EXECUTION_DATE'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# S3 Raw 데이터 읽기
data_source = glueContext.create_dynamic_frame.from_options(
    format_options={"multiline": True},
    connection_type="s3",
    connection_options={"paths": [INPUT_PATH]},
    format="json",
    transformation_ctx="data_source"
)

# Spark DataFrame으로 변환
df = data_source.toDF()

# JSON 구조에서 row 배열 추출
first_column = df.columns[0]
df = df.select(explode(col(f"{first_column}.row")).alias("row_data"))
df = df.select("row_data.*")

# 데이터 정제 및 필터링
processed_df = (
    df
    # 영업 중인 데이터만 필터링
    .filter(col("DTLSTATENM") == "영업")
    
    # 컬럼명 변경
    .withColumnRenamed("MGTNO", "id")
    .withColumnRenamed("BPLCNM", "name")
    .withColumnRenamed("SNTUPTAENM", "type")
    
    # 결측치 처리
    .withColumn("post_number",
        when((col("RDNPOSTNO") == "") | col("RDNPOSTNO").isNull(), "제공안됨")
        .otherwise(col("RDNPOSTNO"))
    )
    .withColumn("address",
        when((col("RDNWHLADDR") == "") | col("RDNWHLADDR").isNull(), "제공안됨")
        .otherwise(col("RDNWHLADDR"))
    )
    
    # 전화번호 공백 제거
    .withColumn("phone_number", regexp_replace(col("SITETEL"), "\\s+", ""))
    
    # 좌표 정제
    .withColumn("longitude", trim(col("X")))
    .withColumn("latitude", trim(col("Y")))
)

# 최종 컬럼 선택
final_df = processed_df.select(
    "id", "name", "post_number", "address", 
    "phone_number", "longitude", "latitude", "type"
)

# Parquet 형식으로 저장 (파티션 포함)
processed_dyf = DynamicFrame.fromDF(final_df, glueContext, "processed_dyf")
output_path = f"s3://{S3_OUTPUT_BUCKET}/partition_date={EXECUTION_DATE}/district={DISTRICT_NAME}/"

glueContext.write_dynamic_frame.from_options(
    frame=processed_dyf,
    connection_type="s3",
    connection_options={"path": output_path},
    format="parquet",
    transformation_ctx="data_sink"
)

job.commit()
```

**설명**:
- PySpark를 사용하여 대용량 데이터를 처리합니다.
- 영업 중인 음식점만 필터링하고 데이터를 정제합니다.
- Parquet 형식으로 저장하여 Athena 쿼리 성능을 향상시킵니다.
- 날짜와 구 이름으로 파티션을 생성하여 쿼리 효율성을 높입니다.

---

### 5.3 데이터 쿼리 (Athena)

#### 4.3.1 개요
Amazon Athena를 사용하여 S3에 저장된 데이터를 SQL로 쿼리합니다.

#### 4.3.2 테이블 설정

```sql
-- athena-setting.sql
-- 데이터베이스 생성
CREATE DATABASE IF NOT EXISTS food_donor_db;

-- 외부 테이블 생성
CREATE EXTERNAL TABLE `food_donor_db`.`restaurants` (
  `id` string, 
  `name` string, 
  `post_number` string, 
  `address` string, 
  `phone_number` string, 
  `longitude` string, 
  `latitude` string, 
  `type` string
)
PARTITIONED BY ( 
  `partition_date` string, 
  `district` string
)
ROW FORMAT SERDE 
  'org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe' 
LOCATION
  's3://food-donor-processed-data-v1/'
TBLPROPERTIES (
  'classification'='parquet'
);

-- 파티션 인식
MSCK REPAIR TABLE `food_donor_db`.`restaurants`;
```

**설명**:
- S3의 Parquet 파일을 외부 테이블로 등록합니다.
- 파티션을 인식하여 쿼리 성능을 최적화합니다.

#### 4.3.3 Athena 쿼리 실행 (기부자 서비스에서)

```javascript
// donor.mjs - findAndSaveRestaurant 함수
async function findAndSaveRestaurant(restaurantName) {
  const normalizedName = restaurantName.normalize('NFC');
  const escapedName = normalizedName.replace(/'/g, "''").trim();
  
  // 캐시 무시를 위한 타임스탬프 주석 추가
  const cacheBuster = `/* ${new Date().toISOString()} */`;
  
  const query = `SELECT id, name, post_number, address, phone_number, longitude, latitude, type, partition_date, district 
                 FROM "${ATHENA_DATABASE}"."restaurants" 
                 WHERE lower(trim(name)) LIKE lower('%${escapedName}%') 
                 ${cacheBuster}
                 LIMIT 1`;
  
  // 쿼리 실행
  const startCommand = new StartQueryExecutionCommand({
    QueryString: query,
    QueryExecutionContext: { Database: ATHENA_DATABASE },
    ResultConfiguration: { OutputLocation: ATHENA_OUTPUT_LOCATION },
    WorkGroup: ATHENA_WORKGROUP
  });
  
  const startResponse = await athenaClient.send(startCommand);
  const queryExecutionId = startResponse.QueryExecutionId;
  
  // 쿼리 완료 대기 (최대 30초)
  let queryStatus = "RUNNING";
  let attempts = 0;
  while (queryStatus === "RUNNING" && attempts < 30) {
    await new Promise(resolve => setTimeout(resolve, 1000));
    const statusResponse = await athenaClient.send(new GetQueryExecutionCommand({
      QueryExecutionId: queryExecutionId
    }));
    queryStatus = statusResponse.QueryExecution?.Status?.State;
    attempts++;
  }
  
  // 결과 조회
  const resultsResponse = await athenaClient.send(new GetQueryResultsCommand({
    QueryExecutionId: queryExecutionId,
    MaxResults: 2
  }));
  
  // 결과 파싱
  const headerRow = resultsResponse.ResultSet.Rows[0].Data;
  const dataRow = resultsResponse.ResultSet.Rows[1].Data;
  
  const restaurant = {};
  headerRow.forEach((header, index) => {
    const columnName = header.VarCharValue;
    const value = dataRow[index]?.VarCharValue || null;
    restaurant[columnName] = value;
  });
  
  return restaurant;
}
```

**설명**:
- 음식점 이름으로 Athena에서 데이터를 조회합니다.
- 쿼리 완료를 폴링 방식으로 대기합니다.
- 결과를 파싱하여 반환합니다.

---

## 6. AI/ML 서비스 구현

### 6.1 Amazon Bedrock 연동

#### 5.1.1 개요
Amazon Bedrock의 Claude 3 Haiku 모델을 사용하여 수혜자 매칭 추천을 수행합니다.

#### 5.1.2 LLM 테스트 코드

```javascript
// bedrock-claude3-haiku.js - 테스트 버전
export const handler = async (event) => {
  const recipientMemo = "저는 땅콩 알레르기가 있습니다.";
  const availableItems = ["보쌈 정식", "땅콩 쿠키", "참치 샐러드", "크림빵"];

  const systemPrompt = `당신은 AI 매칭 시스템입니다. 수혜자의 안전(알레르기)을 최우선으로 고려해, 가용 품목 중 가장 적합한 메뉴 하나만 추천하세요.`;
  
  const userPrompt = `수혜자 메모: "${recipientMemo}". 가용 품목: [${availableItems.join(', ')}]. 추천 메뉴 하나와 추천 이유(10자 이내)를 JSON 형식으로 반환하세요.`;

  const body = JSON.stringify({
    anthropic_version: "bedrock-2023-05-31",
    messages: [{ role: 'user', content: userPrompt }],
    system: systemPrompt,
    max_tokens: 100,
    temperature: 0.1,
  });

  const command = new InvokeModelCommand({
    body,
    modelId: MODEL_ID,
    contentType: 'application/json',
    accept: 'application/json',
  });
  
  const response = await bedrockClient.send(command);
  const responseBody = JSON.parse(new TextDecoder().decode(response.body));
  const recommendationText = responseBody.content[0].text;

  return {
    statusCode: 200,
    body: JSON.stringify({
      status: "success",
      message: "Bedrock 연결 및 추천 테스트 완료",
      recommendation: recommendationText
    })
  };
};
```

**설명**:
- Claude 3 Haiku 모델을 사용하여 알레르기 정보를 고려한 메뉴 추천을 수행합니다.
- 낮은 temperature(0.1)를 사용하여 일관된 결과를 얻습니다.

---

## 7. 인증 및 보안

### 7.1 Amazon Cognito 설정

```javascript
// cognito-config.js
const cognitoAuthConfig = {
  authority: "https://cognito-idp.ap-northeast-2.amazonaws.com/{USER_POOL_ID}",
  client_id: "{CLIENT_ID}", // 환경 변수로 관리 권장
  redirect_uri: "{FRONTEND_URL}",
  response_type: "code",
  scope: "email openid phone",
};
```

**설명**:
- Cognito User Pool을 사용하여 사용자 인증을 처리합니다.
- OAuth 2.0 Authorization Code Flow를 사용합니다.
- **보안 주의**: 실제 운영 환경에서는 User Pool ID와 Client ID를 환경 변수나 AWS Secrets Manager로 관리해야 합니다.

### 7.2 API Gateway Authorizer

모든 Lambda 함수에서 Cognito JWT 토큰을 검증합니다:

```javascript
// 공통 패턴
const authorizer = event.requestContext?.authorizer;
const authorizerClaims = authorizer?.jwt?.claims || authorizer?.claims || {};
const cognito_id = authorizerClaims?.sub;
const email = authorizerClaims?.email;

if (!cognito_id || !email) {
  return createResponse(401, { 
    status: "error", 
    message: "인증 정보가 없습니다." 
  });
}
```

---

## 8. 데이터베이스 설계

### 8.1 DynamoDB 테이블 구조

#### 7.1.1 주요 테이블
- **donor**: 기부자 프로필 (PK: donor_id)
- **donation**: 기부 품목 (PK: donation_id, GSI: donor_id-index, status-index)
- **recipient**: 수혜자 프로필 (PK: recipient_id)
- **volunteer**: 자원봉사자 프로필 (PK: volunteer_id, GSI: cognito_id-index)
- **task**: 매칭 작업 (PK: task_id)
- **volunteer_match**: 봉사자-수혜자 매칭 (PK: match_id, GSI: volunteer_id-index)

### 8.2 데이터 흐름

1. **기부 등록**: donor → donation 테이블에 저장
2. **매칭 요청**: donation → SQS → task 테이블 (PROCESSING)
3. **매칭 처리**: recipient 조회 → Bedrock LLM → task 테이블 (COMPLETED)
4. **매칭 확정**: task → volunteer_match 테이블에 저장

---

## 9. 성능 최적화

### 9.1 비동기 처리
- SQS를 사용하여 매칭 작업을 비동기로 처리하여 API 응답 시간을 단축합니다.

### 9.2 데이터 파티셔닝
- Athena 테이블을 날짜와 구 이름으로 파티셔닝하여 쿼리 성능을 향상시킵니다.

### 9.3 Parquet 형식 사용
- Glue ETL에서 Parquet 형식으로 저장하여 스토리지 비용과 쿼리 성능을 최적화합니다.

### 9.4 GSI 활용
- DynamoDB GSI를 활용하여 다양한 쿼리 패턴을 지원합니다.

---

## 10. 배포 및 관리

### 10.1 인프라 배포
```bash
# 루트 디렉토리에서 실행
terraform init
terraform plan
terraform apply
```

자세한 배포 가이드는 [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md)를 참고하세요.

### 10.2 Lambda 함수 업데이트
Lambda 함수 소스 코드를 수정한 후:
1. 코드 변경사항 커밋
2. `terraform apply` 실행 (자동으로 zip 파일 생성 및 업로드)
3. Lambda 함수 자동 업데이트

**소스 코드 경로**: `services/aws-micro-service/*.js` → Terraform이 자동으로 패키징

### 10.3 State 관리
- **Backend**: S3 + DynamoDB로 State 파일 관리
- **락킹**: DynamoDB로 동시 작업 방지
- **버전 관리**: S3 버전 관리 활성화

자세한 내용은 [`docs/BACKEND_SETUP.md`](docs/BACKEND_SETUP.md)를 참고하세요.

---

---

## 부록: 주요 설정 및 참고 자료

### A.1 프로젝트 구조 요약

#### A.1.1 파일 구조 매핑

| 기능 | 파일 위치 | 설명 |
|------|----------|------|
| **인프라 정의** | 루트 디렉토리 | Terraform 코드로 AWS 리소스 정의 |
| **Lambda 소스** | `services/aws-micro-service/*.mjs` | 비즈니스 로직 구현 |
| **데이터 파이프라인** | `services/aws-batch-process-pipeline/` | 데이터 수집 및 처리 스크립트 |
| **AI/ML** | `services/aws-LLM+MCP-agent/` | Bedrock LLM 테스트 코드 |
| **인프라 문서** | `docs/` | 배포, 설정, 마이그레이션 가이드 |

#### A.1.2 주요 리소스 매핑

| AWS 리소스 | Terraform 모듈 | Lambda 함수 | 설명 |
|-----------|---------------|------------|------|
| DynamoDB Tables | `modules/database/dynamodb.tf` | 모든 서비스 | 사용자 데이터 저장 |
| Lambda Functions | `modules/compute/lambda.tf` | `services/aws-micro-service/` | 비즈니스 로직 실행 |
| API Gateway | `modules/integration/api-gateway.tf` | 모든 서비스 | RESTful API 엔드포인트 |
| S3 Buckets | `modules/storage/s3.tf` | `ingest-trigger`, `donor-service` | 데이터 저장 |
| Glue Job | `modules/database/glue.tf` | `services/aws-batch-process-pipeline/glue-processor.py` | 데이터 처리 |
| SQS Queue | `modules/integration/sqs.tf` | `recipient-service` | 비동기 매칭 처리 |
| Cognito | `modules/security/cognito.tf` | 모든 서비스 | 사용자 인증 |
| IAM Roles | `modules/security/iam.tf` | 모든 Lambda | 권한 관리 |

### A.2 IAM 정책 예시
각 Lambda 함수는 필요한 권한만 부여하는 최소 권한 원칙을 따릅니다:
- DynamoDB 읽기/쓰기 권한
- S3 읽기/쓰기 권한
- SQS 전송 권한
- Athena 쿼리 실행 권한
- Bedrock 모델 호출 권한

**Terraform에서의 IAM 정책 정의 위치**: `modules/security/iam.tf`

### A.3 환경 변수 및 보안
- **민감 정보 관리**: API 키, 시크릿, 인증 정보는 절대 소스코드에 하드코딩하지 않아야 합니다.
- **권장 사항**:
  - AWS Secrets Manager 또는 Systems Manager Parameter Store 사용
  - Lambda 환경 변수 활용 (암호화된 변수 사용)
  - 테이블명, 버킷명, 큐 URL 등도 환경 변수로 관리
  - Cognito User Pool ID, Client ID 등은 환경 변수로 관리
  - 네이버 API 키, 서울시 공공데이터 API 키 등은 Secrets Manager로 관리

**환경 변수 설정 위치**: `modules/compute/lambda.tf`의 `environment` 블록

### A.4 문서 가이드

- [`docs/DEPLOYMENT_GUIDE.md`](docs/DEPLOYMENT_GUIDE.md): 배포 가이드
- [`docs/BACKEND_SETUP.md`](docs/BACKEND_SETUP.md): Backend 설정 가이드
- [`docs/BACKEND_MIGRATION.md`](docs/BACKEND_MIGRATION.md): Backend 마이그레이션 가이드
- [`docs/PROJECT_STRUCTURE.md`](docs/PROJECT_STRUCTURE.md): 프로젝트 구조 설명
- [`docs/REFACTORING_SUMMARY.md`](docs/REFACTORING_SUMMARY.md): 리팩토링 요약

---

**작성일**: 2025년 1월  
**버전**: 1.0


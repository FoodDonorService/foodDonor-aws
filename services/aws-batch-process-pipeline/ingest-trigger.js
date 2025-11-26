// =======================
//   [광진구 스케줄러 입력 예시]
//   EventBridge 스케줄러의 입력(Input) 필드에 설정
// =======================
/*
{
  "district_name": "gwangjin",
  "service_key": "564c47475864617434395a714b796f",
  "api_endpoint": "LOCALDATA_072404_GJ"
}
"api_url": "http://openapi.seoul.go.kr:8088/564c47475864617434395a714b796f/json/LOCALDATA_072404_GJ/1/5/"
*/

// =======================
//   [노원구 스케줄러 입력 예시]
//   (※ 별도의 스케줄 생성, 동일 Lambda 지정)
// =======================
/*
{
  "district_name": "nowon",
  "service_key": "704558565564617436336d6371504f",
  "api_endpoint": "LOCALDATA_072404_NW"
}
"api_url": "http://openapi.seoul.go.kr:8088/704558565564617436336d6371504f/json/LOCALDATA_072404_NW/1/5/"
*/

// API 정보:
// - 광진구: http://openapi.seoul.go.kr:8088/{인증키}/json/LOCALDATA_072404_GJ/1/5/
// - 노원구: http://openapi.seoul.go.kr:8088/{인증키}/json/LOCALDATA_072404_NW/1/5/
// 참고: 서울시 공공데이터 포털 (data.seoul.go.kr)

/*
 * 이 코드는 Node.js 20.x 런타임에서 작동하며, 외부 라이브러리(npm install)가 필요 없습니다.
 * API 응답(JSON)을 1000건씩 스트리밍하여 S3에 작은 파일(_part_N.json)로 분할 저장합니다.
 * 메모리 사용량을 최소화하여 1GB가 넘는 데이터도 128MB 메모리로 처리할 수 있습니다.
 */

/*
 * (최종 수정)
 * 'Unable to calculate hash' 오류를 해결하기 위해,
 * PutObjectCommand 대신 @aws-sdk/lib-storage의 'Upload' 클래스를 사용합니다.
 * 이 'Upload' 클래스도 Lambda 런타임에 기본 내장되어 있습니다.
 */
import { S3Client } from '@aws-sdk/client-s3';
import { GlueClient, StartJobRunCommand } from '@aws-sdk/client-glue';
// PutObjectCommand 대신 lib-storage의 Upload를 임포트합니다.
import { Upload } from "@aws-sdk/lib-storage";

// --- 설정 (고정값) ---
const S3_RAW_BUCKET = "food-donor-raw-data-v1";
const GLUE_JOB_NAME = "food-donor-ETL-job-v1";
const API_BASE_URL = "http://openapi.seoul.go.kr:8088";
const MAX_BATCH_SIZE = 1000;

// AWS SDK 클라이언트 초기화
const s3Client = new S3Client({ region: process.env.AWS_REGION || 'ap-northeast-2' });
const glueClient = new GlueClient({ region: process.env.AWS_REGION || 'ap-northeast-2' });

export const handler = async (event, context) => {
    console.log('Event received:', JSON.stringify(event, null, 2));

    const { district_name: DISTRICT, service_key: SERVICE_KEY, api_endpoint: API_ENDPOINT } = event;
    
    if (!DISTRICT || !SERVICE_KEY || !API_ENDPOINT) {
        throw new Error('Missing required parameters: district_name, service_key, api_endpoint');
    }
    
    const today = new Date().toISOString().split('T')[0];
    const s3KeyPrefix = `raw_data/${DISTRICT}/${today}/`;

    try {
        // =========================================================
        // 1. 전체 데이터 개수 확인 (Step 1)
        // =========================================================
        console.log(`Step 1: Checking total data count for district: ${DISTRICT}`);
        const countCheckUrl = `${API_BASE_URL}/${SERVICE_KEY}/json/${API_ENDPOINT}/1/1/`;
        
        const countResponse = await fetch(countCheckUrl, { headers: { 'Accept': 'application/json' } });
        if (!countResponse.ok) throw new Error(`Count check API request failed: ${countResponse.status}`);
        
        const countData = await countResponse.json();
        
        const countDataKey = Object.keys(countData).find(key => key !== 'RESULT');
        if (!countDataKey) throw new Error('Unable to find data key in count response');
        
        const countDataObject = countData[countDataKey];
        if (countDataObject?.RESULT && countDataObject.RESULT.CODE !== 'INFO-000') {
            throw new Error(`API Error (Count): ${countDataObject.RESULT.MESSAGE || 'Unknown error'}`);
        }
        
        const totalCount = countDataObject?.list_total_count;
        if (!totalCount || totalCount === 0) {
            console.log('No data found for this district.');
            return { statusCode: 200, body: 'No data found, ingestion skipped.' };
        }
        
        console.log(`Total data count: ${totalCount}`);

        // =========================================================
        // 2. 데이터 스트리밍 및 S3에 분할 저장 (Step 2)
        // =========================================================
        console.log(`Step 2: Fetching and streaming all ${totalCount} records in batches of ${MAX_BATCH_SIZE}...`);
        
        let startIndex = 1;
        let partIndex = 1;
        
        while (startIndex <= totalCount) {
            const endIndex = Math.min(startIndex + MAX_BATCH_SIZE - 1, totalCount);
            console.log(`Fetching records ${startIndex} to ${endIndex}...`);
            
            const apiUrl = `${API_BASE_URL}/${SERVICE_KEY}/json/${API_ENDPOINT}/${startIndex}/${endIndex}/`;
            const response = await fetch(apiUrl, { headers: { 'Accept': 'application/json' } });
            
            if (!response.ok) throw new Error(`API request failed: ${response.status} at batch ${startIndex}`);

            // [메모리 최적화 + 해시 오류 해결]
            // PutObjectCommand 대신 S3 멀티파트 업로더 (Upload)를 사용합니다.
            
            const partS3Key = `${s3KeyPrefix}part_${partIndex.toString().padStart(5, '0')}.json`;
            console.log(`Streaming to S3: s3://${S3_RAW_BUCKET}/${partS3Key}`);

            const parallelUploads3 = new Upload({
                client: s3Client,
                params: {
                    Bucket: S3_RAW_BUCKET,
                    Key: partS3Key,
                    Body: response.body, // 스트림을 Body로 직접 전달
                    ContentType: 'application/json'
                },
                partSize: 1024 * 1024 * 5, // 5MB 단위로 조각내어 업로드
                queueSize: 4 // 동시 4개 파트 업로드
            });

            // 업로드가 완료될 때까지 기다립니다.
            await parallelUploads3.done();

            console.log(`Part ${partIndex} uploaded successfully.`);
            
            startIndex = endIndex + 1;
            partIndex++;
        }
        
        console.log(`Successfully fetched and streamed all ${totalCount} records into ${partIndex - 1} parts.`);

        // =========================================================
        // 3. Glue ETL Job 실행 트리거
        // =========================================================
        const glueS3InputPath = `s3://${S3_RAW_BUCKET}/${s3KeyPrefix}`;
        
        console.log(`Triggering Glue Job: ${GLUE_JOB_NAME} with input path: ${glueS3InputPath}`);
        
        const glueParams = {
            JobName: GLUE_JOB_NAME,
            Arguments: {
                '--S3_INPUT_PATH': glueS3InputPath,
                '--DISTRICT_NAME': DISTRICT,
                '--EXECUTION_DATE': today
            }
        };
        
        const glueResponse = await glueClient.send(new StartJobRunCommand(glueParams));
        console.log(`Glue Job started: ${glueResponse.JobRunId}`);
        
        return {
            statusCode: 200,
            body: JSON.stringify({
                message: 'Data ingestion and streaming completed successfully',
                district: DISTRICT,
                s3Folder: glueS3InputPath,
                glueJobRunId: glueResponse.JobRunId
            })
        };
        
    } catch (error) {
        console.error('Error in handler:', error);
        return {
            statusCode: 500,
            body: JSON.stringify({
                error: 'Data ingestion failed',
                message: error.message
            })
        };
    }
};
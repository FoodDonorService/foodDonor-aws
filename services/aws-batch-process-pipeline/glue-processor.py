import os
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
# PySpark의 SQL 함수 임포트 (전처리에 필수)
from pyspark.sql.functions import col, when, trim, regexp_replace, lit, explode

# 1. Lambda로부터 Job 인수를 받음
# Lambda에서 전달하는 인자: --S3_INPUT_PATH, --DISTRICT_NAME, --EXECUTION_DATE
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_INPUT_PATH', 'DISTRICT_NAME', 'EXECUTION_DATE'])

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- 설정 ---
S3_OUTPUT_BUCKET = os.environ.get("PROCESSED_DATA_BUCKET")
if not S3_OUTPUT_BUCKET:
    raise ValueError("Environment variable PROCESSED_DATA_BUCKET is required")
INPUT_PATH = args['S3_INPUT_PATH'] # Lambda가 넘겨준 원본 파일 경로
DISTRICT_NAME = args['DISTRICT_NAME'] # 구 이름 (예: "gwangjin", "nowon")
EXECUTION_DATE = args['EXECUTION_DATE'] # 파티션 생성을 위한 날짜

# =========================================================
# 2. S3 Raw 데이터 읽기
# =========================================================
# S3에 저장된 JSON 파일들을 읽어 Glue DynamicFrame으로 변환
# Lambda에서 저장한 구조: { LOCALDATA_072404_NW: { row: [...] } }
# jsonPath 없이 전체 JSON을 읽고, DataFrame에서 row 배열 추출
data_source = glueContext.create_dynamic_frame.from_options(
    format_options={"multiline": True},
    connection_type="s3",
    connection_options={"paths": [INPUT_PATH]}, # 폴더 경로: 모든 part_*.json 파일 읽기
    format="json",
    transformation_ctx="data_source"
)

# =========================================================
# 3. 데이터 정제 및 필터링 (Spark/PySpark 로직)
# =========================================================
# DynamicFrame을 Spark DataFrame으로 변환
df = data_source.toDF()

# JSON 구조: { LOCALDATA_072404_NW: { row: [...] } }
# 동적 키(첫 번째 컬럼)를 찾아서 그 안의 row 배열을 추출
# 컬럼명이 동적이므로 첫 번째 컬럼을 사용
columns = df.columns
if len(columns) == 0:
    raise ValueError("No columns found in the data")

# 첫 번째 컬럼(동적 키)의 row 배열을 추출
first_column = columns[0]
df = df.select(explode(col(f"{first_column}.row")).alias("row_data"))

# row_data 구조체를 평탄화하여 개별 컬럼으로 변환
df = df.select("row_data.*")

# 9가지 전처리 로직 적용
# 실제 API 응답 필드명: MGTNO, BPLCNM, DTLSTATENM, RDNPOSTNO, RDNWHLADDR, SITETEL, X, Y, SNTUPTAENM
processed_df = (
    df
    # 3. 'DTLSTATENM' (상세영업상태명)이 "영업"인 데이터만 필터링
    .filter(col("DTLSTATENM") == "영업")
    
    # 1. 컬럼명 변경: 'MGTNO' (관리번호) -> 'id'
    .withColumnRenamed("MGTNO", "id")
    
    # 2. 컬럼명 변경: 'BPLCNM' (사업장명) -> 'name'
    .withColumnRenamed("BPLCNM", "name")
    
    # 4. 'RDNPOSTNO' (도로명우편번호) -> 'post_number' (결측치 처리)
    .withColumn("post_number",
        when((col("RDNPOSTNO") == "") | col("RDNPOSTNO").isNull(), "제공안됨")
        .otherwise(col("RDNPOSTNO"))
    )
    
    # 5. 'RDNWHLADDR' (도로명주소) -> 'address' (결측치 처리)
    .withColumn("address",
        when((col("RDNWHLADDR") == "") | col("RDNWHLADDR").isNull(), "제공안됨")
        .otherwise(col("RDNWHLADDR"))
    )
    
    # 6. 'SITETEL' (전화번호) -> 'phone_number' (모든 공백 제거)
    .withColumn("phone_number", regexp_replace(col("SITETEL"), "\\s+", ""))
    
    # 7. 'X' (좌표정보 X) -> 'longitude' (공백 제거)
    .withColumn("longitude", trim(col("X")))
    
    # 8. 'Y' (좌표정보 Y) -> 'latitude' (공백 제거)
    .withColumn("latitude", trim(col("Y")))
    
    # 9. 'SNTUPTAENM' (위생업태명) -> 'type'
    .withColumnRenamed("SNTUPTAENM", "type")
)

# 최종적으로 필요한 컬럼만 선택
final_df = processed_df.select(
    "id", "name", "post_number", "address", 
    "phone_number", "longitude", "latitude", "type"
)

# 다시 Glue DynamicFrame으로 변환
processed_dyf = DynamicFrame.fromDF(final_df, glueContext, "processed_dyf")

# =========================================================
# 4. S3 Processed 버킷에 결과 저장
# =========================================================
# Athena 쿼리 성능과 비용 절감을 위해 Parquet 형식으로, 날짜와 구 이름 파티션을 생성하여 저장
# 파티션 구조: partition_date=2025-01-15/district=gwangjin/
output_path = f"s3://{S3_OUTPUT_BUCKET}/partition_date={EXECUTION_DATE}/district={DISTRICT_NAME}/"

glueContext.write_dynamic_frame.from_options(
    frame=processed_dyf,
    connection_type="s3",
    connection_options={"path": output_path},
    format="parquet", # Parquet은 Athena 쿼리 비용을 크게 절감시킵니다.
    transformation_ctx="data_sink"
)

job.commit()
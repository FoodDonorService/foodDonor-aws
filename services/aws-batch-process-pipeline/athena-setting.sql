-- 데이터베이스 생성 (장부 보관할 캐비닛 만들기)
CREATE DATABASE IF NOT EXISTS <ATHENA_DATABASE>;

-- 테이블 생성 (Parquet 파일 설계도 등록)
CREATE EXTERNAL TABLE `<ATHENA_DATABASE>`.`<ATHENA_TABLE>` (
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
  's3://<PROCESSED_DATA_BUCKET>/'
TBLPROPERTIES (
  'classification'='parquet'
)

-- 파티션 인식 (S3 폴더 스캔해서 "선반" 등록)
MSCK REPAIR TABLE `<ATHENA_DATABASE>`.`<ATHENA_TABLE>`;
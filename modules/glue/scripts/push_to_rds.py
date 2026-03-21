import sys
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from pyspark.sql.functions import current_date

# Get job args
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_BUCKET_NAME', 'RDS_CONNECTION_NAME'])
bucket = args['S3_BUCKET_NAME']
db_conn_name = args['RDS_CONNECTION_NAME']

sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# --- STEP 1: Read Parquet from S3 ---
s3_source = f"s3://{bucket}/data/harmonized/customers_to_accounts/"
df = spark.read.parquet(s3_source).withColumn("feed_date", current_date())

# --- STEP 2: Write to RDS ---
db_conn_name = "tf-prj-01-conn-rds-mysql"
db_conf = glueContext.extract_jdbc_conf(db_conn_name)
(
  df.write
    .format("jdbc")
    .option("url", db_conf['fullUrl'])
    .option("user", db_conf['user'])
    .option("password", db_conf['password'])
    .option("dbtable", "customer_to_accounts")
    .option("driver", "com.mysql.cj.jdbc.Driver")
    .mode("overwrite")
    .save()
)

# --- STEP 3: VERIFICATION (Read back from RDS and write to S3) ---
verification_df = (
  spark.read
    .format("jdbc")
    .option("url", db_conf['fullUrl'])
    .option("user", db_conf['user'])
    .option("password", db_conf['password'])
    .option("dbtable", "customer_to_accounts")
    .load()
)

# Write the "Proof" to a new S3 location
s3_verify_path = f"s3://{bucket}/data/harmonized/test_rds_customer_to_accounts/"
verification_df.write.mode("overwrite").parquet(s3_verify_path)

job.commit()
import sys
from datetime import datetime
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from pyspark.sql.functions import lit

# Get timestamp
def get_timestamp():
  return datetime.now().strftime("%Y-%m-%d %H:%M:%S")

print(f">>>> Job started at - [{get_timestamp()}]")

# Get job args
args = getResolvedOptions(sys.argv, ['JOB_NAME', 'S3_BUCKET_NAME'])
bucket = args['S3_BUCKET_NAME']

# Get run date
run_date = get_timestamp()[0:10]
print(f">>>> Rundate - [{run_date}]")

# Initialize Glue context
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args['JOB_NAME'], args)

# Define S3 paths
accounts_path = f"s3://{bucket}/data/raw/accounts/{run_date}/"
customers_path = f"s3://{bucket}/data/raw/customers/{run_date}/"

# Read data into DataFrames
df_accounts = spark.read.option("header", "true").csv(accounts_path)
df_customers = spark.read.option("header", "true").csv(customers_path)

# Show schema for debugging
df_accounts.printSchema()
df_customers.printSchema()

# Join datasets and print samples
df_joined = df_customers.join(
  df_accounts,
  "customer_id",
  "inner"
).withColumn("run_date", lit(run_date))

df_joined.show(10, truncate=False)
print(f">>>> Join completed!")

# Save output
output_path = f"s3://{bucket}/data/harmonized/customers_to_accounts/"
(
  df_joined
    .write
    .mode("overwrite")
    .partitionBy("run_date")
    .parquet(output_path)
)

print(f">>>> Job completed at - [{get_timestamp()}]")

job.commit()
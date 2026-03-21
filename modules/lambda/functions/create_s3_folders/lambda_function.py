import boto3
import os

def lambda_handler(event, context):
  s3 = boto3.client('s3')
  bucket_name = os.environ['S3_BUCKET_NAME']

  print(">>>> Executing Lambda - 001-lambda-create-s3-folders")

  folders = [
    "data/raw/accounts/",
    "data/raw/customers/",
    "data/harmonized/customers_to_accounts/",
    "data/curated/"
  ]

  for folder in folders:
    response = s3.list_objects_v2(Bucket=bucket_name, Prefix=folder, MaxKeys=1)

    if 'Contents' in response:
      print(f">>>> Folder: [{folder}] already exists.")
    else:
      print(f">>>> Folder: [{folder}] doesn't exist. Creating folder...")
      s3.put_object(Bucket=bucket_name, Key=folder)
      print(f"Folder created: {folder}")

  return {
    'statusCode': 200,
    'body': 'Folder check and creation process completed'
  }
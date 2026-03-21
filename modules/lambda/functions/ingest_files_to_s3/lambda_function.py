import boto3
import urllib.request
from datetime import datetime
import os

def lambda_handler(event, context):
  s3 = boto3.client('s3')
  bucket_name = os.environ['S3_BUCKET_NAME']

  print(">>>> Executing Lambda - 002-lambda-ingest-files-to-s3")

  current_date = datetime.utcnow().strftime("%Y-%m-%d")
  print(f">>>> Executing the app for date: {current_date}")

  files = {
    "sample_accounts.csv": {
      "source": "https://gist.githubusercontent.com/krohit-bkk/b52dfbbd0168276da24e4e42ec4d5e86/raw/29bc257ab61fa60296e3227b6ea18585fb794d6b/sample_accounts.csv",
      "target": f"data/raw/accounts/{current_date}/sample_accounts.csv"
    },
    "sample_customers.csv": {
      "source": "https://gist.githubusercontent.com/krohit-bkk/b52dfbbd0168276da24e4e42ec4d5e86/raw/29bc257ab61fa60296e3227b6ea18585fb794d6b/sample_customer.csv",
      "target": f"data/raw/customers/{current_date}/sample_customers.csv"
    }
  }

  total = len(files)
  counter = 1
  for name, info in files.items():
    print(f"\n>>>> Processing {counter}/{total} files...")
    print(f">>>> File name: [{name}]")
    target_key = info["target"]

    try:
      s3.head_object(Bucket=bucket_name, Key=target_key)
      print(f">>>> File already exists in S3: {target_key} — will overwrite.")
    except s3.exceptions.ClientError:
      print(f">>>> File does not exist yet: {target_key}")

    response = urllib.request.urlopen(info["source"])
    data = response.read()

    s3.put_object(Bucket=bucket_name, Key=target_key, Body=data)
    print(f">>>> Uploaded {name} to {target_key}")
    counter += 1

  return {
    'statusCode': 200,
    'body': 'Files ingested successfully into S3'
  }
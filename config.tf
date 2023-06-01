provider "aws" {}

data "aws_caller_identity" "current" {}


# IAM [start]

resource "aws_iam_role" "glue_role" {
  name = "glue_role_tf"

  assume_role_policy = jsonencode({
    Version   = "2012-10-17"
    Statement = [
      {
        Actio = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "glue_service_role_attachment" {
  role = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSGlueServiceRole"
}

resource "aws_iam_role_policy_attachment" "dynamodb_readonly_role_attachment" {
  role = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
}

resource "aws_iam_role_policy_attachment" "s3_role_attachment" {
  role = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "athena_role_attachment" {
  role      = aws_iam_role.glue_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonAthenaFullAccess"
}
# IAM [end]

# S3 [start]
resource "aws_s3_bucket" "tf-artifacts-storage" {
  bucket = "tf-artifacts-storage"
}

resource "aws_s3_bucket" "glue-metadata-storage" {
  bucket = "glue-metadata-storage"
}

resource "aws_s3_bucket" "target-transactions-storage" {
  bucket = "tgt-transactions-storage"
}
# S3 [end]

# DynamoDB [start]
resource "aws_dynamodb_table" "ddb_table" {
  name = "ddb_transactions_data"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "UniqueID"

  attribute {
    name = "UniqueID"
    type = "N"
  }
}
# DynamoDB [end]

# Glue [start]
resource "aws_glue_catalog_database" "glue_source_db" {
  name = "primary_table"
  description = "Location of the metadata for the source data"
}

resource "aws_glue_catalog_database" "glue_dest_db" {
  name = "destination_table"
  description = "Location of the metadata for the destination data"
}

resource "aws_glue_crawler" "glue_source_location_crawler" {
  database_name = aws_glue_catalog_database.glue_source_db.name
  schedule      = "cron(00 8 ? * * *)"
  name = "source_crawler_"
  description = "Crawler for fast data retrieval from DynamoDB"
  role = aws_iam_role.glue_role.arn
  configuration = jsonencode(
    {
      Version = 1
      CrawlerOutput = {
        Tables = {AddOrUpdateBehavior = "MergeNewColumns"}
      }
    }
  )

  dynamodb_target {
    path = aws_dynamodb_table.ddb_table.name
  }
}

# resource "aws_glue_crawler" "glue_dest_location_crawler" {
#   database_name = aws_glue_catalog_database.glue_source_db.name
#   schedule      = "cron(40 6 ? * * *)"
#   name = "destination_crawler"
#   description = "Crawler for fast data retrieval from S3 and easy tracking of schema changes in S3"
#   role = aws_iam_role.glue_role.arn
#   configuration = jsonencode(
#     {
#       Version = 1
#       CrawlerOutput = {
#         Tables = {AddOrUpdateBehavior = "MergeNewColumns"}
#       }
#     }
#   )

#   s3_target {
#     path = "s3://${aws_s3_bucket.target-transactions-storage.bucket}"
#   }
# }

resource "aws_s3_object" "glue_script_location" {
  bucket = aws_s3_bucket.tf-artifacts-storage.id
  key    = "Scripts/DynamoDB_ETL_S3.py"
  source = "DynamoDB_ETL_S3.py"
  }

resource "aws_glue_job" "glue_job" {
  name = "DynamoDB_ETL_S3"
  role_arn = aws_iam_role.glue_role.arn
  description = "Glue job created from Terraform!"
  max_retries = "1"
  timeout = 2880
  command {
    script_location = "s3://${aws_s3_object.glue_script_location.bucket}/${aws_s3_object.glue_script_location.key}"
    python_version = "3"
  }
  execution_property {
    max_concurrent_runs = 1
  }
  glue_version = "3.0"
  number_of_workers = 2
  worker_type = "G.1X"
}

resource "aws_glue_trigger" "glue_trigger_ETL_job" {
  name = "ETL_job_trigger_"
  description = "Glue Trigger for automatic job kick-off after the Crawler run succeeds"
  type = "CONDITIONAL"
  actions {
    job_name = aws_glue_job.glue_job.name
  }
  predicate {
    logical = "ANY"

    conditions {
      logical_operator = "EQUALS"
      crawler_name = aws_glue_crawler.glue_source_location_crawler.name
      crawl_state = "SUCCEEDED"
    }
  }
  start_on_creation = "true"
}
#  Glue [end]
**Project Summary - Data Ingestion from DynamoDB to S3**

This project involves ingesting a portion (~1000 records) of E-Commerce transactions data from a Kaggle [dataset](https://www.kaggle.com/datasets/carrie1/ecommerce-data) into AWS S3.
The project is set up using Terraform, with the necessary configuration located in `config.tf`. To ensure security, all credentials are stored as environment variables.

**Prerequisites**

To successfully deploy this architecture on AWS, please ensure that you have completed the following prerequisites:

- AWS Account: Create an AWS account if you haven't already and obtain the necessary access credentials (Access Key, Access Secret).
- Environment Variables: Store the access credentials securely in .env file. Additionally, include the required information for bucket names, as these must be globally unique. When deploying, you will have different buckets based on your configuration.
- Dependencies: Install the latest versions of `boto3`, `terraform` and `python`.

After ensuring all the requirements are met you can run `terraform init` followed by `terraform apply`.

The ETL process for this project requires the following services and resources to be set up:
-  IAM: Creation of the Glue role
- DynamoDB table: The source storage for the data.
- S3: The destination storage and storage for various artifacts.
- Glue Crawler: Manages metadata, including schema changes and data type identification.
- Glue Database + Glue Table: Centralized storage for the metadata extracted by the Crawler.
- Glue Job: Performs the ETL processes.
- Glue Trigger: Automates job execution after the Crawler finishes running.

At present, the workflow can only be executed manually by triggering individual services. To process new data, follow these steps:
1. Run `python dynamo_populate.py` to load data from the local machine into DynamoDB.
2. Run the `glue_source_location_crawler` to extract metadata from the DynamoDB table, enabling quick access for the Glue script. This crawler is scheduled to run every day at 08:00.

Although the plan was to automate the ETL kick-off using Glue triggers, however for some reason the trigger isn't working as intented as it's not starting Glue job. An alternative approach is to create a Lambda function to trigger the ETL.

3. Once the crawler has successfully completed, start the `DynamoDB_ETL_S3` Glue job in Web UI.

The current version of the Glue job performs basic operations, such as type checks, applying mappings to dynamic frames, and writing the final dynamic frame to S3 in the Parquet format, which can later be as part of data ingestion to Snowflake.

**Future work for this project includes:**
  - Gaining a better understanding of how the triggers function and resolving the issue of the non-working functionality
  - Incorporating more complex and interesting transformations into the ETL process, including the addition of partition keys for storage in S3
  - Use least priviledge principle for IAM Glue role
  - Use more features of DynamoDB
  - Glue Crawler for destination S3 bucket

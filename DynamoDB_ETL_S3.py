import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

args = getResolvedOptions(sys.argv, ["JOB_NAME"])
sc = SparkContext()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
job.init(args["JOB_NAME"], args)

# Script generated for node DynamoDB table
DynamoDBtable_node1 = glueContext.create_dynamic_frame.from_catalog(
    database="primary_table",
    table_name="ddb_transactions_data",
    transformation_ctx="DynamoDBtable_node1",
)
DynamoDBtable_node1.printSchema()
resolvedData_node2 = DynamoDBtable_node1.resolveChoice(specs = [("UnitPrice", "cast:long")],transformation_ctx="resolve_choice")
    
# Script generated for node ApplyMapping
ApplyMapping_node3 = ApplyMapping.apply(
    frame=resolvedData_node2,
    mappings=[
        ("UnitPrice", "long", "UnitPrice", "long"),
        ("Description", "string", "Description", "string"),
        ("Country", "string", "Country", "string"),
        ("Quantity", "long", "Quantity", "long"),
        ("InvoiceNo", "string", "InvoiceNo", "string"),
        ("InvoiceDate", "string", "InvoiceDate", "string"),
        ("CustomerId", "long", "CustomerId", "long"),
        ("StockCode", "string", "StockCode", "string"),
    ],
    transformation_ctx="ApplyMapping_node3",
)

ApplyMapping_node3.printSchema()

# Script generated for node S3 bucket
S3bucket_node3 = glueContext.write_dynamic_frame.from_options(
    frame=ApplyMapping_node3,
    connection_type="s3",
    format="glueparquet",
    connection_options={"path": "s3://tgt-transactions-storage", "partitionKeys": []},
    format_options={"compression": "snappy"},
    transformation_ctx="S3bucket_node3",
)

job.commit()

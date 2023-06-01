import boto3
import os
import csv

TABLE_NAME = os.environ.get("DDB_TABLE")
BATCH_SIZE = 25

def write_items_to_table(items_data):
    client_ = boto3.client("dynamodb")
    resp = client_.batch_write_item(
        RequestItems={
            TABLE_NAME: items_data
        }
    )
    return resp

def main():
    with open("data_filtered.csv") as csv_file:
        reader_ = csv.reader(csv_file, delimiter=",")
        file_lst = list(reader_)
        file_len = len(file_lst)

        unique_id = 1

        for i in range(0, file_len, BATCH_SIZE):
            chunks = file_lst[i:i + BATCH_SIZE]
            chunks_formatted = []
            for c in chunks:
                chunks_formatted.append({
                    "PutRequest": {
                        "Item": {
                            "UniqueID": {"N": str(unique_id)},
                            "InvoiceNo": {"S": str(c[0])},
                            "StockCode": {"S": str(c[1])},
                            "Description": {"S": str(c[2])} if c[2] else {"NULL": True},
                            "Quantity": {"N": str(c[3])},
                            "InvoiceDate": {"S": str(c[4])},
                            "UnitPrice": {"N": str(c[5])},
                            "CustomerID": {"N": str(c[6])} if c[6] else {"NULL": True},
                            "Country": {"S": str(c[7])}
                        }
                    }
                })

                unique_id += 1

            write_items_to_table(chunks_formatted)

main()

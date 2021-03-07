import partition_data
from partition_data import IngestionEvent

event = { "s3_bucket": "jpinsolle-source-titanic-dev", "object_key": "incoming/2021-03-06__passengers.csv" }

partition_data.lambda_handler(event, {})
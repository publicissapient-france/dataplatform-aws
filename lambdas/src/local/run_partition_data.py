import partition_data
from models.IngestionEvent import IngestionEvent

event: IngestionEvent = IngestionEvent(
    environment="test",
    datasource_name="titanic",
    s3_bucket="jpinsolle-source-titanic-dev",
    object_key="incoming/2021-03-06__passengers.csv"
)

print(partition_data.process(event))

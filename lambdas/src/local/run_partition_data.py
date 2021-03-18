import partition_data
from models.IngestionEvent import IngestionEvent

event: IngestionEvent = IngestionEvent(
    environment="dev",
    datasource_name="phone",
    s3_bucket="jpinsolle-source-phone-dev",
    # object_key="incoming/customers.csv"
    object_key="incoming/2021-01-01__calls.csv"
)

print(partition_data.process(event))

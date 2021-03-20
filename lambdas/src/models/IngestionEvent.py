from dataclasses import dataclass, replace
from dataclasses_json import dataclass_json


@dataclass_json
@dataclass
class IngestionEvent:
    environment: str
    datasource_name: str
    s3_bucket: str
    object_key: str
    raw_data_file: str = None
    prepared_data_prefix: str = None
    database_name: str = None
    table_name: str = None
    correlation_id: str = None
    partitions: str = None

    def copy(self, raw_data_file: str = None, prepared_data_prefix: str = None, database_name: str = None,
             table_name: str = None, partitions: str = None):
        return replace(self,
                       raw_data_file=raw_data_file,
                       prepared_data_prefix=prepared_data_prefix,
                       database_name=database_name,
                       table_name=table_name,
                       partitions=partitions
                       )

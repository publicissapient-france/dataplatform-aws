import uuid
from dataclasses import dataclass
from dataclasses_json import dataclass_json

@dataclass_json
@dataclass
class IngestionEvent:
    environment: str
    datasource_name: str
    s3_bucket: str
    object_key: str
    correlation_id: str = str(uuid.uuid4())

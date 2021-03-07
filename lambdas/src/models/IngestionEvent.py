import uuid
from dataclasses import dataclass

@dataclass_json
@dataclass
class IngestionEvent:
    s3_bucket: str
    object_key: str
    correlation_id: str = str(uuid.uuid4())

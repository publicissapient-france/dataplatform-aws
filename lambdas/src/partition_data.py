import re
from pathlib import Path
from models.IngestionEvent import IngestionEvent
from typing import Tuple
import boto3
import json

from utils.logging import get_logger

logger = get_logger()


def move_object_in_raw_data(s3_resource, bucket: str, object_key: str) -> Tuple[str, str, str, str]:

    raw_data_prefix, raw_data_base_prefix, raw_data_name, table_name, partitions = compute_raw_data_destination(object_key)
    raw_data_key = raw_data_prefix + raw_data_name

    logger.info(f"Move file s3://{bucket}/{object_key} to s3://{bucket}/{raw_data_key}",
                extra={"source": object_key, "destination": raw_data_key})

    destination = s3_resource.Object(bucket_name=bucket, key=raw_data_key)
    destination.copy({ 'Bucket': bucket, 'Key': object_key })

    return raw_data_base_prefix, raw_data_name, table_name, partitions


def compute_raw_data_destination(object_key: str) -> Tuple[str, str, str, str, str]:
    m = extract_file_information(object_key)
    if m is None:
        raise Exception(f"File pattern doesn't match for file {object_key}")
    logger.info(m.group("prefix"))
    logger.info(m.group("extraction_date"))

    partition = ""
    json_partition = None
    if m.group('year') and m.group('month') and m.group('day'):
        partition = f"year={m.group('year')}/month={m.group('month')}/day={m.group('day')}/"
        json_partition = f'{{"year": "{m.group("year")}", "month": "{m.group("month")}", "day": "{m.group("day")}"}}'

    source_name = Path(m.group("source")).stem
    table_name = Path(m.group("filename")).stem

    return f"raw-data/{source_name}/{table_name}/{partition}", f"raw-data/{source_name}/{table_name}", m.group('filename'), table_name, json_partition


def extract_file_information(source_object_key):
    return re.search(
        "(?P<prefix>[\\w+]*)/(?P<source>[\\w+]*)/(?P<extraction_date>(?P<year>\\d{4})-(?P<month>\\d{1,2})-(?P<day>\\d{1,2}))?(__)?(?P<filename>.+)",
        source_object_key)


def lambda_handler(event, context):
    logger.debug(f"Event={event}")
    logger.debug(f"Context={context}")

    try:
        return process(IngestionEvent.from_json(json.dumps(event)))
    except Exception as e:
        logger.exception('An error occurred')
        raise e


def process(event: IngestionEvent) -> dict:
    s3_resource = boto3.resource('s3')

    raw_data_base_prefix, raw_data_name, table_name, partitions = move_object_in_raw_data(s3_resource, bucket=event.s3_bucket, object_key=event.object_key)

    prepared_data_prefix = raw_data_base_prefix.replace("raw-data", "prepared-data")
    return event.copy(
        raw_data_file=raw_data_base_prefix,
        prepared_data_prefix=prepared_data_prefix,
        database_name=f"{event.environment}-{event.datasource_name}",
        table_name=table_name,
        partitions=partitions
    ).to_dict()

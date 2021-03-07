import re
from pathlib import Path
from models.IngestionEvent import IngestionEvent
import boto3

from utils.logging import get_logger

logger = get_logger()


def move_object(s3_resource, bucket: str, source_key: str, destination_key: str):
    logger.info(f"Move file s3://{bucket}/{source_key} to s3://{bucket}/{destination_key}",
                extra={"source": source_key, "destination": destination_key})

    destination = s3_resource.Object(bucket_name=bucket, key=destination_key)
    destination.copy({
        'Bucket': bucket,
        'Key': source_key
    })


def compute_destination(object_key: str) -> str:
    m = extract_file_information(object_key)
    if m is None:
        raise Exception(f"File pattern doesn't match for file {object_key}")
    logger.info(m.group("prefix"))
    logger.info(m.group("extraction_date"))

    table_name = Path(m.group("filename")).stem
    return f"raw-data/{table_name}/year={m.group('year')}/month={m.group('month')}/day={m.group('day')}/{m.group('filename')}"


def extract_file_information(source_object_key):
    return re.search(
        "(?P<prefix>[\\w+/]*)(?P<extraction_date>(?P<year>\\d{4})-(?P<month>\\d{1,2})-(?P<day>\\d{1,2}))__(?P<filename>.+)",
        source_object_key)


def lambda_handler(event, context):
    logger.debug(f"Event={event}")
    logger.debug(f"Context={context}")

    try:

        process(IngestionEvent(s3_bucket=event['s3_bucket'], object_key=event['object_key']))
    except Exception as e:
        logger.exception('An error occurred')
        raise e


def process(event: IngestionEvent):
    s3_resource = boto3.resource('s3')

    destination_key = compute_destination(event.object_key)
    move_object(s3_resource,
                bucket=event.s3_bucket,
                source_key=event.object_key,
                destination_key=destination_key
                )
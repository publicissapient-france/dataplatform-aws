from utils.logging import get_logger
from models.IngestionEvent import IngestionEvent
import boto3
import os
import uuid

logger = get_logger()


def lambda_handler(event, context):
    logger.debug(f"Event={event}")
    logger.debug(f"Context={context}")

    try:
        process(event=event, sfn_arn=os.environ['STEP_FUNCTIONS_ARN'], environment=os.environ['ENVIRONMENT'])
    except Exception as e:
        logger.exception('An error occurred')
        raise e


def process(event, sfn_arn: str, environment: str):
    sfn_client = boto3.client('stepfunctions')
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']

    datasource_name = extract_source_from_bucket(bucket)
    step_functions_input = IngestionEvent(
        environment=environment,
        datasource_name=datasource_name,
        s3_bucket=bucket,
        object_key=key,
        correlation_id=str(uuid.uuid4())
    )

    execution_name = f"{datasource_name}-{step_functions_input.correlation_id}"
    start(sfn_client, sfn_arn, execution_name, step_functions_input)


def extract_source_from_bucket(bucket: str):
    return bucket.split("-")[2]


def start(sfn_client, sfn_arn: str, execution_name: str, sfn_input: IngestionEvent):
    try:
        sfn_response = sfn_client.start_execution(
            stateMachineArn=sfn_arn,
            name=execution_name,
            input=sfn_input.to_json(),
        )

        logger.info(f"Start step functions {sfn_arn}",
                    extra={"sfn_arn": sfn_arn, "execution_name": execution_name, "sfn_payload": sfn_input, "status": "ok"})
        return sfn_response
    except Exception as e:
        logger.exception(f"Start step functions {sfn_arn}",
                         extra={"sfn_arn": sfn_arn, "execution_name": execution_name, "sfn_payload": sfn_input, "status": "ko"})
        raise e

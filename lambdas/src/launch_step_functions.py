from utils.logging import get_logger
import boto3
import os

logger = get_logger()


def lambda_handler(event, context):
    logger.debug(f"Event={event}")
    logger.debug(f"Context={context}")

    try:
        process(event=event, sfn_arn=os.environ['STEP_FUNCTIONS_ARN'])
    except Exception as e:
        logger.exception('An error occurred')
        raise e


def process(event, sfn_arn: str):
    sfn_client = boto3.client('stepfunctions')
    bucket = event['Records'][0]['s3']['bucket']
    key = event['Records'][0]['s3']['object']['key']

    step_functions_input = {
        "s3_bucket": "",
        "object_key": "",
        "correlation_id": ""
    }

    start(sfn_client, sfn_arn)


def start(sfn_client, sfn_arn: str, execution_name: str, sfn_input: str):
    try:
        sfn_response = sfn_client.start_execution(
            stateMachineArn=sfn_arn,
            name=execution_name,
            input=sfn_input
        )

        logger.info(f"Start step functions {sfn_arn}",
                    extra={"sfn_arn": sfn_arn, "execution_name": execution_name, "sfn_payload": sfn_input, "status": "ok"})
        return sfn_response
    except Exception as e:
        logger.exception(f"Start step functions {sfn_arn}",
                         extra={"sfn_arn": sfn_arn, "execution_name": execution_name, "sfn_payload": sfn_input, "status": "ko"})
        raise e

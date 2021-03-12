import boto3
import os
import json
from utils.logging import get_logger
from models.IngestionEvent import IngestionEvent
from typing import List

logger = get_logger()


def lambda_handler(event, context):
    logger.debug(f"Event={event}")
    logger.debug(f"Context={context}")

    try:
        process(event=event, eventbus_name=os.environ['EVENTBUS_NAME'])

    except Exception as e:
        logger.exception('An error occurred')
        raise e


def process(event: dict, eventbus_name: str):
    sfn_client = boto3.client('stepfunctions')
    events_client = boto3.client('events')

    ingestion_event: IngestionEvent = IngestionEvent.from_json(event['detail']['input'])
    state_machine_arn: str = event['detail']['stateMachineArn']
    execution_arn: str = event['detail']['executionArn']
    time: str = event['time']
    state = None

    execution_history = get_step_functions_history(sfn_client, execution_arn)
    if is_success_execution(execution_history):
        state = "SUCCEED"
        logger.info("Success for step functions %s", execution_arn,
                    extra={"executionArn": execution_arn, "stateMachineArn": state_machine_arn, "input": ingestion_event})
    else:
        state = "FAILED"
        failed_step: dict = get_failed_step(execution_history)
        logger.error("Step Functions error %s", state_machine_arn,
                 extra={"error": failed_step['executionFailedEventDetails'], "executionArn": execution_arn,
                        "stateMachineArn": state_machine_arn, "input": ingestion_event})

    details = {
        "SourceName": ingestion_event.datasource_name,
        "Environment": ingestion_event.environment,
        "CorrelationId": ingestion_event.correlation_id,
        "status": state
    }
    events_client.put_events(
        Entries=[
            {
                'Time': time,
                'Source': 'datalake.ingestion',
                'DetailType': f"ingestion-{state}",
                'Detail': json.dumps(details),
                'EventBusName': eventbus_name,
            }
        ]
    )


def get_step_functions_history(sfn_client, execution_arn: str):
    paginator = sfn_client.get_paginator('get_execution_history')
    response_iterator = paginator.paginate(
        executionArn=execution_arn,
        maxResults=1000,
        PaginationConfig={
            'MaxItems': 1000
        }
    )
    execution_history: List[dict] = []
    for response in response_iterator:
        execution_history.extend(response['events'])
    logger.info(f"Execution graph size={len(execution_history)}")
    return execution_history


def is_success_execution(execution_history: List[dict]):
    event_succeeded = [event for event in execution_history if event['type'] in 'ExecutionSucceeded']
    return len(event_succeeded) > 0


def get_failed_step(execution_history: List[dict]):
    return [event for event in execution_history if event['type'] in 'ExecutionFailed'][0]

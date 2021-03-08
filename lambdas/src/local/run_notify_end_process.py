from notification import notify_end_process

event = {
    'version': '0',
    'id': 'c37db0b5-6bdd-d286-416f-8ceb9966b7f4',
    'detail-type': 'Step Functions Execution Status Change',
    'source': 'aws.states',
    'account': '767178862217',
    'time': '2021-03-07T20:27:34Z',
    'region': 'eu-west-1',
    'resources': [
        'arn:aws:states:eu-west-1:767178862217:execution:dev-ingestion-workflow:titanic-6e7b0e6f-0ca7-4294-a084-924057d871f2'],
    'detail': {
        'executionArn': 'arn:aws:states:eu-west-1:767178862217:execution:dev-ingestion-workflow:titanic-6e7b0e6f-0ca7-4294-a084-924057d871f2',
        'stateMachineArn': 'arn:aws:states:eu-west-1:767178862217:stateMachine:dev-ingestion-workflow',
        'name': 'titanic-6e7b0e6f-0ca7-4294-a084-924057d871f2', 'status': 'SUCCEEDED', 'startDate': 1615148850582,
        'stopDate': 1615148854726,
        'input': '{\"environment\": \"test\", \"datasource_name\": \"titanic\", \"s3_bucket\": \"jpinsolle-source-titanic-dev\", \"object_key\": \"incoming/2021-03-06__passengers.csv\", \"correlation_id\": \"6e7b0e6f-0ca7-4294-a084-924057d871f2\"}',
        'inputDetails': {'included': True}, 'output': 'null', 'outputDetails': {'included': True}
    }
}

notify_end_process.process(event, "jinsolle")

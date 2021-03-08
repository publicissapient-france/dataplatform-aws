import launch_step_functions

event = {'Records': [{
    's3': {
        'bucket': {
            'name': 'jpinsolle-source-titanic-dev',
            'ownerIdentity': {'principalId': 'AP8T0YB92KHXW'},
            'arn': 'arn:aws:s3:::jpinsolle-source-titanic-dev'
        },
        'object': {
            'key': 'incoming/2021-03-06__passengers.csv',
            'size': 121612,
            'eTag': 'cc838e608b861f2ac922936c889a9c8d',
            'versionId': 'kTuIei3rI23ml.FNz8nhQsfEk6EV3.IQ',
            'sequencer': '006044FC998CEF24B2'}}
    }]}

launch_step_functions.process(event, "arn:aws:states:eu-west-1:767178862217:stateMachine:dev-ingestion-workflow", "test")

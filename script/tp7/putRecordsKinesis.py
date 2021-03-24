import json
import boto3
import sys
import random
import time
import uuid

session = boto3.Session(profile_name='default')
usStatesClient = session.client('firehose')
states = ["NY", "AK", "AZ", "AR", "CA", "IDF", "PACA"]
while True:
    kinesisDeliveryStream = sys.argv[1]
    entry = {f"{uuid.uuid1()}": random.choice(states)}
    response = usStatesClient.put_record(DeliveryStreamName=kinesisDeliveryStream,
                                         Record={'Data': json.dumps(entry)})
    print(f"Writing to {kinesisDeliveryStream}: {response}")
    time.sleep(1)

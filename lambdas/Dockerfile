FROM public.ecr.aws/lambda/python:3.8

COPY src ${LAMBDA_TASK_ROOT}
COPY requirements.txt ${LAMBDA_TASK_ROOT}
RUN pip install --upgrade pip && pip install -r requirements.txt

CMD [ "partition_data.lambda_handler" ]
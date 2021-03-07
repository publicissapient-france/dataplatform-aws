
Le bucket S3 étant dans une autre stack cloudformation il est nécessaire de passer par un 
workaround pour configurer les events S3. La ressource `AWS::S3::Bucket` possède bien une 
propriété `NotificationConfiguration` mais cela implique de déclarer tout dans la même stack.



```shell
AWS_PROFILE=jpinsolle aws s3 cp data/titanic/passengers.csv s3://jpinsolle-source-titanic-dev/incoming/2021-03-06__passengers.csv


docker run -ti -v ~/.aws:/root/.aws -e AWS_PROFILE=jpinsolle -p 9000:8080 767178862217.dkr.ecr.eu-west-1.amazonaws.com/ingestion-workflow:latest
```
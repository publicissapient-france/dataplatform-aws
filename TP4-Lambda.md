## Étape 0 Créer un virtualenv
Vous pouvez si vous le souhaitez installer un virtualenv. Pour cela exécuter la commande : 
```
./deploy/sapient-formation.sh setup-create-virtualenv
```

Activez le virtualenv : 
```
source ~/.venvs/formation/bin/activate
```


## Étape 1 : Build des lambdas
Installez les dépendances python
```
./deploy/sapient-formation.sh setup-install-lambda-python-requirements
```

Ou si vous êtes dans un virtualenv
```
./deploy/sapient-formation.sh setup-install-lambda-python-requirements-with-venv
```

Construisez l'image Docker des lambdas. Cette étape : 
* Génère un numéro de version qui est la date courante
* Se connecte à l'ECR créé au du TP1
* Construit une image à partir du fichier **lambdas/Dockerfile**.
* Taggue l'image avec la version ainsi que latest puis la push dans l'ECR
```
./deploy/sapient-formation.sh tp4-build-ingestion-workflow dev
```

Notez le numéro de version retourné par la commande, vous en aurez besoin l'étape suivante, pour déployer la stack Cloudformation
```shell
[..]
029149e8529a: Layer already exists 
latest: digest: sha256:5865e0197fb37ab4f7fb17d7dcd8d79b08c64b5881e095e0b4b5e2d6f5d5203a size: 2208
############################################################################################################
# VERSION 20210326153005
############################################################################################################
```


## Étape 3 : Déploiement de l'event bus
L'eventbus est géré dans une stack dédiée car son cycle de vie est différent des autres stack

```
 ./deploy/sapient-formation.sh tp4-deploy-eventbus dev
```


## Étape 4 : Déploiement la chaine d'ingestion
```
 ./deploy/sapient-formation.sh tp4-deploy-ingestion-workflow dev <VERSION_A_REMPLACER>
```

## Étape 5 : Déploiement de la lambda pour gérer les notifications S3
Le bucket S3 étant dans une autre stack cloudformation il est nécessaire de passer par un workaround pour configurer les
events S3. La ressource `AWS::S3::Bucket` possède bien une propriété `NotificationConfiguration` mais cela implique de
déclarer tout dans la même stack.

Nous créons donc une custom ressource pour ajouter les events à un bucket S3 existant. Pour cela, déployez la stack adéquat

```
./deploy/sapient-formation.sh tp4-deploy-custom-s3-notification-custom-resource dev
```

La lambda [dev-bucket-notification-updater-custom-cfn](https://eu-west-1.console.aws.amazon.com/lambda/home?region=eu-west-1#/functions/dev-bucket-notification-updater-custom-cfn?tab=code)
a été crée. Elle sera appelée par le service Cloudformation pour ajouter l'event.

## Étape 6 : Modification de la stack S3 pour gérer les événements

La stack s3 du tp4 contient l'appel à la custom resource pour enregistrer le déclenchement d'une lambda sur l'upload d'un fichier
dans le répertoire incoming.
```
./deploy/sapient-formation.sh tp4-deploy-s3 dev phone
```

## Étape 7 : Test
```shell
aws s3 cp data/phone/customers.csv s3://<trainee>-source-phone-dev/incoming/phone/customers.csv
aws s3 cp data/phone/2021-01-01__calls.csv s3://<trainee>-source-phone-dev/incoming/phone/2021-01-01__calls.csv
```


# Développement Local
```
docker run -ti -v ~/.aws:/root/.aws -e AWS_PROFILE=<profile> -p 9000:8080 767178862217.dkr.ecr.eu-west-1.amazonaws.com/ingestion-workflow:latest
```

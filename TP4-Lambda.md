# TP4-LAMBDA
Avant de commencer, assurez-vous d'être dans le dossier `dataplatform-aws` 
```shell
cd dataplatform-aws/
```
## Étape 1 : Créer un virtualenv 
Pour avoir une gestion des dépendances python propres et ainsi éviter de gérer plusieurs versions de librairies sur vos différents projets,
il est recommandé d'installer un [virtualenv](https://docs.python.org/fr/3/library/venv.html).
Pour cela exécuter la commande : 
```
./deploy/sapient-formation.sh setup-create-virtualenv
```

Activez le virtualenv : 
```
source ~/.venvs/formation/bin/activate
```

## Étape 2 : Build des lambdas
Installez les dépendances python :
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

Notez le numéro de version retourné par la commande, vous en aurez besoin à l'étape suivante, pour déployer la stack Cloudformation
```shell
[..]
029149e8529a: Layer already exists 
latest: digest: sha256:5865e0197fb37ab4f7fb17d7dcd8d79b08c64b5881e095e0b4b5e2d6f5d5203a size: 2208
############################################################################################################
# VERSION 20210326153005
############################################################################################################
```


## Étape 3 : Déploiement de l'event bus
L'event bus est géré dans une stack dédiée, car son cycle de vie est différent des autres stack:

```
./deploy/sapient-formation.sh tp4-deploy-eventbus dev
```


## Étape 4 : Déploiement de la chaine d'ingestion
```
./deploy/sapient-formation.sh tp4-deploy-ingestion-workflow dev <VERSION_A_REMPLACER>
```

## Étape 5 : Modification de la stack S3 pour gérer les événements

La stack s3 du tp4 contient la configuration des notifications pour enregistrer le déclenchement d'une lambda sur l'upload d'un fichier
dans le répertoire incoming.
```
./deploy/sapient-formation.sh tp4-deploy-s3 dev phone
```

## Étape 6 : Test

###Dépôt de fichier dans le repertoire incoming du bucket S3 :

NB : Modifier la valeur <trainee> par la vôtre avant de lancer la commande

```shell
aws s3 cp data/phone/customers.csv s3://<trainee>-source-phone-dev/incoming/phone/customers.csv
aws s3 cp data/phone/2021-01-01__calls.csv s3://<trainee>-source-phone-dev/incoming/phone/2021-01-01__calls.csv
```
### Vérification du déclenchement du job Glue :
Vérifiez à l'aide de [la console](https://eu-west-1.console.aws.amazon.com/gluestudio/home?region=eu-west-1#/editor/job/dev-csv-to-parquet/runs)
le lancement du job glue après le dépôt des fichiers.


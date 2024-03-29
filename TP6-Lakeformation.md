# TP6-LAKE FORMATION
Avant de commencer, assurez-vous d'être dans le dossier `dataplatform-aws` 
```shell
cd dataplatform-aws/
```
Le but de cet exercice est d'utiliser lake formation pour sécuriser l'accès à des données requêtées via Athena.

Nous utiliserons aussi un crawler pour alimenter notre data platform.

## Le use case
Nous avons reçu dans notre centre d'appels, des données sensibles que l'on doit gérer sur notre dataplatform, les passagers du titanic.

Le but d'avoir ces données et de contacter par la suite la famille des rescapés pour une offre promotionnelle.

Cependant, pour restreindre l'accès aux données sensibles à notre nouveau data analyst fraîchement recruté, nous souhaitons, via lake formation,
ne laisser l'accès qu'aux colonnes `pclass`,`name`, `age` de cette table.

## Déroulement de l'exercice
Pour répondre à ce besoin nous allons tout d'abord lancer une stack cloudformation qui nous créera le user `DataAnalyst et certains pré-requis.

Nous allons par la suite ingérer la donnée via crawler.

Et finalement nous allons, via la console (car malheureusement ce niveau de droit assez fin n'est pas gérable par cloudformation),
octroyer les droits à notre data analyst.

## Étape 1 : Activer les droits LakeFormation sur les données 
Cette étape, qui ne peut être configurée avec cloud formation pour le moment, doit se faire sur la console.

Reportez vous donc, sur la console, connectez vous avec votre compte principal et ouvrez le service LakeFormation.

Une fois cela fait, désactiver les deux cases suivantes qui empêcheront d'appliquer les droits IAM aux databases et tables
qui seront prochainement créées :
![LakeFormation14](./documentation/tp6/LakeFormation_14.png "LakeFormation14")

## Étape 2 : Lancer la stack cloudformation de configuration du service LakeFormation

À cette étape nous allons créer le user DataAnalyst, configurer son rôle, configurer l'administrateur du service LakeFormation,
mais aussi créer un crawler et configurer ses droits LakeFormation pour alimenter la table.

Pour se faire, assurez-vous d'être dans le dossier `dataplatform-aws` 
```shell
cd dataplatform-aws/
```
Ensuite déployer la stack
```shell
./deploy/sapient-formation.sh tp6-deploy-lakeformation-workshop dev
```

En attendant le déploiement, voyons en détail les resources créées et les configurations intéressantes de cette stack:

* #### Définition de l'admin lakeformation:
![CF1](./documentation/tp6/CF1.png "CF1")
  Nous allons à ce niveau référencer l'administrateur des données sur LakeFormation. Dans notre cas nous avons spécifier un user,
  qui en l'occurence sera vous même, mais dans un contexte hors démo, il est possible de le rajouter à un rôle IAM existant et de l'affecter à plusieurs users.
  

* #### Rajout des permissions LakeFormation au role du crawler créé:
![CF2](./documentation/tp6/CF2.png "CF2")
Notez que les droits sont octroyés à une seule database et sont restreints uniquement à la modification, suppression et création des tables.
  
* #### Définition du DataLake location au niveau du service LakeFormation
![CF3](./documentation/tp6/CF3.png "CF3")
Cette étape permettra de définir où seront stockées mes données et où les règles LakeFormation vont s'appliquer.

* #### Définition du user DataAnalyst
![CF3](./documentation/tp6/CF4.png "CF4")
Notez les droits retreints du user et comment est configurée l'application des droits LakeFormation.
Notez aussi le rajout des droits pour pouvoir écrire le resultat des requêtes Athena dans le bucket dédié.

## Étape 3 : Rajouter les droits sur les données pour le crawler
Actuellement, nous avons affecté des droits uniquement au niveau des tables (au sens Glue) mais pas aux données sauvegardées dans S3.
Pour cela nous allons utiliser la console pour octroyer ces droits, et les rajouter au rôle du crawler:
![LakeFormation12](./documentation/tp6/LakeFormation_12.png "LakeFormation12")
Puis :
![LakeFormation11](./documentation/tp6/LakeFormation_11.png "LakeFormation11")

## Étape 4 : Déposer le fichier sur S3 et lancer le crawler
Récupérer tout d'abord l'ID de votre compte AWS :
![Id_compte](./documentation/tp6/Id_compte.png "Id_compte")

NB : Modifier la valeur '<AWS::AccountId>' par la vôtre avant de lancer la commande

```shell
aws s3 cp data/titanic/passengers.csv s3://lake-formation-demo-source-eu-west-1-<AWS::AccountId>/passengers.csv
```

Puis lancer le crawler :
```shell
aws glue start-crawler --name lake-formation-demo-crawler
```
Vous pouvez suivre son avancement [ici](https://eu-west-1.console.aws.amazon.com/glue/home?region=eu-west-1#catalog:tab=crawlers).

Une fois le crawler passé au statut `Ready` passez à l'étape 5. 

## Étape 5 : Donner les droits requis au data analyst
Dans cette étape, nous allons affecter les droits nécessaires au data analyst avec Lake Formation.

Pour créer un filtre sur les données rendez vous [ici](https://eu-west-1.console.aws.amazon.com/lakeformation/home?region=eu-west-1#data-filters),
puis créer le filtre suivant :
![LakeFormation7.2](./documentation/tp6/LakeFormation_7.2.png "LakeFormation7.2")
Notez aussi qu'on peut faire l'opération inverse, en ne donnant pas accès à certaines colonnes.
La valeur `true` dans la partie Row filter expression permet de dire qu'on peut accéder à toutes les données de ces champs,
car il est possible de ne donner accès qu'à une catégorie de donnée (par exemple uniquement aux personnes majeures en appliquant le filtre age>=18).

Puis, allez au service Lake Formation puis dans le panel `Tables` cliquez sur `Grant` en sélectionnant la table nouvellement créée:
![LakeFormation8](./documentation/tp6/LakeFormation_8.png "LakeFormation8")

À partir de là vous pouvez affecter le filtre qu'on vient de créer au user `DataAnalyst`:
![LakeFormation7.3](./documentation/tp6/LakeFormation_7.3.png "LakeFormation7.3")

## Étape 6 : Tester les droits en tant que data analyst:
Connectez-vous via un autre navigateur web ou dans un onglet privé à l'interface de connexion de la [Console AWS](https://console.aws.amazon.com).
Puis renseignez votre ID de compte, le user `DataAnalyst` ainsi que son mot de passe `Azerty123!`.

NB : Une fois connecté vérifiez bien que la région spécifiée est `Irlande`.

Reportez-vous ensuite sur le service Athena et configurer le bucket de sortie des requêtes:
![LakeFormation5](./documentation/tp6/LakeFormation_5.png "LakeFormation5")
Puis :
![LakeFormation4](./documentation/tp6/LakeFormation_4.png "LakeFormation4")

Notez qu'on ne retrouve que les colonnes définies plus haut qui sont exposés et pas les autres :
![LakeFormation3](./documentation/tp6/LakeFormation_3.png "LakeFormation3")

Essayez maintenant de supprimer cette table, vous constaterez que ce n'est pas possible, une erreur `Insufficient Lake Formation Permission(s)`est remontée: 
![LakeFormation2](./documentation/tp6/LakeFormation_2.png "LakeFormation2")

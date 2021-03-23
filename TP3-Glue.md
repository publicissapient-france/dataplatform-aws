
Le but de cet exercice est de créer et déployer un job Glue.

Le script `.scala` du job est fournit dans le répertoire `csvtoparquet` à la racine du projet.

Le job Glue a besoin d'un jar pour fonctionner. Il est construit avec Maven. 

Le packaging et l'upload du jar ainsi que l'upload du fichier Scala sont effectués par la méthode `tp3-deploy-glue` du fichier `sapient-formation.sh`.

Dans cet exercice vous allez devoir compléter le template Cloudformation `tp3/glue.yaml`


Avant de commencer assurez-vous d'être dans le dossier `dataplatform-aws` 
```shell
cd dataplatform-aws/
```

## Étape 1 : Déployer la stack Artifact
Le script Scala et le jar vont être déployé dans un bucket à part. Ce bucket se trouve dans la stack `tp3/artifacts.yaml`.
Prenez connaissance de son contenu et déployez-le avec la commande suivante :

```shell
./deploy/sapient-formation.sh tp3-deploy-artifacts dev
```
Vérifiez grâce à la console que le bucket a bien été créé.

## Étape 2 : Déployer la stack Catalog
Le job Glue va automatiquement peupler le data catalog. Il est nécessaire de créer en amont la base de données qui contiendra les tables.
La définition de la base de données se trouve dans le template `tp3/catalog.yaml`

```shell
./deploy/sapient-formation.sh tp3-deploy-catalog dev phone
```

Vérifiez grâce à la console que la base de données a bien été créée.

## Étape 3 : Créer le job Glue
Le template contenant le job Glue et son rôle associé se trouve ici : `tp3/glue.yaml`.
Complétez-le en vous aidant des exemples donné dans le cours. Vous trouvez la solution ici : `tp3/reponses/glue.yaml`.

Quelques informations importantes : 
* Pensez bien à regarder les paramètres d'entrée de la stack, ils seront utiles.
* Le script Scala sera déployé ici : `s3://<bucket-artifact>/glue/CsvToParquet.scala`
* Le jar sera déployé ici : `s3://<bucket-artifact>/glue/csv-to-parquet-1.0-SNAPSHOT-jar-with-dependencies.jar`
* La classe à appeler est celle-ci `fr.publicissapient.training.csvtoparquet.CsvToParquet`

## Étape 3 : Créer le rôle associé
* Le rôle doit pouvoir être assumé par le service `glue.amazonaws.com`
* Il doit donner les droits S3 à tous les buckets commençant par la valeur contenue dans le paramètre de stack `BucketPrefix`
* Il doit donner les droits S3 au bucket artifact.
  * Pour ce dernier attention vous devez donner les droits à `<bucket-artifact>` et `<bucket-artifact>/*`. Le rôle a besoin de `<bucket-artifact>` pour pouvoir lister le contenu du bucket.
* Les droits S3 nécessaires sont les suivants : 
  * `s3:HeadObject`
  * `s3:GetObject`
  * `s3:PutObject`
  * `s3:DeleteObject`
  * `s3:PutObjectAcl`
  * `s3:ListBucket`
* Le rôle doit donner les droits à la clé KMS de la plateforme
* Les droits à donner surr la clé KMS sont les suivants :
  * `kms:Encrypt`
  * `kms:Decrypt`
  * `kms:ReEncrypt*`
  * `kms:GenerateDataKey*`
  * `kms:DescribeKey`
  
## Étape 4 : Déployer le job
Pour déployer votre job lancez la commande suivante : 
```shell
./deploy/sapient-formation.sh tp3-deploy-glue dev
```
Cette commande a 3 étapes
* Construction du jar avec Maven
* Upload du jar et du script Scala
* Déploiement de la stack `tp3/glue.yaml`

Si vous rencontrez un problème dans la construction du jar avec Maven, un jar déjà construit est disponible dans le répertoire `csvtoparquet/jar/`. Pour le déployer allez dans le fichier `deploy_functions.sh`. Dans la fonction `deploy_glue_job`, commentez la ligne de création du jar (`mvn clean package`) ainsi que la suivante qui upload le jar créé par Maven. Dé-commentez ensuite la ligne suivante qui uploadera le jar déjà prêt.

## Étape 5 : Lancer le job
Pour lancer le job exécuter d'abord la commande suivante pour uploader des données dans le bucket : 
```shell
aws s3 cp data/phone/customer.csv s3://<trainee>-source-phone-dev/raw-data/phone/customers/customers.csv
```

Lancez le job Glue avec la commande suivante : 
```shell
aws glue start-job-run --job-name dev-csv-to-parquet --arguments '{"--table_name": "customers", "--database_name": "dev-phone", "--input_path": "s3://<trainee>-source-phone-dev/raw-data/phone/customers", "--output_path": "s3://<trainee>-source-phone-dev/prepared-data/phone/customers"}'
```

Vérifiez dans la console que le job s'est bien exécuté avec succès.

Nous allons voir dans les prochains chapitres comment déclencher un job Glue au sein d'un pipeline complet de données.
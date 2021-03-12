
Le but de cet exercice est de déployer de prendre en main cloudformation et de 
vérifier que vous êtes en mesure de déployer des stacks sur vos comptes.


Assurer vous d'être dans le dossier `dataplatform-aws` 
```shell
cd dataplatform-aws/
git checkout tp1
```

## Étape 1
Déployer les stack suivantes sur l'environnement `dev`
 * dev-dataplatform-kms
 * dev-dataplatform-s3
 * dev-dataplatform-ecr
 
```
./deploy/sapient-formation.sh tp1-deploy-kms dev
./deploy/sapient-formation.sh tp1-deploy-s3 dev titanic
./deploy/sapient-formation.sh tp1-deploy-ecr dev
```

Vérifier les stacks déployées dans [le service cloudformation](https://eu-west-1.console.aws.amazon.com/cloudformation/home?region=eu-west-1)

## Étape 2
Ajouter les outputs pertinents à vos stacks. Noter les différentes possibilités pour récupérer les valeurs
de retour de chaque ressource `Ref` pour le BucketName et `!GetAtt` pour l'ARN du bucket.

Voir la liste des possibilités pour les curieux : [S3](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-s3-bucket.html#aws-properties-s3-bucket-return-values),
[KMS](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-resource-kms-key.html#aws-resource-kms-key-return-values)

**dev-dataplatform-kms**
```yaml
Outputs:
  KMSKeyArn:
    Value: !GetAtt KMSKey.Arn
```

**dev-dataplatform-s3**
```yaml
Outputs:
  BucketArn:
    Value: !GetAtt Bucket.Arn
```

**Résultat**
![Résultat](./documentation/tp1/cloudformation.png "Permissions")
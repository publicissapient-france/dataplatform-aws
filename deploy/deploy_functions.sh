#!/bin/bash

# Usage : configure_proxy PROXY_URL
function configure_proxy() {
    PROXY=$1
    echo "Setup proxy in environment with PROXY=$PROXY"
    export http_proxy=$PROXY && export https_proxy=$PROXY && export no_proxy="169.254.169.254,localhost,s3-website-eu-west-1.amazonaws.com"
}


# Usage: install_ansible_requirements
function install_deps() {
    pip install ansible
    pip install -r ${BASE_PATH}/deploy/kafka/ansible/requirements.txt
    mkdir -p ~/.ansible/plugins/modules
    ansible-galaxy install -r  ${BASE_PATH}/deploy/kafka/ansible/requirements.yml -p ~/.ansible/plugins/modules/
}


# Usage : install_python_requirements
function install_lambda_python_requirements() {
    EXEC_PWD=$PWD
    echo "Install python requirement for $BASE_PATH/lambdas"
    cd "$BASE_PATH/lambdas"
    pip install -r requirements.txt

    cd ${EXEC_PWD}
}

# Usage : deploy_generic_stack ENVIRONMENT TEMPLATE_PATH
function deploy_generic_stack() {
    ENV=$1
    TEMPLATE_PATH=$2
    VERSION=$3
    SOURCE=$4

    echo "Deploy cloudformation $TEMPLATE_PATH with parameters ENV=$ENV VERSION=$VERSION SOURCE=$SOURCE"
    if [[ -z "$ENV" ]] ; then
        echo "Missing required parameter. ENVIRONMENT is missing"
        exit 3
    fi

    EXEC_PWD=$PWD
    cd "$BASE_PATH/deploy/cloudformation/"
    sceptre \
      --var-file="variables.default.yaml" \
      --var-file="variables.$ENV.yaml" \
      --var="Version=$VERSION" \
      --var="Source=$SOURCE" \
      launch --yes "$TEMPLATE_PATH"

    cd ${EXEC_PWD}
}

# Usage : deploy_glue_job ENVIRONMENT
function deploy_glue_job() {
    ENV=$1

    echo "Deploy glue job with parameters ENV=$ENV"
    if [[ -z "$ENV" ]] ; then
        echo "Missing required parameter. ENVIRONMENT is missing"
        exit 3
    fi

    BUCKET_NAME=$(aws cloudformation describe-stacks --stack-name "$ENV-dataplatform-artifacts" --output text --query 'Stacks[0].Outputs[?OutputKey==`BucketName`].OutputValue')

    EXEC_PWD=$PWD
    cd "$BASE_PATH/csvtoparquet/src/main/scala/fr/publicissapient/training/csvtoparquet/"
    aws s3 cp CsvToParquet.scala "s3://$BUCKET_NAME/glue/CsvToParquet.scala"

    cd "$BASE_PATH/csvtoparquet/"
    mvn clean package
    aws s3 cp target/csv-to-parquet-1.0-SNAPSHOT-jar-with-dependencies.jar "s3://$BUCKET_NAME/glue/csv-to-parquet-1.0-SNAPSHOT-jar-with-dependencies.jar"

    cd ${EXEC_PWD}
}

# docker_login PROFILE REGION
function docker_login() {
  REGION=$1
  REGISTRY=$(aws cloudformation describe-stacks --region $REGION --stack-name "$ENV-dataplatform-ecr" --query 'Stacks[0].Outputs[?OutputKey==`IngestionWorkflowRegistry`].OutputValue' --output text)

  aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin "$REGISTRY"
}

# build_lambda REGION ENV VERSION
function build_lambda() {
  REGION=$1
  ENV=$2
  VERSION=$3

  echo "Build lambda docker with parameters REGION=$REGION ENV=$ENV VERSION=$VERSION"
  if [[ -z "$REGION" ]] || [[ -z "$ENV" ]] || [[ -z "$VERSION" ]] ; then
      echo "Missing required parameter. ENVIRONMENT or REGION or REGION is missing"
      exit 3
  fi

  EXEC_PWD=$PWD
  cd "$BASE_PATH/lambdas/"

  docker_login "$REGION"

  REGISTRY=$(aws cloudformation describe-stacks --region $REGION --stack-name "$ENV-dataplatform-ecr" --query 'Stacks[0].Outputs[?OutputKey==`IngestionWorkflowRegistry`].OutputValue' --output text)
  docker build . -t "$REGISTRY:$VERSION"
  docker tag "$REGISTRY:$VERSION" "$REGISTRY:latest"

  docker push "$REGISTRY:$VERSION"
  docker push "$REGISTRY:latest"

  cd ${EXEC_PWD}
}


# Usage: display_version VERSION
function display_version() {
  VERSION=$1
  echo "############################################################################################################"
  echo "# VERSION $VERSION"
  echo "############################################################################################################"
}
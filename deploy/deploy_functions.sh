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

# Usage : assume_role ROLE_TO_ASSUME
function assume_role() {
    ROLE=$1
    echo "Assume IAM role $ROLE"

    AWS_TMP_CONNEXION=$(aws sts assume-role --role-arn $ROLE --role-session-name gitlab-configuration)
    mkdir -p ~/.aws
    echo "[datalake]" >> ~/.aws/credentials
    echo "aws_access_key_id=$(echo $AWS_TMP_CONNEXION | jq -r '.Credentials.AccessKeyId')" >> ~/.aws/credentials
    echo "aws_secret_access_key=$(echo $AWS_TMP_CONNEXION | jq -r '.Credentials.SecretAccessKey')" >> ~/.aws/credentials
    echo "aws_session_token=$(echo $AWS_TMP_CONNEXION | jq -r '.Credentials.SessionToken')" >> ~/.aws/credentials
}

# Usage : deploy_generic_stack PROFILE ENVIRONMENT TEMPLATE_PATH
function deploy_generic_stack() {
    PROFILE=$1
    ENV=$2
    TEMPLATE_PATH=$3
    VERSION=$4
    SOURCE=$5

    echo "Deploy cloudformation $TEMPLATE_PATH with parameters PROFILE=$PROFILE ENV=$ENV VERSION=$VERSION SOURCE=$SOURCE"
    if [[ -z "$PROFILE" ]] || [[ -z "$ENV" ]] ; then
        echo "Missing required parameter. PROFILE or ENVIRONMENT is missing"
        exit 3
    fi

    EXEC_PWD=$PWD
    cd "$BASE_PATH/deploy/cloudformation/"
    AWS_PROFILE=$PROFILE sceptre \
      --var-file="variables.default.yaml" \
      --var-file="variables.$ENV.yaml" \
      --var="Version=$VERSION" \
      --var="Source=$SOURCE" \
      launch --yes "$TEMPLATE_PATH"

    cd ${EXEC_PWD}
}

# docker_login PROFILE REGION
function docker_login() {
  PROFILE=$1
  REGION=$2
  REGISTRY=$(AWS_PROFILE=$PROFILE aws cloudformation describe-stacks --region $REGION --stack-name "$ENV-ecr" --query 'Stacks[0].Outputs[?OutputKey==`IngestionWorkflowRegistry`].OutputValue' --output text)

  aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin "$REGISTRY"
}

# build_lambda PROFILE REGION ENV VERSION
function build_lambda() {
  PROFILE=$1
  REGION=$2
  ENV=$3
  VERSION=$4

  echo "Build lambda docker with parameters PROFILE=$PROFILE REGION=$REGION ENV=$ENV VERSION=$VERSION"
  if [[ -z "$PROFILE" ]] || [[ -z "$REGION" ]] || [[ -z "$ENV" ]] || [[ -z "$VERSION" ]] ; then
      echo "Missing required parameter. PROFILE or ENVIRONMENT or REGION or REGION is missing"
      exit 3
  fi

  EXEC_PWD=$PWD
  cd "$BASE_PATH/lambdas/"

  docker_login "$PROFILE" "$REGION"

  REGISTRY=$(AWS_PROFILE=$PROFILE aws cloudformation describe-stacks --region $REGION --stack-name "$ENV-dataplatform-ecr" --query 'Stacks[0].Outputs[?OutputKey==`IngestionWorkflowRegistry`].OutputValue' --output text)
  docker build . -t "$REGISTRY:$VERSION"
  docker tag "$REGISTRY:$VERSION" "$REGISTRY:latest"

  docker push "$REGISTRY:$VERSION"
  docker push "$REGISTRY:latest"

  cd ${EXEC_PWD}
}

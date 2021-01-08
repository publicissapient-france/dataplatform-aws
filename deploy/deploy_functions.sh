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
function install_python_requirements() {
    EXEC_PWD=$PWD
    echo "Install python requirement for $BASE_PATH/api/lambdas"
    cd "$BASE_PATH/api/lambdas"
    pip install -r test_requirements.txt --use-feature=2020-resolver
    pip install -r setup_requirements.txt --use-feature=2020-resolver
    pip install -r requirements.txt --use-feature=2020-resolver

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


# Usage : deploy_cloudformation_exploitation PROFILE ENVIRONMENT
function deploy_cloudformation_lakeformation() {
    PROFILE=$1
    ENV=$2
    echo "Deploy cloudformation for lakeformation with parameters PROFILE=$PROFILE ENV=$ENV"

    if [[ -z "$PROFILE" ]] || [[ -z "$ENV" ]] ; then
        echo "Missing required parameter. PROFILE or ENVIRONMENT is missing"
        exit 3
    fi

    EXEC_PWD=$PWD
    cd "$BASE_PATH/deploy/cloudformation/"
    AWS_PROFILE=$PROFILE sceptre --debug --var-file="variables.default.yaml" --var-file="variables.$ENV.yaml" launch --yes lakeformation/s3.yaml
    AWS_PROFILE=$PROFILE sceptre --debug --var-file="variables.default.yaml" --var-file="variables.$ENV.yaml" launch --yes lakeformation/lakeformation.yaml

    cd ${EXEC_PWD}
}
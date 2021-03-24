#!/bin/bash

set -e

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
export BASE_PATH=$(realpath $SCRIPT_DIR/../)

ACTION=$1
ENVIRONMENT=$2
PACKAGE_VERSION="$(date +%Y%m%d%H%M%S)"

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $DIR/deploy_functions.sh

AWS_REGION=eu-west-1

usage() {
    echo "Run the script with:"
    echo "`basename "$0"` <ACTION> "
    echo ""
    echo "SETUP"
    echo "  - setup-install-lambda-python-requirements: install python requirements in the current virtualenv"
    echo "  - setup-create-virtualenv: create python virtualenv"

    echo ""
    echo "DEPLOY"
    echo "  - deploy-vpc <ENVIRONMENT>: deploy vpc stack"
    echo "  - deploy-lambda-iam: deploy a lambda and a role"

    echo ""
    echo "TP 1"
    echo "  - tp1-deploy-kms <ENVIRONMENT>: deploy KMS key stack"
    echo "  - tp1-deploy-s3 <ENVIRONMENT> <SOURCE>: deploy the s3 stack for a source"
    echo "  - tp1-deploy-ecr <ENVIRONMENT>: deploy ecr"

    echo ""
    echo "TP 2"
    echo "  - tp2-deploy-s3 <ENVIRONMENT> <SOURCE>: deploy the s3 stack for a source"

    echo ""
    echo "TP 3"
    echo "  - tp3-deploy-artifacts <ENVIRONMENT>: deploy s3 bucket to store artifacts"
    echo "  - tp3-deploy-catalog <ENVIRONMENT> <SOURCE>: deploy glue database for the given source"
    echo "  - tp3-deploy-glue <ENVIRONMENT>: deploy glue job on s3 and deploy the cloudformation stack"

    echo ""
    echo "TP 4"
    echo "  - tp4-deploy-custom-s3-notification-custom-resource <ENVIRONMENT>: deploy cloudformation custom resource to register events"
    echo "  - tp4-build-ingestion-workflow <ENVIRONMENT> : build lambda for ingestion workflow"
    echo "  - tp4-deploy-ingestion-workflow <ENVIRONMENT> <VERSION>: deploy the ingestion workflow"

    echo ""
    echo "TP 6"
    echo "  - tp6-deploy-athena-workshop <ENVIRONMENT> <SOURCE>: deploy the athena workflow"

    echo ""
    echo "TP 7"
    echo "  - tp7-deploy-kinesis-workshop : deploy the kinesis stack"

    echo ""
    echo "TP 8"
    echo "  - tp8-deploy-s3-with-backup <ENVIRONMENT> <SOURCE>: deploy the s3 stack for a source with backup configuration"




}

########################################################################################################################
# SETUP
########################################################################################################################
setup-install-lambda-python-requirements() {
    install_lambda_python_requirements
}

setup-create-virtualenv() {
  python3 -m venv ~/.venvs/formation

  echo ""
  echo "Virtualenv '~/.venvs/formation' created. Activate virtualenv with the following command"
  echo "source ~/.venvs/formation/bin/activate"
}


deploy-vpc() {
    ENVIRONMENT=$1
    deploy_generic_stack "$ENVIRONMENT" "infra/vpc.yaml"
}
deploy-lambda-iam() {
    ENVIRONMENT="dev"
    deploy_generic_stack "$ENVIRONMENT" "infra/lambda-iam.yaml"
}


########################################################################################################################
#   TP 1
########################################################################################################################
tp1-deploy-kms() {
    ENVIRONMENT=$1
    deploy_generic_stack "$ENVIRONMENT" "tp1/kms.yaml"
}
tp1-deploy-s3() {
    ENVIRONMENT=$1
    SOURCE=$2
    if [[ -z "$SOURCE" ]] ; then
        echo "Missing required parameter SOURCE"
        exit 3
    fi

    deploy_generic_stack "$ENVIRONMENT" "tp1/s3.yaml" "" "$SOURCE"
}
tp1-deploy-ecr() {
    ENVIRONMENT=$1
    deploy_generic_stack "$ENVIRONMENT" "tp1/ecr.yaml"
}


########################################################################################################################
#   TP 2
########################################################################################################################
tp2-deploy-s3() {
    ENVIRONMENT=$1
    SOURCE=$2
    if [[ -z "$SOURCE" ]] ; then
        echo "Missing required parameter SOURCE"
        exit 3
    fi

    deploy_generic_stack "$ENVIRONMENT" "tp2/reponses/s3.yaml" "" "$SOURCE"
}

########################################################################################################################
#   TP 3
########################################################################################################################
tp3-deploy-artifacts() {
    ENVIRONMENT=$1

    deploy_generic_stack "$ENVIRONMENT" "tp3/artifacts.yaml"
}

tp3-deploy-catalog() {
    ENVIRONMENT=$1
    SOURCE=$2
    if [[ -z "$SOURCE" ]] ; then
        echo "Missing required parameter SOURCE"
        exit 3
    fi

    deploy_generic_stack "$ENVIRONMENT" "tp3/catalog.yaml" "" "$SOURCE"
}

tp3-deploy-glue() {
    ENVIRONMENT=$1
    deploy_glue_job "$ENVIRONMENT"
    deploy_generic_stack "$ENVIRONMENT" "tp3/glue.yaml"
}

########################################################################################################################
#   TP 4
########################################################################################################################
tp4-deploy-custom-s3-notification-custom-resource() {
    ENVIRONMENT=$1
    deploy_generic_stack "$ENVIRONMENT" "tp4/s3-notification-updater.yaml"
}

tp4-build-ingestion-workflow() {
    ENVIRONMENT=$1
    build_lambda "$AWS_REGION" "$ENVIRONMENT" "$PACKAGE_VERSION"
    display_version "$VERSION"
}

tp4-deploy-ingestion-workflow() {
    ENVIRONMENT=$1
    VERSION=$2
    deploy_generic_stack "$ENVIRONMENT" "tp4/ingestion.yaml" "$VERSION"
    display_version "$VERSION"
}
tp4-build-and-deploy-ingestion-workflow() {
    ENVIRONMENT=$1
    tp4-build-ingestion-workflow "$ENVIRONMENT"
    tp4-deploy-ingestion-workflow "$ENVIRONMENT" "$PACKAGE_VERSION"
}


########################################################################################################################
#   TP 6
########################################################################################################################
tp6-deploy-athena-workshop() {
    ENVIRONMENT=$1
    SOURCE=$2
    if [[ -z "$SOURCE" ]] ; then
        echo "Missing required parameter SOURCE"
        exit 3
    fi
    deploy_generic_stack "$ENVIRONMENT" "tp6/athena-ctas.yaml" "" "$SOURCE"
}


########################################################################################################################
#   TP 7
########################################################################################################################
tp7-deploy-kinesis-workshop() {
    ENVIRONMENT=$1
    deploy_generic_stack "$ENVIRONMENT" "tp7/kinesis.yaml" "" ""
}


########################################################################################################################
#   TP 8
########################################################################################################################
tp8-deploy-s3-with-backup() {
    ENVIRONMENT=$1
    SOURCE=$2
    if [[ -z "$SOURCE" ]] ; then
        echo "Missing required parameter SOURCE"
        exit 3
    fi

    deploy_generic_stack "$ENVIRONMENT" "tp8/s3.yaml" "" "$SOURCE"
}



fn_exists() {
    [[ `type -t $1`"" == 'function' ]]
}

main() {

    if [[ -n "${ACTION}" ]]; then
        echo
    else
        usage
        exit 1
    fi

    if ! fn_exists ${ACTION}; then
        echo "Error: ${ACTION} is not a valid ACTION"
        usage
        exit 2
    fi

    # Execute action
    ${ACTION} "${@:2}"
}

main "$@"
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
    echo "  - deploy-lakeformation <ENVIRONMENT>: deploy lakeformation stack"
    echo "  - deploy-vpc <ENVIRONMENT>: deploy vpc stack"

    echo ""
    echo "TP 1"
    echo "  - tp1-deploy-kms <ENVIRONMENT>: deploy KMS key stack"
    echo "  - tp1-deploy-s3 <ENVIRONMENT> <SOURCE>: deploy the s3 stack for a source"
    echo "  - tp1-deploy-ecr: deploy ecr"

    echo ""
    echo "TP 3"
    echo "  - tp3-deploy-custom-s3-notification-custom-resource <ENVIRONMENT>: deploy cloudformation custom resource to register events"
    echo "  - tp3-build-ingestion-workflow <ENVIRONMENT> : build lambda for ingestion workflow"
    echo "  - tp3-deploy-ingestion-workflow <ENVIRONMENT>: deploy the ingestion workflow"


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

deploy-lakeformation() {
    ENVIRONMENT=$1
    deploy_cloudformation_lakeformation "$AWS_PROFILE" "$ENVIRONMENT"
}

deploy-vpc() {
    ENVIRONMENT=$1
    deploy_generic_stack "$AWS_PROFILE" "$ENVIRONMENT" "infra/vpc.yaml"
}


########################################################################################################################
#   TP 1
########################################################################################################################
tp1-deploy-kms() {
    ENVIRONMENT=$1
    deploy_generic_stack "$AWS_PROFILE" "$ENVIRONMENT" "tp1/kms.yaml"
}
tp1-deploy-s3() {
    ENVIRONMENT=$1
    SOURCE=$2
    if [[ -z "$SOURCE" ]] ; then
        echo "Missing required parameter SOURCE"
        exit 3
    fi

    deploy_generic_stack "$AWS_PROFILE" "$ENVIRONMENT" "tp1/s3.yaml" "" "$SOURCE"
}
tp1-deploy-ecr() {
    ENVIRONMENT="dev"
    deploy_generic_stack "$AWS_PROFILE" "$ENVIRONMENT" "tp1/ecr.yaml"
}

########################################################################################################################
#   TP 3
########################################################################################################################
tp3-deploy-custom-s3-notification-custom-resource() {
    ENVIRONMENT=$1
    deploy_generic_stack "$AWS_PROFILE" "$ENVIRONMENT" "tp3/s3-notification-updater.yaml"
}

tp3-build-ingestion-workflow() {
    build_lambda "$AWS_PROFILE" "$AWS_REGION" "$ENVIRONMENT" "$PACKAGE_VERSION"
}

tp3-deploy-ingestion-workflow() {
    ENVIRONMENT=$1
    VERSION=$2
    deploy_generic_stack "$AWS_PROFILE" "$ENVIRONMENT" "tp3/ingestion.yaml" "$VERSION"
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
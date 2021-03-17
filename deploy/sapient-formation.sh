#!/bin/bash

set -e

SCRIPT_PATH=$(realpath $0)
SCRIPT_DIR=$(dirname $SCRIPT_PATH)
export BASE_PATH=$(realpath $SCRIPT_DIR/../)

ACTION=$1
ENVIRONMENT=$2

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source $DIR/deploy_functions.sh

usage() {
    echo "Run the script with:"
    echo "`basename "$0"` <ACTION> "
    echo ""
    echo "SETUP"
    echo "  - setup-install-python-requirements: install python requirements in the current virtualenv"
    echo "  - setup-create-virtualenv: create python virtualenv"


    echo ""
    echo "DEPLOY"
    echo "  - deploy-lakeformation <ENVIRONMENT>: deploy lakeformation stack"
    echo "  - deploy-vpc <ENVIRONMENT>: deploy vpc stack"
    echo "  - deploy-glue-job <ENVIRONMENT>: deploy glue job resources"

    echo ""
    echo "DATA"
    echo "  - upload-titanic-data <ENVIRONMENT>: deploy glue job resources"


}

########################################################################################################################
# SETUP
########################################################################################################################
setup-install-python-requirements() {
    install_python_requirements
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
    deploy_cloudformation_vpc "$AWS_PROFILE" "$ENVIRONMENT"
}

deploy-glue-job() {
    ENVIRONMENT=$1
    deploy_glue_job "$AWS_PROFILE" "$ENVIRONMENT"
}

upload-titanic-data() {
    ENVIRONMENT=$1
    upload_titanic_data "$AWS_PROFILE" "$ENVIRONMENT"
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
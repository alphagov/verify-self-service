#!/usr/bin/env bash

set -e

STACK_NAME=SelfService
BUCKET=verify-self-service-lambda

sam package --template-file template.yml --output-template-file packaged-template.yaml --s3-bucket $BUCKET
sam deploy --template-file packaged-template.yaml --stack-name $STACK_NAME --capabilities CAPABILITY_IAM
# get API endpoint
API_ENDPOINT=$(aws cloudformation describe-stacks --stack-name $STACK_NAME --query 'Stacks[0].Outputs[0].OutputValue')

# remove quotes
API_ENDPOINT=$(sed -e 's/^"//' -e 's/"$//' <<< $API_ENDPOINT)

echo "Test in browser: $API_ENDPOINT"

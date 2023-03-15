#!/usr/bin/env bash
# this script takes output from terraform and saves it to an env file to build our react frontend with
# it then executes the build and terraform will take over and upload the build to s3

set -e

API_URL=$(jq -r '.API_URL')

echo "VITE_API_URL=$API_URL" > .env.local

# build vite and also echo the destination folder "dist" for terraform to use
# redirect output to err stream since terraform will latch onto the first stdout output for a response
(npm ci && npm run build) >&2 

# create a json object to pass back to terraform
# echo -n "{\"dest\": \"dist\"}"
jq -n --arg dest dist '{"dest":"dist"}'
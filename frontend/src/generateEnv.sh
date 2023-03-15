#!/bin/bash
# this script takes output from terraform and saves it to an env file to build our react frontend with
# it then executes the build and terraform will take over and upload the build to s3

set -e

API_URL=$(jq -r '.testjsonkey')

echo "VITE_API_URL=$API_URL" > .env.local
npm ci && npm run build >&2 && echo "{\"dest\": \"dist\"}"
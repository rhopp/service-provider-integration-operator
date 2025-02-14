#!/bin/bash
#
# Copyright (C) 2021 Red Hat, Inc.
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#         http://www.apache.org/licenses/LICENSE-2.0
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

set -e
echo "Testing token injection"

SPI_URL=$(minikube service  service-provider-integration-api  --url -n vault)
echo $SPI_URL
curl -d '{"token":"github_token_here", "name":"some-service-token"}' -H "Content-Type: application/json" -X POST $SPI_URL/api/v1/token
kubectl create namespace usr-1 --dry-run=client -o yaml | kubectl apply -f -


cat <<EOF | kubectl apply -n usr-1 -f -
apiVersion: appstudio.redhat.com/v1beta1
kind: AccessTokenSecret
metadata:
  name: ats
spec:
  accessTokenName: some-service-token
  target:
    secret:
        name: spi-data
        fields:
          token: GITHUB_TOKEN
        labels:
          yiee: haa
EOF
sleep 10
INJECTED_VALUE=$(kubectl get secret spi-data -n usr-1 -o jsonpath='{.data.GITHUB_TOKEN}' | base64 -d)
if [ $INJECTED_VALUE = "github_token_here" ]; then
   echo "injected value "$INJECTED_VALUE
   exit 0
else
  echo "fail to inject value."
  echo "INJECTED_VALUE="$INJECTED_VALUE
  echo "vault events"
  kubectl get events --sort-by=.metadata.creationTimestamp -n vault
  echo "spi-system events"
  kubectl get events --sort-by=.metadata.creationTimestamp -n spi-system
  echo "operator logs"
  kubectl logs -n spi-system deployment/spi-controller-manager -c manager
  echo "SPI API logs"
  kubectl logs -n vault deployment/service-provider-integration-api -c service-provider-integration-api
  exit 1
fi


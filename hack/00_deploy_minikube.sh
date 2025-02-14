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
echo "Starting SPI on minikube"
cwd=$(pwd)
tmp_dir=$(mktemp -d -t service-provider-integration-api-XXXXXXXXXX)
echo $tmp_dir
git clone https://github.com/redhat-appstudio/service-provider-integration-api $tmp_dir
$tmp_dir/scripts/fast_01_06.sh
rm -rf $tmp_dir
cd $cwd
echo "SPI started on minikube"
TAG=$(date '+%Y_%m_%d_%H_%M_%S')
export SPIO_IMG=quay.io/skabashn/service-provider-integration-operator:$TAG
echo $SPIO_IMG
echo "Building docker image "$SPIO_IMG
make docker-build
echo "Uploading "$SPIO_IMG" to minikube"
minikube image load $SPIO_IMG
echo "Installing operator configuration"
make install
echo "Deploying operator"
make deploy


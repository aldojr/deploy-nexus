#!/bin/bash


RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'


VolumeDIR=/var/lib/docker/volumes/
image=$(sed -n 's/^[[:space:]]*image:[[:space:]]*//p' docker-compose.yml)
container_name="nexus-repo_nexus_1"

echo "${YELLOW}${BOLD}[✓] Create directory for docker volume"

mkdir $VolumeDIR/nexus-repo_docker-registry-dev && chmod -R 777 $VolumeDIR/nexus-repo_docker-registry-dev
mkdir $VolumeDIR/nexus-repo_docker-registry-test && chmod -R 777 $VolumeDIR/nexus-repo_docker-registry-test

echo "Running docker compose Nexus repository with image $image"
docker-compose down
docker-compose up -d

echo "${YELLOW}${BOLD}[✓] Waiting Nexus container ready..."

until docker logs "$container_name" 2>&1 | grep -q "Started Sonatype Nexus"; do
  echo "Waiting Nexus Repo ready..."
  sleep 5
done

echo "${GREEN}${BOLD}[✓] Nexus Running. Continue Configur blobstore and registry..."

send_request() {
  description="$1"
  shift
  echo "${CYAN}${BOLD}[✓] $description..."
  response=$(curl -s -o /tmp/response.json -w "%{http_code}" "$@")
  if [[ "$response" == 2* ]]; then
    echo "${CYAN}${BOLD}[✓] $description Done."
  else
    echo "${RED}${BOLD}[✗] $description Failed. Status code: $response"
    echo "🔍 Response:"
    cat /tmp/response.json
    exit 1
  fi
}

# Create blobstore
send_request "Membuat Blobstore" -X POST "http://192.168.0.8:8081/service/rest/v1/blobstores/file" \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/mnt/docker-registry-dev",
    "name": "docker-registry-dev"
}'

send_request "Membuat Blobstore" -X POST "http://192.168.0.8:8081/service/rest/v1/blobstores/file" \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/mnt/docker-registry-test",
    "name": "docker-registry-test"
}'

# Create Docker registry
send_request "Membuat Docker Registry" -X POST "http://192.168.0.8:8081/service/rest/v1/repositories/docker/hosted" \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
  "name": "docker-registry-dev",
  "online": true,
  "storage": {
    "blobStoreName": "docker-registry-dev",
    "strictContentTypeValidation": true,
    "writePolicy": "ALLOW"
  },
  "cleanup": null,
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": false,
    "httpPort": 5000,
    "httpsPort": null,
    "subdomain": null
  },
  "component": {
    "proprietaryComponents": false
  }
}'

send_request "Membuat Docker Registry" -X POST "http://192.168.0.8:8081/service/rest/v1/repositories/docker/hosted" \
  -u admin:admin123 \
  -H "Content-Type: application/json" \
  -d '{
  "name": "docker-registry-test",
  "online": true,
  "storage": {
    "blobStoreName": "docker-registry-test",
    "strictContentTypeValidation": true,
    "writePolicy": "ALLOW"
  },
  "cleanup": null,
  "docker": {
    "v1Enabled": false,
    "forceBasicAuth": false,
    "httpPort": 5001,
    "httpsPort": null,
    "subdomain": null
  },
  "component": {
    "proprietaryComponents": false
  }
}'

echo "🚀 All Configuration running well !"

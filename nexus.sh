#!/bin/bash

NEXUS_USER="admin"
NEXUS_PASS="admin123"
NEXUS_URL="http://localhost:8081"


RED='\033[0;31m'
GREEN='\033[0;32m'
PURPLE='\033[0;95m'
BLUE='\033[0;94m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

timeout=300
elapsed=0
interval=5

VolumeDIR=/var/lib/docker/volumes/
image=$(sed -n 's/^[[:space:]]*image:[[:space:]]*//p' docker-compose.yml)
container_name="nexus-repo_nexus_1"

echo -e "${YELLOW}${BOLD}[✓] Create directory for docker volume"

docker volume create nexus-repo_docker-registry-dev
docker volume create nexus-repo_docker-registry-test

chmod -R 777 $VolumeDIR/nexus-repo_docker-registry-dev
chmod -R 777 $VolumeDIR/nexus-repo_docker-registry-test

echo -e "Running docker compose Nexus repository with image $image"
docker-compose down
sleep 5
docker-compose up -d

echo -e "${YELLOW}${BOLD}[✓] Waiting Nexus container ready..."

until docker logs "$container_name" 2>&1 | grep -q "Started Sonatype Nexus"; do
  echo -e "Waiting Nexus Repo ready..."
  sleep $interval
  ((elapsed+=interval))
  if [ "$elapsed" -ge "$timeout" ]; then
    echo -e "${RED}${BOLD}[✗] Timeout"
    exit 1
  fi
done

echo -e "${GREEN}${BOLD}[✓] Nexus Running. Continue Configure blobstore and registry..."

send_request() {
  description="$1"
  shift
  echo -e "${CYAN}${BOLD}[✓] $description..."
  response=$(curl -s -o /tmp/response.json -w "%{http_code}" "$@")
  if [[ "$response" == 2* ]]; then
    echo -e "${CYAN}${BOLD}[✓] $description Done."
  else
    echo -e "${RED}${BOLD}[✗] $description Failed. Status code: $response"
    echo -e "🔍 Response:"
    cat /tmp/response.json
    exit 1
  fi
}

send_request "Enable Anonymous" -X PUT "$NEXUS_URL/service/rest/v1/security/anonymous" \
  -u $NEXUS_USER:$NEXUS_PASS \
  -H "Content-Type: application/json" \
  -d '{
  "enabled" : true,
  "userId" : "anonymous",
  "realmName" : "NexusAuthorizingRealm"
}'

# Create blobstore
send_request "Membuat Blobstore dev" -X POST "$NEXUS_URL/service/rest/v1/blobstores/file" \
  -u $NEXUS_USER:$NEXUS_PASS \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/mnt/docker-registry-dev",
    "name": "docker-registry-dev"
}'

send_request "Create Blobstore test" -X POST "$NEXUS_URL/service/rest/v1/blobstores/file" \
  -u $NEXUS_USER:$NEXUS_PASS \
  -H "Content-Type: application/json" \
  -d '{
    "path": "/mnt/docker-registry-test",
    "name": "docker-registry-test"
}'

# Create Docker registry
send_request "Create Docker Registry dev" -X POST "$NEXUS_URL/service/rest/v1/repositories/docker/hosted" \
  -u $NEXUS_USER:$NEXUS_PASS \
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

send_request "Membuat Docker Registry test" -X POST "$NEXUS_URL/service/rest/v1/repositories/docker/hosted" \
  -u $NEXUS_USER:$NEXUS_PASS \
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

send_request "Add NexusAuthentication and DockerToken" -X PUT "$NEXUS_URL/service/rest/v1/security/realms/active" \
  -u $NEXUS_USER:$NEXUS_PASS \
  -H "Content-Type: application/json" \
  -d '[ "NexusAuthenticatingRealm", "DockerToken" ]'

echo -e "🚀 All Configuration running well !"

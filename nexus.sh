#!/bin/bash

# Ambil image dari docker-compose.yml
image=$(sed -n 's/^[[:space:]]*image:[[:space:]]*//p' docker-compose.yml)

echo "Running docker compose Nexus repository dengan image $image"
docker-compose down
docker-compose up -d

echo "Menunggu Nexus container siap..."

# Nama container Nexus (pastikan ini benar sesuai hasil docker ps)
container_name="nexus-repo_nexus_1"

# Tunggu sampai log Nexus menunjukkan sudah siap
until docker logs "$container_name" 2>&1 | grep -q "Started Sonatype Nexus"; do
  echo "Menunggu Nexus siap..."
  sleep 5
done

echo "Nexus sudah berjalan. Melanjutkan konfigurasi blobstore dan registry..."

# Fungsi untuk kirim request dan cek error
send_request() {
  description="$1"
  shift
  echo "🔧 $description..."
  response=$(curl -s -o /tmp/response.json -w "%{http_code}" "$@")
  if [[ "$response" == 2* ]]; then
    echo "✅ $description berhasil."
  else
    echo "❌ $description gagal. Status code: $response"
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

echo "🚀 Semua konfigurasi berhasil!"

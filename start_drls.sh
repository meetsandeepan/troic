#!/bin/bash

# Function to check if a service is running by attempting a curl request
check_service() {
  local url=$1
  local description=$2
  echo "Checking $description..."
  if curl -s "$url" > /dev/null; then
    echo "$description is running!"
  else
    echo "Failed to verify $description. Please check manually."
  fi
}

# Start CRD
echo "Starting CRD..."
cd /Users/sandy/code/troic/crd || exit
gradle bootRun & # Run in background
sleep 30 # Allow time for the service to initialize
check_service "http://localhost:8090" "CRD main page"
check_service "http://localhost:8090/data" "CRD data"

# Start test-ehr
echo "Starting test-ehr..."
cd ../test-ehr || exit
rm -rf target build
gradle bootRun & # Run in background
sleep 30
gradle loadData
check_service "http://localhost:8080/test-ehr/r4/Patient" "test-ehr patient resource"

# Start keycloak
echo "Starting Keycloak..."
docker run --name keycloak -p 8180:8080 --rm -e DB_VENDOR=h2 -e KEYCLOAK_USER=admin -e KEYCLOAK_PASSWORD=admin hkong2/keycloak & # Run in background
sleep 30
check_service "http://localhost:8180" "Keycloak login page"

# Start DTR
echo "Starting DTR..."
cd ../dtr || exit
npm install
npm start & # Run in background
sleep 30
check_service "http://localhost:3005/register" "DTR registration page"

# Start CRD Request Generator
echo "Starting CRD Request Generator..."
cd ../crd-request-generator || exit
npm install
PORT=3000 npm start & # Run in background
sleep 30
check_service "http://localhost:3000/ehr-server/reqgen" "CRD Request Generator webpage"

# Optional: Reload EHR data if necessary
echo "Reloading EHR data (if applicable)..."
cd ../test-ehr || exit
gradle loadData

echo "All services have been started and verified where possible."

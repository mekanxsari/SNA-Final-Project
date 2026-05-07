#!/bin/bash

echo "========================================="
echo " Static Web Cluster Cleanup"
echo "========================================="

echo "Stopping containers..."
docker-compose down -v --rmi local 2>/dev/null || docker compose down -v --rmi local 2>/dev/null

echo "Removing all containers..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "Removing generated files..."
rm -rf apps temp_repo nginx docker-compose.yml

echo "Removing images..."
docker rmi -f $(docker images -q) 2>/dev/null || true

echo ""
echo "Cleanup complete!"
echo ""
echo "Remaining containers:"
docker ps
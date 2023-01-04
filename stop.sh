#clear previous network
docker-compose -f explorer/docker-compose.yaml down -v
docker-compose -f docker-compose-byfn.yaml down -v
rm -rf channel-artifacts
rm -rf crypto-config
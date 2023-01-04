#clear previous network
docker-compose -f explorer/docker-compose.yaml down -v
docker-compose -f docker-compose-byfn.yaml down -v
rm -rf channel-artifacts
rm -rf crypto-config
#generate crypto materials
./bin/cryptogen generate --config=./crypto-config.yaml
#create channel materials
mkdir channel-artifacts
#generate genesis block
./bin/configtxgen -profile TwoOrgsOrdererGenesis -channelID byfn-sys-channel -outputBlock ./channel-artifacts/genesis.block
#generate channel config
./bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID mychannel
#generate anchor peer config
./bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org1MSPanchors.tx -channelID mychannel -asOrg Org1MSP
./bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Org2MSPanchors.tx -channelID mychannel -asOrg Org2MSP

#boot containers
docker-compose -f docker-compose-byfn.yaml up -d 

peer0org1="CORE_PEER_LOCALMSPID="Org1MSP" CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp CORE_PEER_ADDRESS=peer0.org1.example.com:7051"
peer1org1="CORE_PEER_LOCALMSPID="Org1MSP" CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp CORE_PEER_ADDRESS=peer1.org1.example.com:8051"
peer0org2="CORE_PEER_LOCALMSPID="Org2MSP" CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer0.org2.example.com:9051"
peer1org2="CORE_PEER_LOCALMSPID="Org2MSP" CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp CORE_PEER_ADDRESS=peer1.org2.example.com:10051"

docker exec cli bash -c "$peer0org1 peer channel create -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/channel.tx"

#make all peers join channel
docker exec cli bash -c "$peer0org1 peer channel join -b mychannel.block"
docker exec cli bash -c "$peer1org1 peer channel join -b mychannel.block"
docker exec cli bash -c "$peer0org2 peer channel join -b mychannel.block"
docker exec cli bash -c "$peer1org2 peer channel join -b mychannel.block"

#upfdate anchor peers
docker exec cli bash -c "$peer0org1 peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org1MSPanchors.tx"
docker exec cli bash -c "$peer0org2 peer channel update -o orderer.example.com:7050 -c mychannel -f ./channel-artifacts/Org2MSPanchors.tx"

#install chaincode only on endoser peer
docker exec cli bash -c "$peer0org1 peer chaincode install -n mycc -v 1.0 -l golang -p github.com/chaincode" 
docker exec cli bash -c "$peer0org2 peer chaincode install -n mycc -v 1.0 -l golang -p github.com/chaincode"

#instantiate chaincode (important)  and endorer policy
docker exec cli bash -c "$peer0org1 peer chaincode instantiate -o orderer.example.com:7050  -C mychannel -n mycc -l golang -v 1.0 -c '{\"Args\":[\"init\",\"a\",\"100\",\"b\",\"200\"]}' -P 'AND ('\''Org1MSP.peer'\'','\''Org2MSP.peer'\'')'"
sleep 5
#query test on peer0org1
docker exec cli bash -c "peer chaincode query -C mychannel -n mycc -c '{\"Args\":[\"query\",\"a\"]}'"

#invoke test 
docker exec cli bash -c "peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc --peerAddresses peer0.org1.example.com:7051 --peerAddresses peer0.org2.example.com:9051 -c '{\"Args\":[\"invoke\",\"a\",\"b\",\"10\"]}'"
#wait block commit
sleep 5
#query test on peer1org1
docker exec cli bash -c "peer chaincode query -C mychannel -n mycc -c '{\"Args\":[\"query\",\"a\"]}'"

#boot hyperledger explorer
#replace keys for hyperledger explorer
priv_sk=$(ls crypto-config/peerOrganizations/org1.example.com/users/User1@org1.example.com/msp/keystore)
cp -rf ./explorer/connection-profile/test-network-temp.json ./explorer/connection-profile/test-network.json
sed -i "s/priv_sk/$priv_sk/" ./explorer/connection-profile/test-network.json
docker-compose -f explorer/docker-compose.yaml up -d

#replace keys for tape
#chaincode benchmark command：./tape --config=config.yaml --number=100
cp -rf ./tape/config-temp.yaml ./tape/config.yaml
sed -i "s/priv_sk/$priv_sk/" ./tape/config.yaml



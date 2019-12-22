#!/bin/bash

## Make sure network is up
## Make sure certificates are generated using cryptogen
## Make sure you are executing this script in cli
## docker exec -it cli bash

export ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
export CHANNEL_NAME=byfn-sys-channel

CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/users/Admin@example.com/msp
CORE_PEER_ADDRESS=orderer.example.com:7050
CORE_PEER_LOCALMSPID=OrdererMSP
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/tls/ca.crt


peer channel fetch config config_block.pb -c $CHANNEL_NAME -o $CORE_PEER_ADDRESS  --tls --cafile $ORDERER_CA

configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config > config.json

#### Add Org into Consortium ######
jq -s '.[0] * {"channel_group":{"groups":{"Consortiums":{"groups": {"SampleConsortium": {"groups": {"Org3MSP":.[1]}}}}}}}' config.json ./channel-artifacts/org3.json > modified_config.json

#### Delete Org from Consortium ######
# cat config.json | jq "del(.channel_group.groups.Consortiums.groups.SampleConsortium.groups.Org3MSP)" > modified_config.json

#### Add Organization to channel #####
#jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org3MSP":.[1]}}}}}' config.json ./channel-artifacts/org3.json > modified_config.json

#### Delete Oraganization from channel ####
#jq 'del(.channel_group.groups.Application.groups.Org3MSP)' config.json > modified_config.json


configtxlator proto_encode --input config.json --type common.Config --output config.pb

configtxlator proto_encode --input modified_config.json --type common.Config --output modified_config.pb

configtxlator compute_update --channel_id $CHANNEL_NAME --original config.pb --updated modified_config.pb --output org3_update.pb

configtxlator proto_decode --input org3_update.pb --type common.ConfigUpdate | jq . > org3_update.json

echo '{"payload":{"header":{"channel_header":{"channel_id":"$CHANNEL_NAME", "type":2}},"data":{"config_update":'$(cat org3_update.json)'}}}' | jq . > org3_update_in_envelope.json

configtxlator proto_encode --input org3_update_in_envelope.json --type common.Envelope --output org3_update_in_envelope.pb


peer channel signconfigtx -f org3_update_in_envelope.pb

peer channel update -f org3_update_in_envelope.pb -c $CHANNEL_NAME -o $CORE_PEER_ADDRESS --tls --cafile $ORDERER_CA

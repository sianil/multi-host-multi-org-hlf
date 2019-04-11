## Build multi host multi vm fabric network

####Pre-requisites :

1 #### Install Go1.9 
curl -O https://storage.googleapis.com/golang/go1.11.2.linux-amd64.tar.gz
tar -xvf go1.11.2.linux-amd64.tar.gz
sudo mv go /usr/local
sudo nano ~/.profile
export GOPATH=$HOME/work
export PATH=$PATH:/usr/local/go/bin:$GOPATH/bin

2. #### Install npm 
### Check if node is already installed by node -v command
### Follow below sequence to install NodeJs on Ubuntu 16.04( For other operating systems installations steps please follow Starter Kit ReadMe file)
sudo apt install curl
curl -sL https://deb.nodesource.com/setup_10.x | sudo bash -
sudo apt install nodejs

3. #### Upgrade npm if required by the following command:

sudo npm install npm@5.6.0 -g

4. #### Install Python
sudo apt-get install python

5. #### Install Docker
sudo apt-get update
sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
 curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
 sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
 
sudo apt-get update
sudo apt-get install docker-ce

6. ###### Install Docker Compose
sudo apt-get install docker-compose

7. #### Get the fabric-sample
git clone https://github.com/hyperledger/fabric-samples.git
cd  fabric-samples
git checkout release-1.3
curl -sSL http://bit.ly/2ysbOFE | sudo bash -s 1.3.0 1.3.0 0.4.13

8. #### export tools in PATH
export PATH=$PATH:~/fabric-samples/bin

==================== Pre requisites end ======================


Step 1: Setup the overlay network using swarm - PC1, please ensure the vpc peeering in case of AWS

docker swarm init
docker network create --attachable --driver overlay my-net

Step 2: Checkout the project - PC1

sudo git clone https://github.com/wahabjawed/Build-Multi-Host-Network-Hyperledger.git
sudo chown -R ubuntu:ubuntu Build-Multi-Host-Network-Hyperledger
cd Build-Multi-Host-Network-Hyperledger

Step 3. Generate crypto material and config transaction for Org1 - PC1

./bmhn.sh

Step 4: ## **** Copy crypto materials to PC2 - run this command from PC1
scp -r Build-Multi-Host-Network-Hyperledger/ ubuntu@<PC2 DNS>:/home/ubuntu

Ste 5: Run all the containers for Org1 - peer0 from PC1
cd crypto-config/peerOrganizations/org1.example.com/ca/

-- replace *_sk in below command from above directory.
############# Please run all the commands fromm root folder of the project ~/Build-Multi-Host-Network-Hyperledger

### Change fabric-ca-server-config 1a98d3fb0a7bdd3355b1829d309f92c37046b5ccedc681eee4e1d70dbfa91b8c_sk
Step 5.1. CA Server:
docker run --rm -it --network="my-net" --name ca.example.com -p 7054:7054 -e FABRIC_CA_HOME=/etc/hyperledger/fabric-ca-server -e FABRIC_CA_SERVER_CA_NAME=ca.example.com -e FABRIC_CA_SERVER_CA_CERTFILE=/etc/hyperledger/fabric-ca-server-config/ca.org1.example.com-cert.pem -e FABRIC_CA_SERVER_CA_KEYFILE=/etc/hyperledger/fabric-ca-server-config/<REPLCAE THIS from Previous step> -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/ca/:/etc/hyperledger/fabric-ca-server-config -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=hyp-net hyperledger/fabric-ca sh -c 'fabric-ca-server start -b admin:adminpw -d'

Step 5.2. Orderer
docker run --rm -it --network="my-net" --name orderer.example.com -p 7050:7050 -e ORDERER_GENERAL_LOGLEVEL=debug -e ORDERER_GENERAL_LISTENADDRESS=0.0.0.0 -e ORDERER_GENERAL_LISTENPORT=7050 -e ORDERER_GENERAL_GENESISMETHOD=file -e ORDERER_GENERAL_GENESISFILE=/var/hyperledger/orderer/orderer.genesis.block -e ORDERER_GENERAL_LOCALMSPID=OrdererMSP -e ORDERER_GENERAL_LOCALMSPDIR=/var/hyperledger/orderer/msp -e ORDERER_GENERAL_TLS_ENABLED=false -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net -v $(pwd)/channel-artifacts/genesis.block:/var/hyperledger/orderer/orderer.genesis.block -v $(pwd)/crypto-config/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp -w /opt/gopath/src/github.com/hyperledger/fabric hyperledger/fabric-orderer orderer

Step 5.3. CouchDB 0 — for Peer 0
docker run --rm -it --network="my-net" --name couchdb0 -p 5984:5984 -e COUCHDB_USER= -e COUCHDB_PASSWORD= -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net hyperledger/fabric-couchdb

Step 5.4. Peer 0
docker run --rm -it --link orderer.example.com:orderer.example.com --network="my-net" --name peer0.org1.example.com -p 8051:7051 -p 8053:7053 -e CORE_LEDGER_STATE_STATEDATABASE=CouchDB -e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb0:5984 -e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME= -e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD= -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_NETWORKID=peer0.org1.example.com -e CORE_NEXT=true -e CORE_PEER_ENDORSER_ENABLED=true -e CORE_PEER_ID=peer0.org1.example.com -e CORE_PEER_PROFILE_ENABLED=true -e CORE_PEER_COMMITTER_LEDGER_ORDEaRER=orderer.example.com:7050 -e CORE_PEER_GOSSIP_IGNORESECURITY=true -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org1.example.com:7051 -e CORE_PEER_TLS_ENABLED=false -e CORE_PEER_GOSSIP_USELEADERELECTION=false -e CORE_PEER_GOSSIP_ORGLEADER=true -e CORE_PEER_LOCALMSPID=Org1MSP -v /var/run/:/host/var/run/ -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/msp:/etc/hyperledger/fabric/msp -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-peer peer node start


Step 6 : ### Login to PC2 where you have already copied the root project folder as part of Step 4 - PC2

step 6.1. CouchDB 1 — for Peer 1 - PC2
docker run --rm -it --network="my-net" --name couchdb1 -p 6984:5984 -e COUCHDB_USER= -e COUCHDB_PASSWORD= -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net hyperledger/fabric-couchdb

step 6.2. Peer 1 (PC2)
docker run --rm -it --network="my-net" --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --name peer1.org1.example.com -p 9051:7051 -p 9053:7053 -e CORE_LEDGER_STATE_STATEDATABASE=CouchDB -e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb1:5984 -e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME= -e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD= -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_NETWORKID=peer1.org1.example.com -e CORE_NEXT=true -e CORE_PEER_ENDORSER_ENABLED=true -e CORE_PEER_ID=peer1.org1.example.com -e CORE_PEER_PROFILE_ENABLED=true -e CORE_PEER_COMMITTER_LEDGER_ORDERER=orderer.example.com:7050 -e CORE_PEER_GOSSIP_ORGLEADER=true -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer1.org1.example.com:7051 -e CORE_PEER_GOSSIP_IGNORESECURITY=true -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net -e CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org1.example.com:7051 -e CORE_PEER_GOSSIP_USELEADERELECTION=false -e CORE_PEER_TLS_ENABLED=false -v /var/run/:/host/var/run/ -v $(pwd)/crypto-config/peerOrganizations/org1.example.com/peers/peer1.org1.example.com/msp:/etc/hyperledger/fabric/msp -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-peer peer node start

Step 7 : Create cli for Org1 - peer0 : (PC1)

docker run --rm -it --network="my-net" --name cli --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --link peer1.org1.example.com:peer1.org1.example.com -p 12051:7051 -p 12053:7053 -e GOPATH=/opt/gopath -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_TLS_ENABLED=false -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_ID=cli -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 -e CORE_PEER_NETWORKID=cli -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net  -v /var/run/:/host/var/run/ -v $(pwd)/chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go -v $(pwd)/crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ -v $(pwd)/scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/ -v $(pwd)/channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-tools /bin/bash

Step 8 :  ### - Create channel , All peer to joinChannel , Set the anchor peers for each org in the channel, Install chaincode on Peer0/Org1 and Peer1/Org1
on PC1 :

docker exec -it cli /bin/bash

./scripts/script.sh

// you should see the END message

Step 9 : Instantisate chaincode :
 ====   # Environment variables for PEER0 =====================
#### ON PC1 for peer 0
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
CORE_PEER_ADDRESS=peer0.org1.example.com:7051

### Be careful with endorsement policies
peer chaincode instantiate -o orderer.example.com:7050 -C mychannel -n mycc -v 1.0 -c '{"Args":["init","a","100","b","200"]}' -P "OR ('Org1MSP.member')"

peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'

peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}'

peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'

Step 10: Query chaincode for peer1 cli :

7. Peer0 Org1 CLI :
docker run --rm -it --network="my-net" --name cli --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --link peer1.org1.example.com:peer1.org1.example.com -p 12051:7051 -p 12053:7053 -e GOPATH=/opt/gopath -e CORE_PEER_LOCALMSPID=Org1MSP -e CORE_PEER_TLS_ENABLED=false -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_ID=cli -e CORE_PEER_ADDRESS=peer0.org1.example.com:7051 -e CORE_PEER_NETWORKID=cli -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net  -v /var/run/:/host/var/run/ -v $(pwd)/chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go -v $(pwd)/crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ -v $(pwd)/scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/ -v $(pwd)/channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-tools /bin/bash

# Environment variables for PEER1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
CORE_PEER_ADDRESS=peer1.org1.example.com:7051# Environment variables for PEER1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
CORE_PEER_ADDRESS=peer1.org1.example.com:7051

peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'

=============================== We are done with setup for One Org with 2 peers on different VM =================================
################# PART 2 - Let's add Org2 with one peer to this running network #####################################################

Step 1 : Go to PC1 
cd ~/Build-Multi-Host-Network-Hyperledger
mkdir org2-artifacts
cd org2-artifacts

Step 2 : create config tx file
vi configtx.yaml
-------------
# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

---
################################################################################
#
#   Section: Organizations
#
#   - This section defines the different organizational identities which will
#   be referenced later in the configuration.
#
################################################################################
Organizations:
    - &Org2
        # DefaultOrg defines the organization which is used in the sampleconfig
        # of the fabric.git development environment
        Name: Org2MSP

        # ID to load the MSP definition as
        ID: Org2MSP

        MSPDir: crypto-config/peerOrganizations/org2.example.com/msp

        AnchorPeers:
            # AnchorPeers defines the location of peers which can be used
            # for cross org gossip communication.  Note, this value is only
            # encoded in the genesis block in the Application section context
            - Host: peer0.org2.example.com
              Port: 11051

Profiles:

    NewOrg2Channel:
            Application:
                Organizations:
                    - *Org2



Step 3 : create crypto yaml file

vi org2-crypto.yaml

# Copyright IBM Corp. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#

# ---------------------------------------------------------------------------
# "PeerOrgs" - Definition of organizations managing peer nodes
# ---------------------------------------------------------------------------
PeerOrgs:
  # ---------------------------------------------------------------------------
  # Org2
  # ---------------------------------------------------------------------------
  - Name: Org2
    Domain: org2.example.com
    EnableNodeOUs: true
    Template:
      Count: 1
    Users:
      Count: 1

Step 4 : Create crypto material for Org2 on PC3 :

cryptogen generate --config=./org2-crypto.yaml

export FABRIC_CFG_PATH=$PWD
configtxgen -printOrg Org2MSP > ../channel-artifacts/org2.json


Step 5 == create config tx within cli of PC1 peer0 - Org1 : Get into perr0 Org1 cli on PC1
apt-get -y update && apt-get -y install jq

========== set order global =====
CORE_PEER_LOCALMSPID="OrdererMSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/users/Admin@example.com/msp

===== "Fetching the most recent configuration block for the channel" ==============
peer channel fetch config config_block.pb -o orderer.example.com:7050 -c mychannel --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

=========="Decoding config block to JSON and isolating config to config.json"
configtxlator proto_decode --input config_block.pb --type common.Block | jq .data.data[0].payload.data.config >config.json

jq -s '.[0] * {"channel_group":{"groups":{"Application":{"groups": {"Org2MSP":.[1]}}}}}' config.json ./channel-artifacts/org2.json > modified_config.json

# Compute a config update, based on the differences between config.json and modified_config.json, write it as a transaction to org2_update_in_envelope.p

set -x
configtxlator proto_encode --input config.json --type common.Config >original_config.pb
configtxlator proto_encode --input modified_config.json --type common.Config >modified_config.pb
configtxlator compute_update --channel_id mychannel --original original_config.pb --updated modified_config.pb >config_update.pb
configtxlator proto_decode --input config_update.pb --type common.ConfigUpdate >config_update.json
echo '{"payload":{"header":{"channel_header":{"channel_id":"'mychannel'", "type":2}},"data":{"config_update":'$(cat config_update.json)'}}}' | jq . >config_update_in_envelope.json
configtxlator proto_encode --input config_update_in_envelope.json --type common.Envelope >org2_update_in_envelope.pb
set +x
  
================"Signing config transaction" CAB BE SKIPPED ================
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp
peer channel signconfigtx -f org2_update_in_envelope.pb

========= Sign and Submitting transaction - we can have policies here (have a chk ) =========
CORE_PEER_ADDRESS=peer0.org1.example.com:7051
CORE_PEER_LOCALMSPID="Org1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/peers/peer0.org1.example.com/tls/ca.crt
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org1.example.com/users/Admin@org1.example.com/msp

peer channel update -f org2_update_in_envelope.pb -c mychannel -o orderer.example.com:7050


Step 6 : **** Copy crypto materials to PC3 - run this command from PC1
scp -r ~/Build-Multi-Host-Network-Hyperledger/ ubuntu@<PC3 DNS>:/home/ubuntu

=============================================================================================
Step 7 : Run dockers for Org2 - (Run the below commands from PC3)
=============================================================================================

#Couch DB
docker run --rm -it --network="my-net" --name couchdb2 -p 8984:5984 -e COUCHDB_USER= -e COUCHDB_PASSWORD= -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net hyperledger/fabric-couchdb

# peer0-org2
docker run --rm -it --network="my-net" --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --link peer1.org1.example.com:peer1.org1.example.com --link ca.example.com:ca.example.com --name peer0.org2.example.com -p 7051:7051 -p 7053:7053 -e CORE_LEDGER_STATE_STATEDATABASE=CouchDB -e CORE_LEDGER_STATE_COUCHDBCONFIG_COUCHDBADDRESS=couchdb3:5984 -e CORE_LEDGER_STATE_COUCHDBCONFIG_USERNAME= -e CORE_LEDGER_STATE_COUCHDBCONFIG_PASSWORD= -e CORE_PEER_ADDRESSAUTODETECT=true -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_NETWORKID=peer0.org2.example.com -e CORE_NEXT=true -e CORE_PEER_ENDORSER_ENABLED=true -e CORE_PEER_ID=peer0.org2.example.com -e CORE_PEER_PROFILE_ENABLED=true -e CORE_PEER_COMMITTER_LEDGER_ORDERER=orderer.example.com:7050 -e CORE_PEER_GOSSIP_ORGLEADER=true -e CORE_PEER_GOSSIP_EXTERNALENDPOINT=peer0.org2.example.com:7051 -e CORE_PEER_GOSSIP_IGNORESECURITY=true -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net -e CORE_PEER_GOSSIP_BOOTSTRAP=peer0.org2.example.com:7051 -e CORE_PEER_GOSSIP_USELEADERELECTION=false -e CORE_PEER_TLS_ENABLED=false -v /var/run/:/host/var/run/ -v $(pwd)/org2-artifacts/crypto-config/peerOrganizations/org2.example.com/peers/peer0.org2.example.com/msp:/etc/hyperledger/fabric/msp -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-peer peer node start

# org2Cli
docker run --rm -it --network="my-net" --name org2Cli --link orderer.example.com:orderer.example.com --link peer0.org1.example.com:peer0.org1.example.com --link peer1.org1.example.com:peer1.org1.example.com --link peer0.org2.example.com:peer0.org2.example.com -p 13051:7051 -p 13053:7053 -e GOPATH=/opt/gopath -e CORE_PEER_LOCALMSPID=Org2MSP -e CORE_PEER_TLS_ENABLED=false -e CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock -e CORE_LOGGING_LEVEL=DEBUG -e CORE_PEER_ID=org2Cli -e CORE_PEER_ADDRESS=peer0.org2.example.com:7051 -e CORE_PEER_NETWORKID=org2Cli -e CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp -e CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=my-net  -v /var/run/:/host/var/run/ -v $(pwd)/chaincode/:/opt/gopath/src/github.com/hyperledger/fabric/examples/chaincode/go -v $(pwd)/org2-artifacts/crypto-config:/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ -v $(pwd)/scripts:/opt/gopath/src/github.com/hyperledger/fabric/peer/scripts/ -v $(pwd)/channel-artifacts:/opt/gopath/src/github.com/hyperledger/fabric/peer/channel-artifacts -w /opt/gopath/src/github.com/hyperledger/fabric/peer hyperledger/fabric-tools /bin/bash


========= STEP 8 : on PC3 org2Cli===============================================
- Fetch channel config (by now we have org2 included on channel config transaction)
- Join Channel
- install chaincode on peer0 of Org2
- Invoke and Query
===========================================================================

#Set variables
CORE_PEER_LOCALMSPID="Org2MSP"
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/org2.example.com/users/Admin@org2.example.com/msp
CORE_PEER_ADDRESS=peer0.org2.example.com:7051

peer channel fetch 0 mychannel.block -o orderer.example.com:7050 -c mychannel --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

peer channel join -b mychannel.block

peer chaincode install -n mycc -v 1.0 -p github.com/hyperledger/fabric/examples/chaincode/go/chaincode_example02

peer chaincode invoke -o orderer.example.com:7050 -C mychannel -n mycc -c '{"Args":["invoke","a","b","10"]}'

peer chaincode query -C mychannel -n mycc -c '{"Args":["query","a"]}'


## Build multi host multi vm fabric network

Network Topology
So the network that we are going to build will have the following below components. For this example we are using Three PCs lets say (PC1 , PC2 and PC3):

### For Org1 :

1. A Certificate Authority (CA) — PC1
2. An Orderer — PC1
3. 1 PEER (peer0) on — PC1
4. 1 PEER (peer1) on — PC2
5. couchdb1
6. CLI on — PC1 and PC2

Once we have this network having One Org1 running with 2 peers on different VMs, we are going to extend this by adding a new organization Org2 with 1 peer peer0.org2

### For Org2 :

1. 1 PEER (peer0) on — PC3
2. couchdb2
3. CLI on — PC3

### Please follow stepts mentioned in setupSteps.txt

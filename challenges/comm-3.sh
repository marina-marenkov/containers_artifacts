
# Set environment variables
export CONTAINER_REGISTRY=mmacrdev
export ACR=$CONTAINER_REGISTRY.azurecr.io

export NETWORK=mm-local

export SQL_DBNAME=mydrivingDB
export SQL_USER=marina
export SQL_SERVER=mm-sql-server-01.database.windows.net
export SQL_PASSWORD=Mnrbeuc25

export RESOURCE_GROUP=oh-rg
export CLUSTER_NAME=CHANGEME


# Login to ACR
az acr login -n $CONTAINER_REGISTRY

# Create AKS cluster
az aks create -g $RESOURCE_GROUP -n $CLUSTER_NAME --node-count 1 --enable-addons monitoring --generate-ssh-keys

# create secret 
kubectl create secret generic sqlconnection --namespace=api --from-literal=SQL_DBNAME=$SQL_DBNAME --from-literal=SQL_SERVER=$SQL_SERVER --from-literal=SQL_USER=$SQL_USER --from-literal=SQL_PASSWORD=$SQL_PASSWORD

# Create api namespace
kubectl create namespace api

# create poi deployment
kubectl create -f poi.yaml --namespace=api




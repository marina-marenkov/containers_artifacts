
#Challenge 4: Orchestration and Beyond

# Set environment variables
export CONTAINER_REGISTRY=mmacrdev
export ACR=$CONTAINER_REGISTRY.azurecr.io

# DB connection variables
export SQL_DBNAME=mydrivingDB
export SQL_USER=marina
export SQL_SERVER=mm-sql-server-01.database.windows.net
export SQL_PASSWORD=Mnrbeuc25

#AKS variables
export RESOURCE_GROUP=oh-rg
export CLUSTER_NAME=oh-aks-ch4
export AD_GROUP_NAME=mm-oh-aks-aad-gr
export VNET=$(az network vnet list -g $RESOURCE_GROUP --query "[0].name" -o tsv)


# Login to ACR
az acr login -n $CONTAINER_REGISTRY

#get subnets list
az network vnet subnet list -g $RESOURCE_GROUP --vnet-name $VNET -o table
export CLUSTER_ADDRESS_SPACE=10.0.1.0/24
export CLUSTER_SUBNET=aks-subnet

# Create a subnet for the cluster
export CLUSTER_SUBNET_ID=$(az network vnet subnet create \
    -g $RESOURCE_GROUP --vnet-name $VNET \
    -n $CLUSTER_SUBNET \
    --address-prefixes $CLUSTER_ADDRESS_SPACE \
    --query id -o tsv)

#get group id
export GROUP_OBJECT_ID=$(az ad group create \
    --display-name $AD_GROUP_NAME \
    --mail-nickname $AD_GROUP_NAME \
    --query objectId -o tsv)
export GROUP_OBJECT_ID=7e98d3e8-4d3b-477b-8547-467a262eb38f

# Create AKS cluster with AD integration and RBAC and cni
az aks create \
    --resource-group $RESOURCE_GROUP \
    --name $CLUSTER_NAME \
    --attach-acr $ACR \
    --node-count 3 \
    --network-plugin azure \
    --vnet-subnet-id $CLUSTER_SUBNET_ID \
    --service-cidr 10.2.0.0/24 \
    --dns-service-ip 10.2.0.10 \
    --docker-bridge-address 172.17.0.1/16 \
    --enable-aad \
    --aad-admin-group-object-ids $GROUP_OBJECT_ID \
    --generate-ssh-keys

# create secret 
kubectl create secret generic sqlconnection --namespace=api --from-literal=SQL_DBNAME=$SQL_DBNAME --from-literal=SQL_SERVER=$SQL_SERVER --from-literal=SQL_USER=$SQL_USER --from-literal=SQL_PASSWORD=$SQL_PASSWORD

# Create api namespace
kubectl create namespace api, web

#create api, web groups and add users, assign roles to groups
export WEB_AD_USER=oh-mm-web-user
export API_AD_USER=oh-mm-api-user

export WEB_AD_GROUP_NAME=oh-mm-web-group
export API_AD_GROUP_NAME=oh-mm-api-group

export CLUSTER_ID=$(az aks show \
    -g $RESOURCE_GROUP -n $CLUSTER_NAME \
    --query id -o tsv)

export WEB_GROUP_ID=$(az ad group create \
    --display-name $WEB_AD_GROUP_NAME \
    --mail-nickname $WEB_AD_GROUP_NAME \
    --query objectId -o tsv)

az role assignment create \
    --assignee $WEB_GROUP_ID \
    --role "Azure Kubernetes Service Cluster User Role" \
    --scope $CLUSTER_ID

#assign role to user
az role assignment create \
    --assignee $WEB_AD_USER \
    --role "Azure Kubernetes Service Cluster User Role" \
    --scope $CLUSTER_ID

kubectl apply -f rolebinding.yaml --namespace=web

#create secret for api namespace
 

# create poi deployment
kubectl create -f poi.yaml --namespace=api




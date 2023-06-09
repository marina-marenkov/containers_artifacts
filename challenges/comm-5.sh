
#Challenge 4: Orchestration and Beyond

# Set environment variables
export CONTAINER_REGISTRY=mmacrdev
export ACR=$CONTAINER_REGISTRY.azurecr.io
export KEYVAULT_NAME=mmkeyvault25

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

# Enable Secrets Store CSI Driver Azure Provider add-on
az aks enable-addons \
    -g $RESOURCE_GROUP \
    -n $CLUSTER_NAME \
    --addons azure-keyvault-secrets-provider



# Add the SQL connection info to the keyvault
# Secrets can't have underscores in their names
az keyvault secret set --vault-name $KEYVAULT_NAME -n SQLSERVER --value "$SQL_SERVER"
az keyvault secret set --vault-name $KEYVAULT_NAME -n SQLDBNAME --value "$SQL_DBNAME"
az keyvault secret set --vault-name $KEYVAULT_NAME -n SQLUSER --value "$SQL_USER"
az keyvault secret set --vault-name $KEYVAULT_NAME -n SQLPASSWORD --value "$SQL_PASSWORD"

kubectl create -f keyvault-secret.yaml --namespace=api

# Allow Secrets Provider id to get secrets
az keyvault set-policy -n $KEYVAULT_NAME --secret-permissions get --spn $SECRETS_PROVIDER_IDENTITY

#Install Ingress

export NAMESPACE=ingress
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
    --create-namespace --namespace $NAMESPACE \
    -f nginx-helm-values.yaml



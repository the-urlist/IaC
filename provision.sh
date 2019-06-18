# The variables used in the this script are passed in as environment variables by
# Azure Pipelines
#

# This Sets the subscription identified to be default subscription 
#
echo "Setting default subscription for Azure CLI: $SUBSCRIPTIONNAME"
az account set \
    --subscription $SUBSCRIPTIONNAME
echo

# This creates the resource group used to house all of the URList application
#
echo "Creating resource group $RESOURCEGROUPNAME in region $RESOURCEGROUPREGION"
az group create \
    --name $RESOURCEGROUPNAME \
    --location $RESOURCEGROUPREGION
echo

# This creates a storage account to host our static web site
#
echo "Creating storage account $STORAGEACCOUNTNAME in resource group $RESOURCEGROUPNAME"
az storage account create \
    --location $STORAGEACCOUNTREGION \
    --name $STORAGEACCOUNTNAME \
    --resource-group $RESOURCEGROUPNAME \
    --sku "$STORAGEACCOUNTSKU" \
    --kind StorageV2
echo

# This sets the storage account so it can host a static website
#
echo "Enabling static website hosting in storage account $STORAGEACCOUNTNAME"
az extension add \
    --name storage-preview

az storage blob service-properties update \
    --account-name $STORAGEACCOUNTNAME \
    --static-website \
    --404-document $ERRORDOCUMENTNAME \
    --index-document $INDEXDOCUMENTNAME
echo

# this create a SQL API Cosmos DB account with session consistency and multi-master 
# enabled
#
echo "creating cosmos db with session consistency and multi-master"
az cosmosdb create \
    --name $COSMOSACCOUNTNAME \
    --kind GlobalDocumentDB \
    --locations "South Central US"=0 "North Central US"=1 \
    --resource-group $RESOURCEGROUPNAME \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true
echo

# This checks to see if the database exists in cosmos, if not, it creates a 
# database for urlist, otherwise does nothing 
#
echo "create the db $COSMOSDBNAME for urlist in cosmos"
isDbCreated="$(az cosmosdb database exists --resource-group-name $RESOURCEGROUPNAME --name $COSMOSACCOUNTNAME --db-name $COSMOSDBNAME)"
if [ $isDbCreated = true ] ;
then 
    echo "    db $COSMOSDBNAME already exits"
else
    echo "    db $COSMOSDBNAME does not exist, creating..."
    az cosmosdb database create \
        --name $COSMOSACCOUNTNAME \
        --db-name $COSMOSDBNAME \
        --resource-group $RESOURCEGROUPNAME
    echo
fi

# this creates a fixed-size container and 400 RU/s
#
echo "create a fixed size container and 400 RU/s"
isCollectionCreated="$(az cosmosdb collection exists --db-name $COSMOSDBNAME --collection-name $COSMOSCONTAINERNAME --resource-group-name $RESOURCEGROUPNAME --name $COSMOSACCOUNTNAME)"
if [ $isDbCreated = true ] ;
then 
    echo "    container $ $COSMOSCONTAINERNAME already exits"
else
    echo "    container $ $COSMOSCONTAINERNAME does not exist, creating..."
    az cosmosdb collection create \
        --resource-group $RESOURCEGROUPNAME \
        --collection-name $COSMOSCONTAINERNAME \
        --name $COSMOSACCOUNTNAME \
        --db-name $COSMOSDBNAME \
        --throughput $COSMOSTHROUGHPUT \
        --partition-key-path /vanityUrl
fi
echo

# this creates a storage account for our back end azure function to maintain
# state and other info for the function
# 
echo "create a storage account for function to maintain state and other info for the function"
az storage account create \
    --name $FUNCTIONSTORAGEACCOUNTNAME \
    --location $FUNCTIONSTORAGEACCOUNTREGION \
    --resource-group $RESOURCEGROUPNAME \
    --sku $FUNCTIONSTORAGEACCOUNTSKU
echo

# this creates the function app used to host the back end function
#
echo "create the function app for the back end "
az functionapp create \
    --resource-group $RESOURCEGROUPNAME \
    --consumption-plan-location $FUNCTIONCONSUMPTIONPLANREGION \
    --name $FUNCTIONNAME \
    --storage-account $FUNCTIONSTORAGEACCOUNTNAME \
    --runtime $FUNCTIONRUNTIME
echo

# this grabs the static website storage primary endpoint to be used when
# setting the authentication of the function
echo "getting the static website storage's primary endpoint "
staticWebsiteUrl="$(az storage account show -n $STORAGEACCOUNTNAME -g $RESOURCEGROUPNAME --query "primaryEndpoints.web" --output tsv)"
echo "static website storage's primary endpoint: $staticWebsiteUrl"
echo

# this sets authentication to be on and to use twitter for the back end
# function, also sets the allowed external redirect urls to be the
# static website storage primary endpoint
#
echo "setting authentication for the azure function app back end"
az webapp auth update \
    --name $FUNCTIONNAME \
    --resource-group $RESOURCEGROUPNAME \
    --enabled true \
    --action LoginWithTwitter \
    --twitter-consumer-key $TWITTERCONSUMERKEY \
    --twitter-consumer-secret $TWITTERCONSUMERSECRET \
    --allowed-external-redirect-urls $staticWebsiteUrl
echo
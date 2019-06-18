# The variables in pipelines are set as environment variables. This gets those environment
# variables and sets them as local variables ready to be used in the rest of the script
#
echo "Gathering pipeline variables"
resourceGroupName=$RESOURCEGROUPNAME
echo "    resourceGroupName: $resourceGroupName"
subscriptionName=$SUBSCRIPTIONNAME
echo "    subscriptionName: $subscriptionName"
resourceGroupRegion=$RESOURCEGROUPREGION
echo "    resourceGroupRegion: $resourceGroupRegion"
storageAccountRegion=$STORAGEACCOUNTREGION
echo "    storageAccountRegion: $storageAccountRegion"
storageAccountName=$STORAGEACCOUNTNAME
echo "    storageAccountName: $storageAccountName"
storageAccountSku=$STORAGEACCOUNTSKU
echo "    storageAccountSku: $storageAccountSku"
errorDocumentName=$ERRORDOCUMENTNAME
echo "    errorDocumentName: $errorDocumentName"
indexDocumentName=$INDEXDOCUMENTNAME
echo "    indexDocumentName: $indexDocumentName"
cosmosAccountName=$COSMOSACCOUNTNAME
echo "    cosmosAccountName: $cosmosAccountName"
cosmosRegion=$COSMOSREGION
echo "    cosmosRegion: $cosmosRegion"
cosmosDbName=$COSMOSDBNAME
echo "    cosmosDbName: $cosmosDbName"
cosmosContainerName=$COSMOSCONTAINERNAME
echo "    cosmosContainerName: $cosmosContainerName"
cosmosThroughput=$COSMOSTHROUGHPUT
echo "    cosmosThroughput: $cosmosThroughput"
functionStorageAccountRegion=$FUNCTIONSTORAGEACCOUNTREGION
echo "    functionStorageAccountRegion: $functionStorageAccountRegion"
functionStorageAccountName=$FUNCTIONSTORAGEACCOUNTNAME
echo "    functionStorageAccountName: $functionStorageAccountName"
functionStorageAccountSku=$FUNCTIONSTORAGEACCOUNTSKU
echo "    functionStorageAccountSku: $functionStorageAccountSku"
functionConsumptionPlanRegion=$FUNCTIONCONSUMPTIONPLANREGION
echo "    functionConsumptionPlanRegion: $functionConsumptionPlanRegion"
functionName=$FUNCTIONNAME
echo "    functionName: $functionName"
functionRuntime=$FUNCTIONRUNTIME
echo "    functionRuntime: $functionRuntime"
twitterConsumerKeyX=$TWITTERCONSUMERKEY
echo "    twitterConsumerKeyX: $twitterConsumerKeyX"
twitterConsumerKeyY=$twitterConsumerKey
echo "    twitterConsumerKey: $twitterConsumerKeyY"
twitterConsumerSecret=$TWITTERCONSUMERSECRET
echo "    twitterConsumerSecret: $twitterConsumerSecret"
echo

# This Sets the subscription identified to be default subscription 
#
echo "Setting default subscription for Azure CLI: $subscriptionName"
az account set \
    --subscription $subscriptionName
echo

# This creates the resource group used to house all of the URList application
#
echo "Creating resource group $resourceGroupName in region $resourceGroupRegion"
az group create \
    --name $resourceGroupName \
    --location $resourceGroupRegion
echo

# This creates a storage account to host our static web site
#
echo "Creating storage account $storageAccountName in resource group $resourceGroupName"
az storage account create \
    --location $storageAccountRegion \
    --name $storageAccountName \
    --resource-group $resourceGroupName \
    --sku "$storageAccountSku" \
    --kind StorageV2
echo

# This sets the storage account so it can host a static website
#
echo "Enabling static website hosting in storage account $storageAccountName"
az extension add \
    --name storage-preview

az storage blob service-properties update \
    --account-name $storageAccountName \
    --static-website \
    --404-document $errorDocumentName \
    --index-document $indexDocumentName
echo

# this create a SQL API Cosmos DB account with session consistency and multi-master 
# enabled
#
echo "creating cosmos db with session consistency and multi-master"
az cosmosdb create \
    --name $cosmosAccountName \
    --kind GlobalDocumentDB \
    --locations "South Central US"=0 "North Central US"=1 \
    --resource-group $resourceGroupName \
    --default-consistency-level "Session" \
    --enable-multiple-write-locations true
echo

# This checks to see if the database exists in cosmos, if not, it creates a 
# database for urlist, otherwise does nothing 
#
echo "create the db $cosmosDbName for urlist in cosmos"
isDbCreated="$(az cosmosdb database exists --resource-group-name $resourceGroupName --name $cosmosAccountName --db-name $cosmosDbName)"
if [ $isDbCreated = true ] ;
then 
    echo "    db $cosmosDbName already exits"
else
    echo "    db $cosmosDbName does not exist, creating..."
    az cosmosdb database create \
        --name $cosmosAccountName \
        --db-name $cosmosDbName \
        --resource-group $resourceGroupName
    echo
fi

# this creates a fixed-size container and 400 RU/s
#
echo "create a fixed size container and 400 RU/s"
isCollectionCreated="$(az cosmosdb collection exists --db-name $cosmosDbName --collection-name $cosmosContainerName --resource-group-name $resourceGroupName --name $cosmosAccountName)"
if [ $isDbCreated = true ] ;
then 
    echo "    container $ $cosmosContainerName already exits"
else
    echo "    container $ $cosmosContainerName does not exist, creating..."
    az cosmosdb collection create \
        --resource-group $resourceGroupName \
        --collection-name $cosmosContainerName \
        --name $cosmosAccountName \
        --db-name $cosmosDbName \
        --throughput $cosmosThroughput \
        --partition-key-path /vanityUrl
fi
echo

# this creates a storage account for our back end azure function to maintain
# state and other info for the function
# 
echo "create a storage account for function to maintain state and other info for the function"
az storage account create \
    --name $functionStorageAccountName \
    --location $functionStorageAccountRegion \
    --resource-group $resourceGroupName \
    --sku $functionStorageAccountSku
echo

# this creates the function app used to host the back end function
#
echo "create the function app for the back end "
az functionapp create \
    --resource-group $resourceGroupName \
    --consumption-plan-location $functionConsumptionPlanRegion \
    --name $functionName \
    --storage-account $functionStorageAccountName \
    --runtime $functionRuntime
echo

# this sets authentication to be on and to use twitter for the back end
# function
#
az webapp auth update \
    --name $functionName \
    --resource-group $resourceGroupName \
    --enabled true \
    --action LoginWithTwitter \
    --twitter-consumer-key $twitterConsumerKey \
    --twitter-consumer-secret $twitterConsumerSecret
echo
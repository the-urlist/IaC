# This processes all the command line arguments and sets them to the appropriate variable so
# all variables will be ready to be used in the rest of the script
#
echo "Checking environment variable for resource group: $resourceGroup"
echo "Iterating through parameters..."
echo "Number of parameters passed in: $#"
foundResourceGroupName=false
foundSubscriptionName=false
foundResourceGroupRegion=false
foundStorageAccountName=false
foundStorageAccountRegion=false
foundStorageAccountSku=false
foundErrorDocumentName=false
foundIndexDocumentName=false
foundCosmosAccountName=false
foundCosmosRegion=false
foundCosmosDbName=false
foundCosmosContainerName=false
foundCosmosThroughput=false
foundFunctionStorageAccountRegion=false
foundFunctionStorageAccountName=false
foundFunctionStorageAccountSku=false
foundFunctionConsumptionPlanRegion=false
foundFunctionName=false
foundFunctionRuntime=false
for var in "$@"
do
    echo "    param: $var"

    # set variable values
    if [ $foundResourceGroupName = true ] ;
    then 
        echo "        setting value for resourceGroupName: $var"
        resourceGroupName=$var
        foundResourceGroupName=false
    elif [ $foundSubscriptionName = true ] ;
    then
        echo "        setting value for subscriptionName: $var"
        subscriptionName=$var
        foundSubscriptionName=false
    elif [ $foundResourceGroupRegion = true ];
    then
        echo "        setting value for resourceGroupRegion: $var"
        resourceGroupRegion=$var
        foundResourceGroupRegion=false
    elif [ $foundStorageAccountName = true ];
    then
        echo "        setting value for storageAccountName: $var"
        storageAccountName=$var
        foundStorageAccountName=false
    elif [ $foundStorageAccountRegion = true ];
    then
        echo "        setting value for storageAccountRegion: $var"
        storageAccountRegion=$var
        foundStorageAccountRegion=false
    elif [ $foundStorageAccountSku = true ];
    then
        echo "        setting value for storageAccountSku: $var"
        storageAccountSku=$var
        foundStorageAccountSku=false
    elif [ $foundErrorDocumentName = true ];
    then
        echo "        setting value for errorDocumentName: $var"
        errorDocumentName=$var
        foundErrorDocumentName=false
    elif [ $foundIndexDocumentName = true ];
    then
        echo "        setting value for indexDocumentName: $var"
        indexDocumentName=$var
        foundIndexDocumentName=false
    elif [ $foundCosmosAccountName = true ];
    then
        echo "        setting value for cosmosAccountName: $var"
        cosmosAccountName=$var
        foundCosmosAccountName=false
    elif [ $foundCosmosRegion = true ];
    then
        echo "        setting value for cosmosRegion: $var"
        cosmosRegion=$var
        foundCosmosRegion=false
    elif [ $foundCosmosDbName = true ];
    then
        echo "        setting value for cosmosDbName: $var"
        cosmosDbName=$var
        foundCosmosDbName=false
    elif [ $foundCosmosContainerName = true ];
    then
        echo "        setting value for cosmosContainerName: $var"
        cosmosContainerName=$var
        foundCosmosContainerName=false
    elif [ $foundCosmosThroughput = true ];
    then
        echo "        setting value for cosmosThroughput: $var"
        cosmosThroughput=$var
        foundCosmosThroughput=false
    elif [ $foundFunctionStorageAccountRegion = true ];
    then
        echo "        setting value for functionStorageAccountRegion: $var"
        functionStorageAccountRegion=$var
        foundFunctionStorageAccountRegion=false
    elif [ $foundFunctionStorageAccountName = true ];
    then
        echo "        setting value for functionStorageAccountName: $var"
        functionStorageAccountName=$var
        foundFunctionStorageAccountName=false
    elif [ $foundFunctionStorageAccountSku = true ];
    then
        echo "        setting value for functionStorageAccountSku: $var"
        functionStorageAccountSku=$var
        foundFunctionStorageAccountSku=false
    elif [ $foundFunctionConsumptionPlanRegion = true ];
    then
        echo "        setting value for functionConsumptionPlanRegion: $var"
        functionConsumptionPlanRegion=$var
        foundFunctionConsumptionPlanRegion=false
    elif [ $foundFunctionName = true ];
    then
        echo "        setting value for functionName: $var"
        functionName=$var
        foundFunctionName=false
    elif [ $foundFunctionRuntime = true ];
    then
        echo "        setting value for functionRuntime: $var"
        functionRuntime=$var
        foundFunctionRuntime=false
    fi


    # get variable names
    if [ "$var" = "-resourceGroupName" ]; 
    then
        echo "        found parameter resourceGroupName"
        foundResourceGroupName=true
    elif [ "$var" = "-subscriptionName" ];
    then
        echo "        found parameter subscriptionName"
        foundSubscriptionName=true
    elif [ "$var" = "-resourceGroupRegion" ];
    then
        echo "        found parameter resourceGroupRegion"
        foundResourceGroupRegion=true;
    elif [ "$var" = "-storageAccountName" ];
    then
        echo "        found parameter storageAccountName"
        foundStorageAccountName=true
    elif [ "$var" = "-storageAccountRegion" ];
    then
        echo "        found parameter storageAccountRegion"
        foundStorageAccountRegion=true
    elif [ "$var" = "-storageAccountSku" ];
    then
        echo "        found parameter storageAccountSku"
        foundStorageAccountSku=true;
    elif [ "$var" = "-errorDocumentName" ];
    then
        echo "        found parameter errorDocumentName"
        foundErrorDocumentName=true
    elif [ "$var" = "-indexDocumentName" ];
    then
        echo "        found parameter indexDocumentName"
        foundIndexDocumentName=true;
    elif [ "$var" = "-cosmosAccountName" ];
    then
        echo "        found parameter cosmosAccountName"
        foundCosmosAccountName=true;
    elif [ "$var" = "-cosmosRegion" ];
    then
        echo "        found parameter cosmosRegion"
        foundCosmosRegion=true
    elif [ "$var" = "-cosmosDbName" ];
    then
        echo "        found parameter cosmosDbName"
        foundCosmosDbName=true
    elif [ "$var" = "-cosmosContainerName" ];
    then
        echo "        found parameter cosmosContainerName"
        foundCosmosContainerName=true
    elif [ "$var" = "-cosmosThroughput" ];
    then
        echo "        found parameter cosmosThroughput"
        foundCosmosThroughput=true
    elif [ "$var" = "-functionStorageAccountRegion" ];
    then
        echo "        found parameter functionStorageAccountRegion"
        foundFunctionStorageAccountRegion=true
    elif [ "$var" = "-functionStorageAccountName" ];
    then
        echo "        found parameter functionStorageAccountName"
        foundFunctionStorageAccountName=true
    elif [ "$var" = "-functionStorageAccountSku" ];
    then
        echo "        found parameter functionStorageAccountSku"
        foundFunctionStorageAccountSku=true
    elif [ "$var" = "-functionConsumptionPlanRegion" ];
    then
        echo "        found parameter functionConsumptionPlanRegion"
        foundFunctionConsumptionPlanRegion=true
    elif [ "$var" = "-functionName" ];
    then
        echo "        found parameter functionName"
        foundFunctionName=true
    elif [ "$var" = "-functionRuntime" ];
    then
        echo "        found parameter functionRuntime"
        foundFunctionRuntime=true
    fi
done
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
    --name theurlistfunction \
    --resource-group the-urlist-serverless-abel3 \
    --enabled true \
    --action LoginWithTwitter \
    --twitter-consumer-key KsXcWMh9TIbuz3KyzoL1vWCrY \
    --twitter-consumer-secret hGy2Kw6cKqSiIBNPBVRjJAb5VZYtE8ZamB13mnojUVCUQ5EDua
echo
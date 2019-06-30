# The variables used in the this script are passed in as environment variables by
# Azure Pipelines
#

# this defines my time 1 up function which will deploy and configure the infrastructure 
# for the static web app held in blob storage, the azure function and cosmos
# DB
#
1_Up() {
    # This creates the resource group used to house all of the URList application
    #
    echo "Creating resource group $IAC_EXCLUSIVE_RESOURCEGROUPNAME in region $IAC_RESOURCEGROUPREGION"
    az group create \
        --name $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
        --location $IAC_RESOURCEGROUPREGION
    echo ""

    # This creates a storage account to host our static web site
    #
    echo "Creating storage account $IAC_EXCLUSIVE_WEBSTORAGEACCOUNTNAME in resource group $IAC_EXCLUSIVE_RESOURCEGROUPNAME"
    az storage account create \
        --location $IAC_WEBSTORAGEACCOUNTREGION \
        --name $IAC_EXCLUSIVE_WEBSTORAGEACCOUNTNAME \
        --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
        --sku "$IAC_WEBSTORAGEACCOUNTSKU" \
        --kind StorageV2
    echo ""

    # This sets the storage account so it can host a static website
    #
    echo "Enabling static website hosting in storage account $IAC_EXCLUSIVE_WEBSTORAGEACCOUNTNAME"
    az extension add \
        --name storage-preview

    az storage blob service-properties update \
        --account-name $IAC_EXCLUSIVE_WEBSTORAGEACCOUNTNAME \
        --static-website \
        --404-document $IAC_ERRORDOCUMENTNAME \
        --index-document $IAC_INDEXDOCUMENTNAME
    echo ""

    # this create a SQL API Cosmos DB account with session consistency and multi-master 
    # enabled
    #
    echo "creating cosmos db account"
    # az cosmosdb create \
    #     --name $IAC_EXCLUSIVE_COSMOSACCOUNTNAME \
    #     --kind GlobalDocumentDB \
    #     --locations "South Central US"=0 "North Central US"=1 \
    #     --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
    #     --default-consistency-level "Session" \
    #     --enable-multiple-write-locations true
    az cosmosdb create \
        --name $IAC_EXCLUSIVE_COSMOSACCOUNTNAME \
        --resource-grou $IAC_EXCLUSIVE_RESOURCEGROUPNAME
    echo ""

    # This checks to see if the database exists in cosmos, if not, it creates a 
    # database for urlist, otherwise does nothing 
    #
    echo "create the db $IAC_COSMOSDBNAME for urlist in cosmos"
    isDbCreated="$(az cosmosdb database exists --resource-group-name $IAC_EXCLUSIVE_RESOURCEGROUPNAME --name $IAC_EXCLUSIVE_COSMOSACCOUNTNAME --db-name $IAC_COSMOSDBNAME)"
    if [ $isDbCreated = true ] ;
    then 
        echo "    db $IAC_COSMOSDBNAME already exits"
        echo ""
    else
        echo "    db $IAC_COSMOSDBNAME does not exist, creating..."
        az cosmosdb database create \
            --name $IAC_EXCLUSIVE_COSMOSACCOUNTNAME \
            --db-name $IAC_COSMOSDBNAME \
            --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
        echo ""
    fi

    # this creates a fixed-size container and 400 RU/s
    #
    echo "create a fixed size container and 400 RU/s"
    isCollectionCreated="$(az cosmosdb collection exists --db-name $IAC_COSMOSDBNAME --collection-name $IAC_COSMOSCONTAINERNAME --resource-group-name $IAC_EXCLUSIVE_RESOURCEGROUPNAME --name $IAC_EXCLUSIVE_COSMOSACCOUNTNAME)"
    if [ $isDbCreated = true ] ;
    then 
        echo "    container $ $IAC_COSMOSCONTAINERNAME already exits"
    else
        echo "    container $ $IAC_COSMOSCONTAINERNAME does not exist, creating..."
        az cosmosdb collection create \
            --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
            --collection-name $IAC_COSMOSCONTAINERNAME \
            --name $IAC_EXCLUSIVE_COSMOSACCOUNTNAME \
            --db-name $IAC_COSMOSDBNAME \
            --throughput $IAC_COSMOSTHROUGHPUT \
            --partition-key-path /vanityUrl
    fi
    echo ""

    # this creates a storage account for our back end azure function to maintain
    # state and other info for the function
    # 
    echo "create a storage account for function to maintain state and other info for the function"
    az storage account create \
        --name $IAC_EXCLUSIVE_FUNCTIONSTORAGEACCOUNTNAME \
        --location $IAC_FUNCTIONSTORAGEACCOUNTREGION \
        --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
        --sku $IAC_FUNCTIONSTORAGEACCOUNTSKU
    echo ""

    # this creates the function app used to host the back end function
    #
    echo "create the function app for the back end "
    az functionapp create \
        --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
        --consumption-plan-location $IAC_FUNCTIONCONSUMPTIONPLANREGION \
        --name $IAC_EXCLUSIVE_FUNCTIONNAME \
        --storage-account $IAC_EXCLUSIVE_FUNCTIONSTORAGEACCOUNTNAME \
        --runtime $IAC_FUNCTIONRUNTIME
    echo ""

    # this grabs the static website storage primary endpoint to be used when
    # setting the authentication of the function
    echo "getting the static website storage's primary endpoint "
    staticWebsiteUrl="$(az storage account show -n $IAC_EXCLUSIVE_WEBSTORAGEACCOUNTNAME -g $IAC_EXCLUSIVE_RESOURCEGROUPNAME --query "primaryEndpoints.web" --output tsv)"
    echo "static website storage's primary endpoint: $staticWebsiteUrl"
    echo ""

    # this sets authentication to be on and to use twitter for the back end
    # function, also sets the allowed external redirect urls to be the
    # static website storage primary endpoint
    #
    echo "setting authentication for the azure function app back end"
    az webapp auth update \
        --name $IAC_EXCLUSIVE_FUNCTIONNAME \
        --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
        --enabled true \
        --action LoginWithTwitter \
        --twitter-consumer-key $TWITTERCONSUMERKEY \
        --twitter-consumer-secret $TWITTERCONSUMERSECRET \
        --allowed-external-redirect-urls $staticWebsiteUrl
    echo ""

    # this creates an instance of appliction insight
    #
    echo "creating application insight for the function"
    appInsightCreateResponse="$(az resource create \
        --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
        --resource-type "Microsoft.Insights/components" \
        --name $IAC_APPLICATIONINSIGHTNAME \
        --location $IAC_APPLICATIONINSIGHTLOCATION \
        --properties '{"Application_Type":"web"}')" 
    echo "$appInsightCreateResponse"
    echo ""

    # this grabs the instrumentation key from the creation response
    #
    instrumentationKey="$(echo $appInsightCreateResponse | jq '.["properties"]["InstrumentationKey"]')"
    # strips off begin and end quotes
    instrumentationKey="$(sed -e 's/^"//' -e 's/"$//' <<<"$instrumentationKey")"
    echo "instrumentation key: $instrumentationKey"

    # this wires up application insights to the function
    # echo "wiring up app insight to function"
    #
    az functionapp config appsettings set \
        --name $IAC_EXCLUSIVE_FUNCTIONNAME \
        --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
        --settings "APPINSIGHTS_INSTRUMENTATIONKEY = $instrumentationKey"
    echo ""
}


# This queries the environment for the current version and then applies only 
# the changes necessary to bring the environment up to the latest version.
# The latest version variable needs to be manually updated each time you
# add a new Up function.
#
LATESTVERSION=1;
CURRENTVERSION=0
# get current version of infrastructure
curlResponse="$(curl --max-time 12 --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionRetriever?tablename=abelurlist&stage=beta&infraname=webfunctiondb")"
echo "curlResponce: $curlResponse"
if [ -z $curlResponse ] ;
then
    echo "curl response is empty, setting current version to 0"
	CURRENTVERSION=0
else
    echo "curl response not empty: $curlResponse"
	CURRENTVERSION=$curlResponse
fi
echo ""

# call the correct up  
if [  $CURRENTVERSION >= $LATERSTVERSION ] ;
then
    echo "infrastructure version up to date"
fi
for (( i=($CURRENTVERSION); i<LATESTVERSION; i++))
do
    echo "executing $i""_Up()"
    "$i"_Up
    # register new version of infrastructure deployed
    echo "registering new version of infrastructure"
	curlResponse="$(curl --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionUpdater?tablename=abelurlist&stage=beta&infraname=webfunctiondb")"
	echo "curl response: $curlResponse"
done
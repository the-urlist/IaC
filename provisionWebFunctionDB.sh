# The variables used in the this script are passed in as environment variables by
# Azure Pipelines
#

# This creates the resource group used to house all of the URList application
#
echo "Creating resource group $RESOURCEGROUPNAME in region $RESOURCEGROUPREGION"
az group create \
    --name $RESOURCEGROUPNAME \
    --location $RESOURCEGROUPREGION
echo ""

# This creates a storage account to host our static web site
#
echo "Creating storage account $STORAGEACCOUNTNAME in resource group $RESOURCEGROUPNAME"
az storage account create \
    --location $STORAGEACCOUNTREGION \
    --name $STORAGEACCOUNTNAME \
    --resource-group $RESOURCEGROUPNAME \
    --sku "$STORAGEACCOUNTSKU" \
    --kind StorageV2
echo ""

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
echo ""

# this create a SQL API Cosmos DB account with session consistency and multi-master 
# enabled
#
echo "creating cosmos db account"
# az cosmosdb create \
#     --name $COSMOSACCOUNTNAME \
#     --kind GlobalDocumentDB \
#     --locations "South Central US"=0 "North Central US"=1 \
#     --resource-group $RESOURCEGROUPNAME \
#     --default-consistency-level "Session" \
#     --enable-multiple-write-locations true
az cosmosdb create \
    --name $COSMOSACCOUNTNAME \
    --resource-grou $RESOURCEGROUPNAME
echo ""

# This checks to see if the database exists in cosmos, if not, it creates a 
# database for urlist, otherwise does nothing 
#
echo "create the db $COSMOSDBNAME for urlist in cosmos"
isDbCreated="$(az cosmosdb database exists --resource-group-name $RESOURCEGROUPNAME --name $COSMOSACCOUNTNAME --db-name $COSMOSDBNAME)"
if [ $isDbCreated = true ] ;
then 
    echo "    db $COSMOSDBNAME already exits"
    echo ""
else
    echo "    db $COSMOSDBNAME does not exist, creating..."
    az cosmosdb database create \
        --name $COSMOSACCOUNTNAME \
        --db-name $COSMOSDBNAME \
        --resource-group $RESOURCEGROUPNAME
    echo ""
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
echo ""

# this creates a storage account for our back end azure function to maintain
# state and other info for the function
# 
echo "create a storage account for function to maintain state and other info for the function"
az storage account create \
    --name $FUNCTIONSTORAGEACCOUNTNAME \
    --location $FUNCTIONSTORAGEACCOUNTREGION \
    --resource-group $RESOURCEGROUPNAME \
    --sku $FUNCTIONSTORAGEACCOUNTSKU
echo ""

# this creates the function app used to host the back end function
#
echo "create the function app for the back end "
az functionapp create \
    --resource-group $RESOURCEGROUPNAME \
    --consumption-plan-location $FUNCTIONCONSUMPTIONPLANREGION \
    --name $FUNCTIONNAME \
    --storage-account $FUNCTIONSTORAGEACCOUNTNAME \
    --runtime $FUNCTIONRUNTIME
echo ""

# this grabs the static website storage primary endpoint to be used when
# setting the authentication of the function
echo "getting the static website storage's primary endpoint "
staticWebsiteUrl="$(az storage account show -n $STORAGEACCOUNTNAME -g $RESOURCEGROUPNAME --query "primaryEndpoints.web" --output tsv)"
echo "static website storage's primary endpoint: $staticWebsiteUrl"
echo ""

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
echo ""

# this creates an instance of appliction insight
#
echo "creating application insight for the function"
appInsightCreateResponse="$(az resource create \
    --resource-group $RESOURCEGROUPNAME \
    --resource-type "Microsoft.Insights/components" \
    --name $APPLICATIONINSIGHTNAME \
    --location $APPLICATIONINSIGHTLOCATION \
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
    --name $FUNCTIONNAME \
    --resource-group $RESOURCEGROUPNAME \
    --settings "APPINSIGHTS_INSTRUMENTATIONKEY = $instrumentationKey"
echo ""



# # this addes the front door extension to the azure cli. It's currently in preview
# # hopefully i can remove this soon
# #
# az extension add \
#     --name front-door

# # this creates the front door service used to route all of our 

# # this grabs the url for the function app
# #
# echo "getting the url to the azure function"
# functionUrl="$(az functionapp config hostname list --resource-group the-urlist-serverless-abel3 --webapp-name theurlistfunction --query [0].name)"
# functionUrl="$(sed -e 's/^"//' -e 's/"$//' <<<"$functionUrl")"
# echo "function url: $functionUrl"
# echo ""

# # this creates the front door service
# #
# echo "creating front door service"
# az network front-door create \
#     --backend-address $functionUrl \
#     --name $FRONTDOORNAME \
#     --resource-group $RESOURCEGROUPNAME \
#     --backend-host-header $DNSNAME
# echo ""

# # this creates the load balancer for front door frontend
# echo "creating load balancer for front door frontend"
# az network front-door load-balancing create \
#     --front-door-name $FRONTDOORNAME \
#     --name frontendLoadBalanceSetting \
#     --resource-group $RESOURCEGROUPNAME \
#     --sample-size 4 \
#     --successful-samples-required 2
# echo ""

# # this creates the health probe for front door frontend
# #
# echo "creating health probe for front door frontend"
# az network front-door probe create \
#     --front-door-name $FRONTDOORNAME \
#     --interval 255 \
#     --name frontendHealthProbe \
#     --path / \
#     --resource-group $RESOURCEGROUPNAME
# echo ""

# # this creates the backend pool frontend
# #
# echo "creating backend pool frontend"
# fqdnStaticWebsite="$(awk -F/ '{print $3}' <<<$staticWebsiteUrl)"
# echo "    fqdn of static website: $fqdnStaticWebsite"
# az network front-door backend-pool create \
#     --address $fqdnStaticWebsite \
#     --front-door-name $FRONTDOORNAME \
#     --load-balancing frontendLoadBalanceSetting \
#     --name frontend \
#     --probe frontendHealthProbe \
#     --resource-group $RESOURCEGROUPNAME
# echo ""


# # this creates the load balancer for front door backend
# # 
# echo "creating load balancer for front door backend"
# az network front-door load-balancing create \
#     --front-door-name $FRONTDOORNAME \
#     --name backendLoadBalanceSetting \
#     --resource-group $RESOURCEGROUPNAME \
#     --sample-size 4 \
#     --successful-samples-required 2
# echo ""

# # this creates the health probe for front door backend
# #
# echo "creating health probe for front door backend"
# az network front-door probe create \
#     --front-door-name $FRONTDOORNAME \
#     --interval 255 \
#     --name backendHealthProbe \
#     --path / \
#     --resource-group $RESOURCEGROUPNAME
# echo ""

# # this creates the backend pool backend
# #
# echo "creating backend pool backend"
# az network front-door backend-pool create \
#     --address $functionUrl \
#     --front-door-name $FRONTDOORNAME \
#     --load-balancing backendLoadBalanceSetting \
#     --name backend \
#     --probe backendHealthProbe \
#     --resource-group $RESOURCEGROUPNAME
# echo ""

# # this creates a temp routing rule so we can delete the default created 
# # routing rule. have to go through this round about way because a default
# # routing rule and a default backend pool gets created. And you can't add another rule with the same
# # endpoint and pattern. And you can't delete a routing rule if there is only 
# # one. So the plan is, create a temp routing rule with a crazy pattern match,
# # then delete the Default Routing Rule, then create my real routing rule, then
# # delete the temp routing rule. And finally, delete the default back end pool.
# # There has got to be a better way to do this!
# #
# echo "creating a temp routing rule"
# az network front-door routing-rule create \
#     --front-door-name $FRONTDOORNAME \
#     --frontend-endpoints DefaultFrontendEndpoint \
#     --name tempRoutingRule \
#     --resource-group $RESOURCEGROUPNAME \
#     --route-type Forward \
#     --patterns /abeltemp/* \
#     --backend-pool frontend
# echo ""

# # this deletes the DefaultRoutingRule that was automatically created
# #
# echo "Deleting DefaultRoutingRule"
# az network front-door routing-rule delete \
#     --front-door-name $FRONTDOORNAME \
#     --name DefaultRoutingRule \
#     --resource-group $RESOURCEGROUPNAME
# echo ""

# # this creates the routing rule frontend
# #
# echo "creating routing rule for frontend"
# az network front-door routing-rule create \
#     --front-door-name $FRONTDOORNAME \
#     --frontend-endpoints DefaultFrontendEndpoint \
#     --name frontend \
#     --resource-group $RESOURCEGROUPNAME \
#     --route-type Forward \
#     --accepted-protocols Http Https \
#     --backend-pool frontend \
#     --forwarding-protocol HttpsOnly
# echo ""

# # this deletes the temp routing rule
# #
# echo "Deleting tempRoutingRule"
# az network front-door routing-rule delete \
#     --front-door-name $FRONTDOORNAME \
#     --name tempRoutingRule \
#     --resource-group $RESOURCEGROUPNAME
# echo ""

# # this deletes the DefaultBackendPool
# #
# echo "Deleting DefaultBackendPool"
# az network front-door backend-pool delete \
#     --front-door-name $FRONTDOORNAME \
#     --name DefaultBackendPool \
#     --resource-group $RESOURCEGROUPNAME
# echo ""

# # this creates the routing rule api
# #
# echo "creating routing rule for api"
# az network front-door routing-rule create \
#     --front-door-name $FRONTDOORNAME \
#     --frontend-endpoints DefaultFrontendEndpoint \
#     --name api \
#     --resource-group $RESOURCEGROUPNAME \
#     --route-type Forward \
#     --accepted-protocols Http Https \
#     --backend-pool backend \
#     --forwarding-protocol HttpsOnly \
#     --patterns /api/*
# echo ""

# # this lists all dns records from cloudflare
# #
# echo "getting all dns records from cloudflare"
# listDnsResult="$(curl \
#     --header "X-Auth-Key: $CLOUDFLAREKEY" \
#     --header "X-Auth-Email: $CLOUDFLAREEMAIL" \
#     https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/dns_records)"
# listDnsResult="$(echo "$listDnsResult" | jq '.')"
# echo "dsn records from cloudflare"
# echo "$listDnsResult"
# echo ""

# # this parses the number of dns entries from the response using jq
# #
# echo "getting number of dns entries at cloudflare"
# numEntries="$(echo "$listDnsResult" | jq '.["result"] | length')"
# echo "number of dns entries: $numEntries" 
# echo ""

# # this looks for our dns name, see if it has been set or not
# #
# foundDnsEntry=false
# foundDnsEntryId="x"
# for (( i=0; i<$numEntries; i++))
# do
#     dnsEntryName="$(echo $listDnsResult | jq '.["result"]['$i']["name"]')"
#     # this strips off the begin and end quotes
#     dnsEntryName="$(sed -e 's/^"//' -e 's/"$//' <<<"$dnsEntryName")"
#     if [  $dnsEntryName = "www.abelurlist.club" ] ;
#     then
#         foundDnsEntry=true
#         foundDnsEntryId="$(echo $listDnsResult | jq '.["result"]['$i']["id"]')"
#         # this strips off the begin and end quotes
#         foundDnsEntryId="$(sed -e 's/^"//' -e 's/"$//' <<<"$foundDnsEntryId")"
#         break
#     fi
# done
# echo "found dns entry: $foundDnsEntry"
# echo "dns entry id: $foundDnsEntryId"
# echo ""

# # this either updates or adds a new dns entry to cloudflare
# #
# frontDoorFQDN=$FRONTDOORNAME".azurefd.net"
# echo "front door fqdn: $frontDoorFQDN"
# if [ $foundDnsEntry = true ] ;
# then
#     echo "updating dns entry"
#     curlResponse="$(curl \
#         -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/dns_records/$foundDnsEntryId" \
#         -H "X-Auth-Email: $CLOUDFLAREEMAIL" \
#         -H "X-Auth-Key: $CLOUDFLAREKEY" \
#         -H "Content-Type: application/json" \
#         --data '{"type":"CNAME", "name":"www", "content":"'$frontDoorFQDN'", "proxied":false}')"
#     echo "cloudflare response: "
#     echo "$curlResponse"
#     echo ""
# else
#     echo "adding new dns entry"
#     curlResponse="$(curl \
#         -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/dns_records" \
#         -H "X-Auth-Email: $CLOUDFLAREEMAIL" \
#         -H "X-Auth-Key: $CLOUDFLAREKEY" \
#         -H "Content-Type: application/json" \
#         --data '{"type":"CNAME", "name":"www", "content":"'$frontDoorFQDN'", "priority":10, "proxied":false}')"
#     echo "    cloudflare response: "
#     echo $curlResponse
#     echo ""
# fi
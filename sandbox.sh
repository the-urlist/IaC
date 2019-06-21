# this creates an instance of appliction insight
#
echo "creating application insight for the function"
appInsightCreateResponse="$(az resource create \
    --resource-group the-urlist-serverless-abel3 \
    --resource-type "Microsoft.Insights/components" \
    --name abelurlistfunctionappinsight \
    --location southcentralus \
    --properties '{"Application_Type":"web"}')" 
echo "$appInsightCreateResponse"
echo ""

# this grabs the instrumentation key from the creation response
#
echo $appInsightCreateResponse | jq '.["properties"]["InstrumentationKey"]'

# this wires up application insights to the function
# echo "wiring up app insight to function"
# az functionapp config appsettings set \
#     --name abelurlistfunction \
#     --resource-group the-urlist-serverless-abel3 \
#     --settings 'APPINSIGHTS_INSTRUMENTATIONKEY = <Instrumentation Key>'
# echo ""


# echo appInsightCreateResponse | grep -Po "\"InstrumentationKey\": \K\".*\"" \
#     | xargs -I % az functionapp config appsettings set \
#     --name abelurlistfunctionappinsight \
#     --resource-group the-urlist-serverless-abel3 \
#     --settings "APPINSIGHTS_INSTRUMENTATIONKEY = %"

# this creates an instance of appliction insight
echo "creating application insight for the function"
appInsightCreateResponse="$(az resource create \
    --resource-group the-urlist-serverless-abel3 \
    --resource-type "Microsoft.Insights/components" \
    --name abelurlistfunctionappinsight \
    --location southcentralus \
    --properties '{"Application_Type":"web"}')" 
echo "$appInsightCreateResponse"
echo ""

# this wires up application insights to the function
echo "wiring up app insight to function"
echo appInsightCreateResponse | grep -Po "\"InstrumentationKey\": \K\".*\"" \
    | xargs -I % az functionapp config appsettings set \
    --name abelurlistfunctionappinsight \
    --resource-group the-urlist-serverless-abel3 \
    --settings "APPINSIGHTS_INSTRUMENTATIONKEY = %"

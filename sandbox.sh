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
instrumentationKey="$(echo $appInsightCreateResponse | jq '.["properties"]["InstrumentationKey"]')"
# this strips off begin and end quotes
instrumentationKey="$(sed -e 's/^"//' -e 's/"$//' <<<"$instrumentationKey")"
echo "instrumentation key: $instrumentationKey"

# this wires up application insights to the function
# echo "wiring up app insight to function"
#
az functionapp config appsettings set \
    --name abelurlistfunction \
    --resource-group the-urlist-serverless-abel3 \
    --settings "APPINSIGHTS_INSTRUMENTATIONKEY = $instrumentationKey"
echo ""


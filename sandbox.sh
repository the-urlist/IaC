appInsightCreateResponse="$(az resource create \
    --resource-group the-urlist-serverless-abel3 \
    --resource-type "Microsoft.Insights/components" \
    --name abelurlistfunctionappinsight \
    --location southcentralus \
    --properties '{"Application_Type":"web"}')" 
    
    
#     \
# | grep -Po "\"InstrumentationKey\": \K\".*\"" \
# | xargs -I % az functionapp config appsettings set \
#     --name abelurlistfunctionappinsight \
#     --resource-group the-urlist-serverless-abel3 \
#     --settings "APPINSIGHTS_INSTRUMENTATIONKEY = %"

az resource create \
    --resource-group ca-abewan-demo-test \
    --resource-type "Microsoft.Insights/components" \
    --name abelurlistfunctionappinsight \
    --location southcentralus \
    --properties '{"Application_Type":"web"}' \
| grep -Po "\"InstrumentationKey\": \K\".*\"" \
| xargs -I % az functionapp config appsettings set \
    --name abelurlistfunctionappinsight \
    --resource-group ca-abewan-demo-test \
    --settings "APPINSIGHTS_INSTRUMENTATIONKEY = %"

# this creates the front door service
#
echo "creating front door service"
echo "getting the url to the azure function"
functionUrl="$(az functionapp config hostname list --resource-group the-urlist-serverless-abel3 --webapp-name theurlistfunction --query [0].name)"
functionUrl="$(sed -e 's/^"//' -e 's/"$//' <<<"$functionUrl")"
echo "function url: $functionUrl"
echo ""
az network front-door create \
    --backend-address $functionUrl \
    --name $FRONTDOORNAME \
    --resource-group $RESOURCEGROUPNAME \
    --backend-host-header $DNSNAME
echo ""

# this creates the load balancer for front door frontend
echo "creating load balancer for front door frontend"
az network front-door load-balancing create \
    --front-door-name $FRONTDOORNAME \
    --name frontendLoadBalanceSetting \
    --resource-group $RESOURCEGROUPNAME \
    --sample-size 4 \
    --successful-samples-required 2
echo ""

# this creates the health probe for front door frontend
#
echo "creating health probe for front door frontend"
az network front-door probe create \
    --front-door-name $FRONTDOORNAME \
    --interval 255 \
    --name frontendHealthProbe \
    --path / \
    --resource-group $RESOURCEGROUPNAME
echo ""

# this creates the backend pool frontend
#
echo "creating backend pool frontend"
staticWebsiteUrl="$(az storage account show -n $STORAGEACCOUNTNAME -g $RESOURCEGROUPNAME --query "primaryEndpoints.web" --output tsv)"
echo "static website storage's primary endpoint: $staticWebsiteUrl"
fqdnStaticWebsite="$(awk -F/ '{print $3}' <<<$staticWebsiteUrl)"
echo "    fqdn of static website: $fqdnStaticWebsite"
az network front-door backend-pool create \
    --address $fqdnStaticWebsite \
    --front-door-name $FRONTDOORNAME \
    --load-balancing frontendLoadBalanceSetting \
    --name frontend \
    --probe frontendHealthProbe \
    --resource-group $RESOURCEGROUPNAME
echo ""


# this creates the load balancer for front door backend
# 
echo "creating load balancer for front door backend"
az network front-door load-balancing create \
    --front-door-name $FRONTDOORNAME \
    --name backendLoadBalanceSetting \
    --resource-group $RESOURCEGROUPNAME \
    --sample-size 4 \
    --successful-samples-required 2
echo ""

# this creates the health probe for front door backend
#
echo "creating health probe for front door backend"
az network front-door probe create \
    --front-door-name $FRONTDOORNAME \
    --interval 255 \
    --name backendHealthProbe \
    --path / \
    --resource-group $RESOURCEGROUPNAME
echo ""

# this creates the backend pool backend
#
echo "creating backend pool backend"
az network front-door backend-pool create \
    --address $functionUrl \
    --front-door-name $FRONTDOORNAME \
    --load-balancing backendLoadBalanceSetting \
    --name backend \
    --probe backendHealthProbe \
    --resource-group $RESOURCEGROUPNAME
echo ""

# this creates a temp routing rule so we can delete the default created 
# routing rule. have to go through this round about way because a default
# routing rule and a default backend pool gets created. And you can't add another rule with the same
# endpoint and pattern. And you can't delete a routing rule if there is only 
# one. So the plan is, create a temp routing rule with a crazy pattern match,
# then delete the Default Routing Rule, then create my real routing rule, then
# delete the temp routing rule. And finally, delete the default back end pool.
# There has got to be a better way to do this!
#
echo "creating a temp routing rule"
az network front-door routing-rule create \
    --front-door-name $FRONTDOORNAME \
    --frontend-endpoints DefaultFrontendEndpoint \
    --name tempRoutingRule \
    --resource-group $RESOURCEGROUPNAME \
    --route-type Forward \
    --patterns /abeltemp/* \
    --backend-pool frontend
echo ""

# this deletes the DefaultRoutingRule that was automatically created
#
echo "Deleting DefaultRoutingRule"
az network front-door routing-rule delete \
    --front-door-name $FRONTDOORNAME \
    --name DefaultRoutingRule \
    --resource-group $RESOURCEGROUPNAME
echo ""

# this creates the routing rule frontend
#
echo "creating routing rule for frontend"
az network front-door routing-rule create \
    --front-door-name $FRONTDOORNAME \
    --frontend-endpoints DefaultFrontendEndpoint \
    --name frontend \
    --resource-group $RESOURCEGROUPNAME \
    --route-type Forward \
    --accepted-protocols Http Https \
    --backend-pool frontend \
    --forwarding-protocol HttpsOnly
echo ""

# this deletes the temp routing rule
#
echo "Deleting tempRoutingRule"
az network front-door routing-rule delete \
    --front-door-name $FRONTDOORNAME \
    --name tempRoutingRule \
    --resource-group $RESOURCEGROUPNAME
echo ""

# this deletes the DefaultBackendPool
#
echo "Deleting DefaultBackendPool"
az network front-door backend-pool delete \
    --front-door-name $FRONTDOORNAME \
    --name DefaultBackendPool \
    --resource-group $RESOURCEGROUPNAME
echo ""

# this creates the routing rule api
#
echo "creating routing rule for api"
az network front-door routing-rule create \
    --front-door-name $FRONTDOORNAME \
    --frontend-endpoints DefaultFrontendEndpoint \
    --name api \
    --resource-group $RESOURCEGROUPNAME \
    --route-type Forward \
    --accepted-protocols Http Https \
    --backend-pool backend \
    --forwarding-protocol HttpsOnly \
    --patterns /api/*
echo ""

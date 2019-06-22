# this script file creates the front door service used to route all of our 
# traffic and configures everything
#

# this addes the front door extension to the azure cli. It's currently in preview
# hopefully i can remove this soon
#
az extension add \
    --name front-door

# this grabs the url for the function app
#
echo "getting the url to the azure function"
functionUrl="$(az functionapp config hostname list --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME --webapp-name $IAC_EXCLUSIVE_FUNCTIONNAME --query [0].name)"
functionUrl="$(sed -e 's/^"//' -e 's/"$//' <<<"$functionUrl")"
echo "function url: $functionUrl"
echo ""

# this creates the front door service
#
echo "creating front door service"
az network front-door create \
    --backend-address $functionUrl \
    --name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
    --backend-host-header $IAC_DNSNAME
echo ""

# this creates the Frontend Host for domain name
#
echo "creating frontend host domain name: $IAC_DNSNAME"
az network front-door frontend-endpoint create \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --host-name $IAC_DNSNAME \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
    --name $IAC_FRIENDLYDNSNAME
echo ""

# this sets enables https for the frontend hsot
echo "enabling https for front end host $IAC_FRIENDLYDNSNAME"
az network front-door frontend-endpoint enable-https \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME\
    --name $IAC_FRIENDLYDNSNAME\
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
echo ""

# this creates the load balancer for front door frontend
echo "creating load balancer for front door frontend"
az network front-door load-balancing create \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --name frontendLoadBalanceSetting \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
    --sample-size 4 \
    --successful-samples-required 2
echo ""

# this creates the health probe for front door frontend
#
echo "creating health probe for front door frontend"
az network front-door probe create \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --interval 255 \
    --name frontendHealthProbe \
    --path / \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
echo ""

# this creates the backend pool frontend
#
echo "creating backend pool frontend"
staticWebsiteUrl="$(az storage account show -n $IAC_EXCLUSIVE_WEBSTORAGEACCOUNTNAME -g $IAC_EXCLUSIVE_RESOURCEGROUPNAME --query "primaryEndpoints.web" --output tsv)"
echo "static website storage's primary endpoint: $staticWebsiteUrl"
fqdnStaticWebsite="$(awk -F/ '{print $3}' <<<$staticWebsiteUrl)"
echo "    fqdn of static website: $fqdnStaticWebsite"
az network front-door backend-pool create \
    --address $fqdnStaticWebsite \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --load-balancing frontendLoadBalanceSetting \
    --name frontend \
    --probe frontendHealthProbe \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
echo ""


# this creates the load balancer for front door backend
# 
echo "creating load balancer for front door backend"
az network front-door load-balancing create \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --name backendLoadBalanceSetting \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
    --sample-size 4 \
    --successful-samples-required 2
echo ""

# this creates the health probe for front door backend
#
echo "creating health probe for front door backend"
az network front-door probe create \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --interval 255 \
    --name backendHealthProbe \
    --path / \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
echo ""

# this creates the backend pool backend
#
echo "creating backend pool backend"
az network front-door backend-pool create \
    --address $functionUrl \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --load-balancing backendLoadBalanceSetting \
    --name backend \
    --probe backendHealthProbe \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
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
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --frontend-endpoints DefaultFrontendEndpoint \
    --name tempRoutingRule \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
    --route-type Forward \
    --patterns /abeltemp/* \
    --backend-pool frontend
echo ""

# this deletes the DefaultRoutingRule that was automatically created
#
echo "Deleting DefaultRoutingRule"
az network front-door routing-rule delete \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --name DefaultRoutingRule \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
echo ""

# this creates the routing rule frontend
#
echo "creating routing rule for frontend"
az network front-door routing-rule create \
    --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
    --frontend-endpoints DefaultFrontendEndpoint $IAC_FRIENDLYDNSNAME \
    --name frontend \
    --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
    --route-type Forward \
    --accepted-protocols HttpsOnly \
    --backend-pool frontend \
    --forwarding-protocol HttpsOnly
echo ""

# # this deletes the temp routing rule
# #
# echo "Deleting tempRoutingRule"
# az network front-door routing-rule delete \
#     --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
#     --name tempRoutingRule \
#     --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
# echo ""

# # this deletes the DefaultBackendPool
# #
# echo "Deleting DefaultBackendPool"
# az network front-door backend-pool delete \
#     --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
#     --name DefaultBackendPool \
#     --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
# echo ""

# # this creates the routing rule api
# #
# echo "creating routing rule for api"
# az network front-door routing-rule create \
#     --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
#     --frontend-endpoints DefaultFrontendEndpoint \
#     --name api \
#     --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME \
#     --route-type Forward \
#     --accepted-protocols Http Https \
#     --backend-pool backend \
#     --forwarding-protocol HttpsOnly \
#     --patterns /api/*
# echo ""

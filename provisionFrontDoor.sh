# this creates and configures a front door resource using an 
# ARM template
#

1_Up() {
    # this creates front door from arm template
    # 
    echo "create Front Door: $IAC_EXCLUSIVE_FRONTDOORNAME"
    az group deployment create --name azuredeployfd --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME --template-file "$AGENT_RELEASEDIRECTORY/AbelIaCBuild/drop/frontdoorazuredeploy.json" --parameters frontDoorName=$IAC_EXCLUSIVE_FRONTDOORNAME backendPool1Address1="$IAC_EXCLUSIVE_WEBSTORAGEACCOUNTNAME.z21.web.core.windows.net" backendPool2Address1="$IAC_EXCLUSIVE_FUNCTIONNAME.azurewebsites.net" customDomainName="$IAC_DNSNAME"
    echo ""

    # this addes the front door extension to the azure cli. It's currently in preview
    # hopefully i can remove this soon
    #
    az extension add \
        --name front-door

    # this enables https for the custom domain front end host
    #
    echo "enabling https for front end host $IAC_FRIENDLYDNSNAME"
    az network front-door frontend-endpoint enable-https \
        --front-door-name $IAC_EXCLUSIVE_FRONTDOORNAME \
        --name $IAC_FRIENDLYDNSNAME \
        --resource-group $IAC_EXCLUSIVE_RESOURCEGROUPNAME
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
echo "getting infrastructure version"
curlResponse="$(curl --max-time 12 --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionRetriever?tablename=abelurlist&stage=beta&infraname=frontdoor")"
echo "curlResponce: $curlResponse"
if [ -z $curlResponse ] ;
then
    echo "curl response is empty, setting current version to 0"
	CURRENTVERSION=0
else
	CURRENTVERSION=$curlResponse
fi
echo "current infrastructure version: $CURRENTVERSION"

# call the correct up  
if [  $CURRENTVERSION >= $LATERSTVERSION ] ;
then
    echo "infrastructure version up to date"
else 
    echo "current infrastructure version: $CURRENTVERSION"
    echo "updating infrastructure to version: $LATESTVERSION"
fi
for (( i=($CURRENTVERSION); i<LATESTVERSION; i++))
do
    echo "executing $i""_Up()"
    "$i"_Up
    # register new version of infrastructure deployed
    echo "registering new version of infrastructure"
	curlResponse="$(curl --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionUpdater?tablename=abelurlist&stage=beta&infraname=frontdoor")"
	echo "curl response: $curlResponse"
done
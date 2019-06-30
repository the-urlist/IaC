# this configures DNS with the right values
#
1_Up() {
    # this lists all dns records from cloudflare
    #
    echo "getting all dns records from cloudflare"
    echo "cloudflare key: $CLOUDFLAREKEY"
    echo "cloudflare email: $CLOUDFLAREEMAIL"
    listDnsResult="$(curl \
        --header "X-Auth-Key: $CLOUDFLAREKEY" \
        --header "X-Auth-Email: $CLOUDFLAREEMAIL" \
        https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/dns_records)"
    listDnsResult="$(echo "$listDnsResult" | jq '.')"
    echo "dsn records from cloudflare"
    echo "$listDnsResult"
    echo ""

    # this parses the number of dns entries from the response using jq
    #
    echo "getting number of dns entries at cloudflare"
    numEntries="$(echo "$listDnsResult" | jq '.["result"] | length')"
    echo "number of dns entries: $numEntries" 
    echo ""

    # this looks for our dns name, see if it has been set or not
    #
    foundDnsEntry=false
    foundDnsEntryId="x"
    for (( i=0; i<$numEntries; i++))
    do
        dnsEntryName="$(echo $listDnsResult | jq '.["result"]['$i']["name"]')"
        # this strips off the begin and end quotes
        dnsEntryName="$(sed -e 's/^"//' -e 's/"$//' <<<"$dnsEntryName")"
        if [  $dnsEntryName = "www.abelurlist.club" ] ;
        then
            foundDnsEntry=true
            foundDnsEntryId="$(echo $listDnsResult | jq '.["result"]['$i']["id"]')"
            # this strips off the begin and end quotes
            foundDnsEntryId="$(sed -e 's/^"//' -e 's/"$//' <<<"$foundDnsEntryId")"
            break
        fi
    done
    echo "found dns entry: $foundDnsEntry"
    echo "dns entry id: $foundDnsEntryId"
    echo ""

    # this either updates or adds a new dns entry to cloudflare
    #
    frontDoorFQDN=$IAC_EXCLUSIVE_FRONTDOORNAME".azurefd.net"
    echo "front door fqdn: $frontDoorFQDN"
    if [ $foundDnsEntry = true ] ;
    then
        echo "updating dns entry"
        curlResponse="$(curl \
            -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/dns_records/$foundDnsEntryId" \
            -H "X-Auth-Email: $CLOUDFLAREEMAIL" \
            -H "X-Auth-Key: $CLOUDFLAREKEY" \
            -H "Content-Type: application/json" \
            --data '{"type":"CNAME", "name":"www", "content":"'$frontDoorFQDN'", "proxied":false}')"
        echo "cloudflare response: "
        echo "$curlResponse"
        echo ""
    else
        echo "adding new dns entry"
        curlResponse="$(curl \
            -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/dns_records" \
            -H "X-Auth-Email: $CLOUDFLAREEMAIL" \
            -H "X-Auth-Key: $CLOUDFLAREKEY" \
            -H "Content-Type: application/json" \
            --data '{"type":"CNAME", "name":"www", "content":"'$frontDoorFQDN'", "priority":10, "proxied":false}')"
        echo "    cloudflare response: "
        echo $curlResponse
        echo ""
    fi
}

# This queries the environment for the current version and then applies only 
# the changes necessary to bring the environment up to the latest version.
# The latest version variable needs to be manually updated each time you
# add a new Up function.
#
LATESTVERSION=1;
CURRENTVERSION=0
# get current version of infrastructure
curlResponse="$(curl --max-time 12 --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionRetriever?tablename=abelurlist&stage=beta&infraname=dns")"
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
for (( i=($CURRENTVERSION+1); i<=LATESTVERSION; i++))
do
    echo "executing $i""_Up()"
    "$i"_Up
    # register new version of infrastructure deployed
	curlResponse="$(curl --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionUpdater?tablename=abelurlist&stage=beta&infraname=dns")"
	echo "curl response: $curlResponse"
done

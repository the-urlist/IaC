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

# This script sets up the apex domain url (no www)in dns to point and direct
# to the right place
#
2_Up() {
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
        if [  $dnsEntryName = "$IAC_DNSNAMENAKED" ] ;
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

    # this either updates or adds a new dns entry to cloudflare for
    # the apex domain url abelurlist.club
    #
    urlistFQDN=$IAC_DNSNAME
    echo "urlist fqdn: $urlistFQDN"
    if [ $foundDnsEntry = true ] ;
    then
        echo "updating dns entry"
        curlResponse="$(curl \
            -X PUT "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/dns_records/$foundDnsEntryId" \
            -H "X-Auth-Email: $CLOUDFLAREEMAIL" \
            -H "X-Auth-Key: $CLOUDFLAREKEY" \
            -H "Content-Type: application/json" \
            --data '{"type":"CNAME", "name":"@", "content":"'$frontDoorFQDN'", "proxied":true}')"
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
            --data '{"type":"CNAME", "name":"@", "content":"'$frontDoorFQDN'", "priority":10, "proxied":true}')"
        echo "    cloudflare response: "
        echo $curlResponse
        echo ""
    fi

    # this looks to see if we need to add a page rule for apex domain
    # first by looking up all the rules
    #
    echo "getting all rules from cloudflare"
    echo "cloudflare key: $CLOUDFLAREKEY"
    echo "cloudflare email: $CLOUDFLAREEMAIL"
    listRulesResult="$(curl -X GET "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/pagerules?status=active&order=status&direction=desc&match=all" \
        --header "X-Auth-Key: $CLOUDFLAREKEY" \
        --header "X-Auth-Email: $CLOUDFLAREEMAIL" \
        --header "Content-TYpe: application/json" \
        )"
    listRulesResult="$(echo "$listRulesResult" | jq '.')"
    echo "rules from cloudflare"
    echo "$listRulesResult"
    echo "" 

    # this parses the number of rule entries from the response using jq
    #
    echo "getting number of rule entries at cloudflare"
    numEntries="$(echo "$listRulesResult" | jq '.["result"] | length')"
    echo "number of rule entries: $numEntries" 
    echo ""

    ## delete these old rule entries
    #
    echo "deleting all entries"
    for (( i=0; i<$numEntries; i++))
    do
        ruleId="$(echo "$listRulesResult" | jq '.["result"][0].id' )" 
        # this strips off the begin and end quotes
        ruleId="$(sed -e 's/^"//' -e 's/"$//' <<<"$ruleId")"
        echo "deleting rule with id: $ruleId"
        curl -X DELETE "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/pagerules/$ruleId" \
            --header "X-Auth-Email: $CLOUDFLAREEMAIL" \
            --header "X-Auth-Key: $CLOUDFLAREKEY"
    done
    echo ""

    # Add in the apex domain rule
    #
    echo "adding apex domain rule"
    curl -X POST "https://api.cloudflare.com/client/v4/zones/$CLOUDFLAREZONE/pagerules" \
        --header "X-Auth-Email: $CLOUDFLAREEMAIL" \
        --header "X-Auth-Key: $CLOUDFLAREKEY" \
        --header "Content-Type: application/json" \
        --data '{"targets":[{"target":"url", "constraint":{"operator":"matches","value":"abelurlist.club/*"}}],"actions":[{"id":"forwarding_url","value": {"url": "https://www.abelurlist.club/$1","status_code": 301}}],"priority":1,"status":"active"}'
    echo ""
    echo "done adding apex domain rule"
    echo ""
}

# This queries the environment for the current version and then applies only 
# the changes necessary to bring the environment up to the latest version.
# The latest version variable needs to be manually updated each time you
# add a new Up function.
#
LATESTVERSION=2;
CURRENTVERSION=0
# get current version of infrastructure
echo "getting infrastructure version"
curlResponse="$(curl --max-time 12 --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionRetriever?tablename=abelurlist&stage=beta&infraname=dns")"
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
if [  $CURRENTVERSION -ge $LATESTVERSION ] ;
then
    echo "infrastructure version up to date"
else 
    echo "updating infrastructure to version: $LATESTVERSION"
fi

for (( methodIndex=$((CURRENTVERSION + 1)); methodIndex<=$LATESTVERSION; methodIndex++ ))
do
    echo "executing $methodIndex""_Up()"
    "$methodIndex"_Up
    echo "done with $methodIndex""_Up()"
    
    # register new version of infrastructure deployed
    echo ""
    echo "registering new version of infrastructure"
	curlResponse="$(curl --request GET "https://$IAC_EXCLUSIVE_INFRATOOLSFUNCTIONNAME.azurewebsites.net/api/InfraVersionUpdater?tablename=abelurlist&stage=beta&infraname=dns")"
	echo ""
    echo "curl response: $curlResponse"
done

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
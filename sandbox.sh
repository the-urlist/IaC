# this lists all dns records from cloudflare
echo "getting all dns records from cloudflare"
listDnsResult="$(curl \
    --header "X-Auth-Key: a084cb5ec135f5619f40895e958a138add805" \
    --header "X-Auth-Email: abel.wang@gmail.com" \
    https://api.cloudflare.com/client/v4/zones/3d7a85d315c8ff6541921c7c2bce9abe/dns_records)"
listDnsResult="$(echo "$listDnsResult" | jq '.')"
echo "dsn records from cloudflare"
echo "$listDnsResult"
echo

# this gets the number of dns entries
echo "getting number of dns entries at cloudflare"
numEntries="$(echo "$listDnsResult" | jq '.["result"] | length')"
echo "number of dns entries: $numEntries" 

# this looks for our dns name, see if it has been set or not
#
foundDnsEntry=false 
for (( i=0; i<$numEntries; i++))
do
    if [ "$(echo $listDnsResult | jq '.["result"]['$i']["name"]')" = "\"www.abelurlist.club\"" ] ;
    then
        foundDnsEntry=true
        break
    fi
done
echo "found dns entry: $foundDnsEntry"

if [ $foundDnsEntry = true ] ;
then
    echo "updating dns entry"
    curl \
        -X PUT "https://api.cloudflare.com/client/v4/zones/3d7a85d315c8ff6541921c7c2bce9abe/dns_records/da001a069cfd3ab2c98462eefd7f144b" \
        -H "X-Auth-Email: abel.wang@gmail.com" \
        -H "X-Auth-Key: a084cb5ec135f5619f40895e958a138add805" \
        -H "Content-Type: application/json" \
        --data '{ \
            "type":"CNAME", \
            "name":"www", \
            "content":"abelurlistfd.azurefd.net", \
            "proxied":false \
        }'
else
    echo "adding new dns entry"
    addNewDnsEntryResult="$(curl -X POST "https://api.cloudflare.com/client/v4/zo2bce9abe/dns_records" -H "X-Auth-Email: abel.wang@gmail.com" -H "X-Auth-Key: a084cb5ec135f5619f40895e958a138add805" -H "Content-Type: application/json" --data '{"type":"CNAME", "name":"testdata", "content":"abelurlistfd.azurefd.net", "priority":10, "proxied":false}')"
    echo "    result message: "
    echo $addNewDnsEntryResult
fi
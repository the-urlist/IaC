# this lists all dns records from cloudflare
echo "getting all dns records from cloudflare"
listDnsResult="$(curl --header "X-Auth-Key: a084cb5ec135f5619f40895e958a138add805" --header "X-Auth-Email: abel.wang@gmail.com" https://api.cloudflare.com/client/v4/zones/3d7a85d315c8ff6541921c7c2bce9abe/dns_records)"
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
else
    echo "adding new dns entry"
fi
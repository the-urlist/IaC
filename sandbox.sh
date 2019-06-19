# this lists all dns records from cloudflare
echo "getting all dns records from cloudflare"
listDnsResult="$(curl --header "X-Auth-Key: a084cb5ec135f5619f40895e958a138add805" --header "X-Auth-Email: abel.wang@gmail.com" https://api.cloudflare.com/client/v4/zones/3d7a85d315c8ff6541921c7c2bce9abe/dns_records)"
listDnsResult="$(echo "$listDnsResult" | jq '.')"
echo "dsn records from cloudflare"
echo "$listDnsResult"
echo
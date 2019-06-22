TENANT="72f988bf-86f1-41af-91ab-2d7cd011db47"
CLIENT_ID="$servicePrincipalId"
CLIENT_SECRET="$servicePrincipalKeyX"
SUBSCRIPTION_ID="e97f6c4e-c830-479b-81ad-1aff1dd07470"
RESOURCE_GROUP="dnscheckerrg"
FUNCTION_APP_NAME="abeldnschecker"
API_URL="https://abeldnschecker.scm.azurewebsites.net/api/functions/admin/token"
SITE_URL="https://abeldnschecker.azurewebsites.net/admin/host/systemkeys/_master"

### Grab a fresh bearer access token.
ACCESS_TOKEN=$(curl -s -X POST -F grant_type=client_credentials -F resource=https://management.azure.com/ -F client_id=$CLIENT_ID -F client_secret=$CLIENT_SECRET https://login.microsoftonline.com/$TENANT/oauth2/token | jq '.access_token' -r)

### Grab the publish data for the Funciton App and output it to an XML file.
PUBLISH_DATA=$(curl -s -X POST -H "Content-Length: 0" -H "Authorization: Bearer $ACCESS_TOKEN" https://management.azure.com/subscriptions/$SUBSCRIPTION_ID/resourceGroups/$RESOURCE_GROUP/providers/Microsoft.Web/sites/$FUNCTION_APP_NAME/publishxml?api-version=2016-08-01)
echo $PUBLISH_DATA > publish_data.xml

### Grab the Kudu username and password from the publish data XML file.
USER_NAME=$(xmlstarlet sel -t -v "//publishProfile[@profileName='$FUNCTION_APP_NAME - Web Deploy']/@userName" publish_data.xml)
USER_PASSWORD=$(xmlstarlet sel -t -v "//publishProfile[@profileName='$FUNCTION_APP_NAME - Web Deploy']/@userPWD" publish_data.xml)

### Generate a JWT that can be used with the Functions Key API.
JWT=$(curl -s -X GET -u $USER_NAME:$USER_PASSWORD $API_URL | tr -d '"')

### Grab the '_master' key from the Functions Key API.
KEY=$(curl -s -X GET -H "Authorization: Bearer $JWT" $SITE_URL | jq -r '.value')
echo "key: $KEY"
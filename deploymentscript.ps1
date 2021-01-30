# az login --use-device-code
$output = az account show | ConvertFrom-Json
Write-Host "Currently logged in to subscription" $output.id " in tenant " $output.tenantId
$deploymentName = Read-Host -Prompt "Enter webapp name"
$location = Read-Host -Prompt "Enter location (eastus)"
$resourceGroup = $deploymentName + "-rg"
Write-Host "Creating resource group " $resourceGroup
az group create --location $location --name $resourceGroup
$databaseName = $deploymentName + "db"

Write-Host "Deploying Sample application.. (this might take a few minutes)"
$deploymentOutputs = az deployment group create --resource-group $resourceGroup --mode Incremental --template-file ./windows-webapp-template.json --parameters "webAppName=$deploymentName" --parameters "hostingPlanName=$deploymentName-host" --parameters "appInsightsLocation=$location" --parameters "sku=P1V2 Premium" --parameters "databaseAccountId=$databaseName" --parameters "databaseAccountLocation=$location"
$deploymentOutputs = $deploymentOutputs | ConvertFrom-Json
$connectionString=$deploymentOutputs.properties.outputs.azureCosmosDBAccountKeys.value.connectionStrings[0].connectionString

az webapp config appsettings set --name $deploymentName --resource-group $resourceGroup --settings CONNECTION_STRING="$connectionString"
az webapp config appsettings set --name $deploymentName --resource-group $resourceGroup --settings MSDEPLOY_RENAME_LOCKED_FILES=1

$publishConfig = az webapp deployment list-publishing-credentials --name $deploymentName --resource-group $resourceGroup | ConvertFrom-Json

Write-Host "Publishing sample app.. (this might take a minute or two)"
git init
git add -A
git commit -m "Initial commit"
git remote add azwebapp $publishConfig.scmUri
git push azwebapp master

Start-Process "https://$deploymentName.azurewebsites.net"

Write-Host "Deployment Complete"
Write-Host "To delete the app, run command 'az group delete $resourceGroup'"
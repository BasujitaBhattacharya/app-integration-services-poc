targetScope = 'resourceGroup'
 
@minLength(1)
@maxLength(16)
@description('Prefix for all resources, i.e. {name}storage')
param name string
 
@minLength(1)
@description('Primary location for all resources')
param location string
 
@description('The email address of the owner of the service')
@minLength(1)
param publisherEmail string
 
@description('The name of the owner of the service')
@minLength(1)
param publisherName string
 
param rgname string
 
// resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
//   name: 'rg-${name}'
//   location: location
//   tags: {
//     apptemplate: 'IntegrationSample'
//   }
// }
 
 
module apim './modules/apim.bicep' = {
  name: '${name}-apim'
  // scope: resourceGroup(rgname)
  params: {
    apimServiceName: 'apim-${toLower(name)}'
    publisherEmail: publisherEmail
    publisherName: publisherName
    location: location
  }
}
 
module servicebus './modules/service-bus.bicep' = {
  name: '${name}-servicebus'
  // scope: resourceGroup(rgname)
  params: {
    nameSpace: 'sb-${toLower(name)}'
    location: location
  }
}
 
module cosmosdb './modules/cosmosdb.bicep' = {
  name: '${name}-cosmosdb'
  // scope: resourceGroup(rgname)
  params: {
    accountName: 'cosmos-${toLower(name)}'
    location: location
  }
}
 
module function './modules/function.bicep' = {
  name: '${name}-function'
  // scope: resourceGroup(rgname)
  params: {
    appName: 'func-${toLower(name)}'
    location: location
    appInsightsLocation: location
  }
}
 
module roleAssignmentAPIMSenderSB './modules/configure/roleAssign-apim-service-bus.bicep' = {
  name: '${name}-roleAssignmentAPIMSB'
  scope: resourceGroup(rgname)
  params: {
    apimServiceName: apim.outputs.apimServiceName
    sbNameSpace: servicebus.outputs.sbNameSpace
  }
  dependsOn: [
    apim
    servicebus
  ]
}
 
module roleAssignmentFcuntionReceiverSB './modules/configure/roleAssign-function-service-bus.bicep' = {
  name: '${name}-roleAssignmentFunctionSB'
  // scope: resourceGroup(rgname)
  params: {
    functionAppName: function.outputs.functionAppName
    sbNameSpace: servicebus.outputs.sbNameSpace
  }
  dependsOn: [
    function
    servicebus
  ]
}
 
module configurFunctionAppSettings './modules/configure/configure-function.bicep' = {
  name: '${name}-configureFunction'
  // scope: resourceGroup(rgname)
  params: {
    functionAppName: function.outputs.functionAppName
    cosmosAccountName: cosmosdb.outputs.cosmosDBAccountName
    sbHostName: servicebus.outputs.sbHostName
  }
  dependsOn: [
    function
    servicebus
    cosmosdb
  ]
}
 
module configurAPIM './modules/configure/configure-apim.bicep' = {
  name: '${name}-configureAPIM'
  // scope: resourceGroup(rgname)
  params: {
    apimServiceName: apim.outputs.apimServiceName
    sbEndpoint: servicebus.outputs.sbEndpoint
  }
  dependsOn: [
    apim
  ]
}
 
//  Telemetry Deployment
@description('Enable usage and telemetry feedback to Microsoft.')
param enableTelemetry bool = true
var telemetryId = '69ef933a-eff0-450b-8a46-331cf62e160f-apptemp-${location}'
resource telemetrydeployment 'Microsoft.Resources/deployments@2021-04-01' = if (enableTelemetry) {
  name: telemetryId
  // location: location
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
      contentVersion: '1.0.0.0'
      resources: {}
    }
  }
}
 
output apimServideBusOperation string = '${apim.outputs.apimEndpoint}/sb-operations/'

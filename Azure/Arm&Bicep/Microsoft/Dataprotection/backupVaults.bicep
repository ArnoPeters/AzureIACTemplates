// ---- Standard parameters

@description('Location for the resources in this module.')
param location string

@description('Use \'outputs.tags\' from the \'resourceGroup\' module.')
param tags object

@description('Optional. Is displayed next to the resource name in Azure. Makes uses of the undocumented \'hidden-title\' tag.')
param displayName string = ''

@description('Use \'outputs.instanceNameFormat\' from the \'resourceGroup\' module.')
param instanceNameFormat string

// ---- Template specific parameters

@description('Backup storage redundancy')
@allowed([
  'GeoRedundant'
  'LocallyRedundant'
  'ZoneRedundant'
])
param storageType string

@description('security settings object')
param securitySettings object

@description('csr object')
param featureSettings object

// ---- Deployment

@description ('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'bvault') //TODO: Set resource type shortcode

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource vault 'Microsoft.DataProtection/backupVaults@2023-01-01' = {
	name: instanceName
	location: location
	tags: fullTags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    storageSettings: [
      {
        datastoreType: 'VaultStore'
        type: storageType
      }
    ]
    securitySettings: securitySettings
    featureSettings: featureSettings
  }
}

//TODO: properly set up parameters for log analytics
// resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
//   name: lawName
//   scope: resourceGroup(lawResourceName)
// }

// //Use the json view in the portal when adding diagnostic settings to see what can be added and the correct json
// //Or when configured export the existing resource .properties.logs output
// resource logAnalyticsConfig 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
//   name: 'Configured_Through_Bicep'
//   scope: vault
//   properties: {
//     workspaceId: logAnalyticsWorkspace.id
//     logs: [
//       {
//         category: 'CoreAzureBackup'
//         enabled: true
//         retentionPolicy: {
//           days: 0
//           enabled: false
//         }
//       }
//     ]
//     metrics: []
//   }
// }

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

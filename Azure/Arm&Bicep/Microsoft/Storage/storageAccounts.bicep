// ---- Standard parameters

@description('Location for the resources in this module.')
param location string

@description('Use \'outputs.tags\' from the \'resourceGroup\' module.')
param tags object

@description('Optional. Is displayed next to the resource name in Azure. Makes uses of the undocumented \'hidden-title\' tag.')
param displayName string = ''

@description('Use \'outputs.storageAccountNameFormat\' from the \'resourceGroup\' module.')
param storageAccountNameFormat string

// ---- Template specific parameters

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep#sku')
@allowed([
  'Premium_LRS'
  'Premium_ZRS'
  'Standard_GRS'
  'Standard_GZRS'
  'Standard_LRS'
  'Standard_RAGRS'
  'Standard_RAGZRS'
  'Standard_ZRS'
])
param storageAccountSku string = 'Standard_LRS'

param deleteLockMessage string = ''

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep#storageaccounts')
@allowed([
  'BlobStorage'
  'BlockBlobStorage'
  'FileStorage'
  'Storage'
  'StorageV2'
])
param kind string = 'StorageV2'

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts?pivots=deployment-language-bicep#storageaccountpropertiescreateparametersorstorageacc')
param properties object = {}

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = toLower(format(storageAccountNameFormat, 'storageAccountNameFormat')) //TODO: Set resource type shortcode

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

// Overrides for the Azure Defaults.
var defaultProperties = {}

// Enforce values to ensure specific settings for your enviroment
var mandatoryProperties = {
  minimumTlsVersion: 'TLS1_2'
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: instanceName
  location: location
  tags: fullTags
  kind: kind
  sku: {
    name: storageAccountSku
  }
  properties: union(defaultProperties, properties, mandatoryProperties)
}

resource resourceLock 'Microsoft.Authorization/locks@2020-05-01' = if (!empty(deleteLockMessage)) {
  name: storageAccount.name
  scope: storageAccount
  properties: {
    level: 'CanNotDelete'
    notes: deleteLockMessage
  }
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

output hostNames {
  blob: string
  dfs: string
  file: string
  queue: string
  table: string
  web: string
} = {
  blob: replace(replace(storageAccount.properties.primaryEndpoints.blob, '/', ''), 'https:', '')
  dfs: replace(replace(storageAccount.properties.primaryEndpoints.dfs, '/', ''), 'https:', '')
  file: replace(replace(storageAccount.properties.primaryEndpoints.file, '/', ''), 'https:', '')
  queue: replace(replace(storageAccount.properties.primaryEndpoints.queue, '/', ''), 'https:', '')
  table: replace(replace(storageAccount.properties.primaryEndpoints.table, '/', ''), 'https:', '')
  web: replace(replace(storageAccount.properties.primaryEndpoints.web, '/', ''), 'https:', '')
}

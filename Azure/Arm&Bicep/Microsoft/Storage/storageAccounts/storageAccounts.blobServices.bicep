@description('Requires an array with names: [ \'name\', \'another-name\' ] ')
param containers array
@minLength(3)
@maxLength(24)
@description('Name of the resource. Must be between 3 and 24 characters in length and use numbers and lower-case letters only.')
param storageAccountInstanceName string

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices?pivots=deployment-language-bicep#corsrules')
param corsRules array = []

param principalId string = ''

@description('Look for all built-in role definition guids on https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles')
var roleDefinitionIds = {
  builtin: {
    StorageBlobDataContributor: 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
  }
}

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/blobservices?pivots=deployment-language-bicep#blobservicepropertiesproperties')
var properties = empty(corsRules) ? {} : {
  cors: {
    corsRules: corsRules
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountInstanceName

  resource blobServices 'blobServices' = {
    name: 'default'
    properties: properties

    resource storageAccountContainers 'containers' = [for item in containers: {
      name: item
      properties: {}
    }]
  }
}

resource StorageBlobDataContributorDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = if (!empty(principalId)) {
  scope: subscription()
  name: roleDefinitionIds.builtin.StorageBlobDataContributor
}

resource storageBlobDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(principalId, StorageBlobDataContributorDefinition.id, storageAccount.id) //I want to give Principal a Role on Resource
  scope: storageAccount
  properties: {
    roleDefinitionId: StorageBlobDataContributorDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

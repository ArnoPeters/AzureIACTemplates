@description('Requires an array with names: [ \'name\', \'another-name\' ] ')
param queues array
@minLength(3)
@maxLength(24)
@description('Name of the resource. Must be between 3 and 24 characters in length and use numbers and lower-case letters only.')
param storageAccountInstanceName string

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/queueServices?pivots=deployment-language-bicep#corsrules')
param corsRules array = []

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/queueservices?pivots=deployment-language-bicep#queueservicepropertiesproperties')
var properties = empty(corsRules) ? {} : {
  cors: {
    corsRules: corsRules
  }
}

param principalId string = ''

@description('Containers that should also go into backup. Additional containers like "dataprotection" are not in this list')

param poisonQueueNameSuffix string = ''

@description('Look for all built-in role definition guids on https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles')
var roleDefinitionIds = {
  builtin: {
    StorageQueueDataContributor: '974c5e8b-45b9-4653-ba55-5f855dd0fb88'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountInstanceName

  resource queueServices 'queueServices' = {
    name: 'default'
    properties: properties

    resource storageAccountQueues 'queues' = [for item in queues: {
      name: item
      properties: {
        metadata: {}
      }
    }]

    //For every queue, also construct a poison queue
    resource storageAccountQueues_poison 'queues' = [for item in queues: if (!empty(poisonQueueNameSuffix)) {
      name: '${item}-poison'
      properties: {
        metadata: {}
      }
    }]
  }
}

resource StorageQueueDataContributorDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = if (!empty(principalId)) {
  scope: subscription()
  name: roleDefinitionIds.builtin.StorageQueueDataContributor
}

resource storageQueueDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(principalId)) {
  name: guid(principalId, StorageQueueDataContributorDefinition.id, storageAccount.id) //I want to give Principal a Role on Resource
  scope: storageAccount
  properties: {
    roleDefinitionId: StorageQueueDataContributorDefinition.id
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

//Use a module to assign roles, to be able to target resources in another scope

@description('The principal ID.')
param principalId string

@description('The role definition ID. Look for all built-in role definition guids on https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles')
param roleDefinitionId string

@description('The principal type of the assigned principal ID. Default is \'ServicePrincipal\'')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param principalType string = 'ServicePrincipal'

@description('Name of the instance to assign the role to.')
param instanceName string

resource existingResource 'Microsoft.AppConfiguration/configurationStores@2023-03-01' existing = {
  name: instanceName
}

resource StorageQueueDataContributorDefinition 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  scope: subscription()
  name: roleDefinitionId
}

resource storageQueueDataContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' ={
  name: guid(principalId, roleDefinitionId, existingResource.id)
  scope: existingResource
  properties: {
    roleDefinitionId: StorageQueueDataContributorDefinition.id
    principalId: principalId
    principalType: principalType
  }
}

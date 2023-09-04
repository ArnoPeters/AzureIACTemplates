@description('Requires an array with names \'[ "name", "another-name" ]\'\'')
param fileshares array 
@minLength(3)
@maxLength(24)
@description('Instance name of the storage account that has fileshares that need to be added to a recovery vault.')
param storageAccountInstanceName string
@description('Resource Group name of the storage account that has fileshares that need to be added to a recovery vault.')
param storageAccountResourceGroupName string

param recoveryVaultInstanceName string
param backupPolicyName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountInstanceName
  scope: resourceGroup(storageAccountResourceGroupName)
}

resource recoveryVault 'Microsoft.RecoveryServices/vaults@2023-02-01' existing = {
  name: recoveryVaultInstanceName

  resource fileShareBackupPolicy 'backupPolicies' existing = {
    name: backupPolicyName
  }
}

resource protectionContainers 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers@2023-02-01' = {
  name: '${recoveryVaultInstanceName}/Azure/storagecontainer;Storage;${storageAccountResourceGroupName};${storageAccountInstanceName}'
  properties: {
    backupManagementType: 'AzureStorage'
    containerType: 'StorageContainer'
    sourceResourceId: storageAccount.id
  }

  resource protectedItems 'protectedItems@2023-02-01' = [for item in fileshares: {
    name: 'AzureFileShare;${item}'
    properties: {
      protectedItemType: 'AzureFileShareProtectedItem'
      sourceResourceId: storageAccount.id
      policyId: recoveryVault::fileShareBackupPolicy.id
    }
  }]
}

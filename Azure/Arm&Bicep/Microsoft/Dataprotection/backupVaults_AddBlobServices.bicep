@description('Required to create unique names and prevent Azure from overwriting the history of linked template deployments')
param deploymentDateTimeStamp string

@minLength(3)
@maxLength(24)
@description('Instance name of the storage account that has fileshares that need to be added to a recovery vault.')
param storageAccountInstanceName string
@description('Resource Group name of the storage account that has fileshares that need to be added to a recovery vault.')
param storageAccountResourceGroupName string

@description('Instance name of the backup vault.')
param backupVaultInstanceName string

param backupPolicyName string

@description('Look for all built-in role definition guids on https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles')
var roleDefinitionIds = {
  builtin: {
    StorageAccountBackupContributor: 'e5e2a7ff-d759-4cd2-bb51-3152d37e2eb1'
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountInstanceName
  scope: resourceGroup(storageAccountResourceGroupName)

  resource blobServices 'blobServices' existing = {
    name: 'default'
  }
}

//Use a module to assign roles, to be able to target resources in another scope
@description('Setting up backup will fail if the backup vault is not a storage account backup contributor')
module storageAccountBackupContributor '../Storage/storageAccounts_roleAssignments.bicep' = {
  name: take('${deploymentDateTimeStamp}-${storageAccountInstanceName}-storageAccountBackupContributor', 64)
  scope: resourceGroup(storageAccountResourceGroupName)
  params: {
    roleDefinitionId: roleDefinitionIds.builtin.StorageAccountBackupContributor
    principalId: backupVault.identity.principalId
    storageAccountInstanceName: storageAccount.name
  }
}

resource backupVault 'Microsoft.DataProtection/backupVaults@2023-01-01' existing = {
  name: backupVaultInstanceName

  resource backupPolicy 'backupPolicies' existing = {
    name: backupPolicyName
  }

  //Backup for blob containers is for the entire storage account at once.
  resource containerBackup 'backupInstances' = {
    name: '${storageAccount.name}-${storageAccount.name}-${guid(storageAccount.name)}'
    dependsOn: [
      storageAccountBackupContributor
    ]
    properties: {
      friendlyName: storageAccount.name
      dataSourceInfo: {
        resourceID: storageAccount.id
        resourceUri: storageAccount.id
        datasourceType: 'Microsoft.Storage/storageAccounts/blobServices'
        resourceName: storageAccount.name
        resourceType: 'Microsoft.Storage/storageAccounts'
        resourceLocation: storageAccount.location
        objectType: 'Datasource'
      }
      dataSourceSetInfo: {
        resourceID: storageAccount.id
        resourceUri: storageAccount.id
        datasourceType: 'Microsoft.Storage/storageAccounts/blobServices'
        resourceName: storageAccount.name
        resourceType: 'Microsoft.Storage/storageAccounts'
        resourceLocation: storageAccount.location
        objectType: 'DatasourceSet'
      }
      policyInfo: {
        policyId: backupPolicy.id
        policyParameters: {
          backupDatasourceParametersList: [
            {
              objectType: 'BlobBackupDatasourceParameters'
              containersList: []
            }
          ]
        }
      }
      objectType: 'BackupInstance'
    }
  }
}

output currentProperties object = storageAccount::blobServices.properties

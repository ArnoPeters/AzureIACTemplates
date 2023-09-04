@description('Requires an array with names: [ \'name\', \'another-name\' ] ')
param tables array

@minLength(3)
@maxLength(24)
@description('Name of the resource. Must be between 3 and 24 characters in length and use numbers and lower-case letters only.')
param storageAccountInstanceName string

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/tableServices?pivots=deployment-language-bicep#corsrules')
param corsRules array = []

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/tableservices?pivots=deployment-language-bicep#tableservicepropertiesproperties')
var properties = empty(corsRules) ? {} : {
  cors: {
    corsRules: corsRules
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountInstanceName
  resource tableServices 'tableServices' = {
    name: 'default'
    properties: properties

    resource storageAccountTables 'tables' = [for item in tables: {
      name: item
      properties: {}
    }]
  }
}

@description('Requires an array with names: [ \'name\', \'another-name\' ] ')
param fileshares array 
@minLength(3)
@maxLength(24)
@description('Name of the resource. Must be between 3 and 24 characters in length and use numbers and lower-case letters only.')
param storageAccountInstanceName string

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/fileServices?pivots=deployment-language-bicep#corsrules')
param corsRules array = []

@description('https://learn.microsoft.com/en-us/azure/templates/microsoft.storage/storageaccounts/fileservices?pivots=deployment-language-bicep#fileservicepropertiesproperties')
var properties = empty(corsRules) ? {} : {
  cors: {
    corsRules: corsRules
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' existing = {
  name: storageAccountInstanceName
  
  resource fileServices 'fileServices' = {
    name: 'default'
    properties: properties

    resource storageAccountFileShares 'shares' = [for item in fileshares: {
      name: item
      properties: {}
    }]
  }
}

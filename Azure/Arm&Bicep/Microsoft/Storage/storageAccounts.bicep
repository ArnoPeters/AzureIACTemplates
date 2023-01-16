@description('Specifies the location for resources.')
param location string 

@description('Must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.')
@minLength(3)
@maxLength(24)
param instanceName string

resource MyComponentIdentifierName 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: instanceName
  location: location
  // tags: {
  //   tagName1: 'tagValue1'
  //   tagName2: 'tagValue2'
  // }
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
}

output MyOutputName string = MyComponentIdentifierName.name

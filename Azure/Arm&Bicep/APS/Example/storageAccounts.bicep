@description('Specifies the location for resources.')
param location string 

@description('Must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.')
@minLength(3)
@maxLength(24)
param instanceName string

module MyComponentIdentifierName './../../Microsoft/Storage/storageAccounts.bicep' = {
  name: 'StorageAccountDeployment'
  params: {
    location: location
    instanceName: instanceName
  }
}

output MyOutputName2 string = MyComponentIdentifierName.name

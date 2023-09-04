@description('Instance name of the app that is exposing an API')
param appName string

@description('Resourcegroup name of the app that is exposing an API')
param appResourceGroupName string

@description('Display name of the service in the APIM portal')
param serviceDisplayName string

@description('Identifier for the environment where the application will be deployed.')
@allowed([
  'd'
  'a'
  'p'
  'e'
])
param environment string

@description('Base name (without prefix or suffix) of the service to which this resource belongs.')
param serviceName string

@description('API URL suffix. Leave blank if APIM is not used.')
param apimSuffix string

resource instance 'Microsoft.Web/sites@2022-09-01' existing = {
  name: appName
  scope: resourceGroup(appResourceGroupName)
}

resource apim 'Microsoft.ApiManagement/service@2022-08-01' existing = {
  name: 'aps-${environment}-apim'

  resource backends 'backends' = {
    name: instance.name
    properties: {
      title: instance.name
      url: 'https://${instance.properties.defaultHostName}'
      resourceId: '${az.environment().resourceManager}/${instance.id}'
      protocol: 'http'
      tls: {
        validateCertificateChain: true
        validateCertificateName: true
      }
    }
  }

  resource apimTags 'tags' = {
    name: toLower(serviceName)
    properties: {
      displayName: serviceDisplayName
    }
  }

  resource versionSets 'apiVersionSets' = {
    name: '${instance.name}versionset'
    properties: {
      description: 'The API versionset'
      displayName: instance.name
      versioningScheme: 'Header'
      versionHeaderName: 'Api-Version'
    }
  }

  resource apis 'apis' = {
    name: instance.name
    properties: {
      displayName: instance.name
      apiRevision: '1'
      subscriptionRequired: true
      path: apimSuffix
      protocols: [
        'https'
      ]
      isCurrent: true
      apiVersionSetId: versionSets.id
    }

    resource apiTags 'tags' = {
      name: toLower(serviceName)
    }
  }
}

output api_id string = apim::apis.id

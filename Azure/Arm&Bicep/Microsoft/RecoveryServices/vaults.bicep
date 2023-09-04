// ---- Standard parameters

@description('Location for the resources in this module.')
param location string

@description('Use \'outputs.tags\' from the \'resourceGroup\' module.')
param tags object

@description('Optional. Is displayed next to the resource name in Azure. Makes uses of the undocumented \'hidden-title\' tag.')
param displayName string = ''

@description('Use \'outputs.instanceNameFormat\' from the \'resourceGroup\' module.')
param instanceNameFormat string

// ---- Template specific parameters

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'rsv') //TODO: Set resource type shortcode

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource instance 'Microsoft.RecoveryServices/vaults@2023-02-01' = {
  name: instanceName
  location: location
  tags: fullTags
  properties: {
    securitySettings: {}
    publicNetworkAccess: 'Enabled'
    restoreSettings: {
      crossSubscriptionRestoreSettings: {
        crossSubscriptionRestoreState: 'Enabled'
      }
    }
  }

  //TODO: Only add custom policies, skip the azure defaults. Enhanced policy throws errors. 

  resource defaultAlertSetting 'replicationAlertSettings@2023-02-01' = {
    name: 'defaultAlertSetting'
    properties: {
      sendToOwners: 'DoNotSend'
      customEmailAddresses: []
    }
  }
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

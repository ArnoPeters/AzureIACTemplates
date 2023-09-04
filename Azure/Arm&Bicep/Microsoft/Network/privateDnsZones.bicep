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

param virtualNetworkName string

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'pdnsz')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' existing = {
	name: virtualNetworkName
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
	name: instanceName
	location: location
	tags: fullTags
	properties: {}

	resource virtualNetworkLinks 'virtualNetworkLinks' = {
		name: uniqueString(virtualNetwork.id)
		location: location
		properties: {
			virtualNetwork: {
				id: virtualNetwork.id
			}
			registrationEnabled: false
		}
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

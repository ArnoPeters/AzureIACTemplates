// ---- Standard parameters

@description('Location for the resources in this module.')
param location string

@description('Use \'outputs.tags\' from the \'resourceGroup\' module.')
param tags object

@description('Optional. Is displayed next to the resource name in Azure. Makes uses of the undocumented \'hidden-title\' tag.')
param displayName string = ''

@description('Use \'outputs.formats.instanceName\' from the \'resourceGroup\' module.')
param instanceNameFormat string

// ---- Template specific parameters

param addressPrefixes array
param subnets array

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'vnet')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-04-01' = {
	name: instanceName
	tags: fullTags
	location: location
	properties: {
		addressSpace: {
			addressPrefixes: addressPrefixes
		}
		subnets: subnets
		virtualNetworkPeerings: []
		enableDdosProtection: false
		enableVmProtection: false
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

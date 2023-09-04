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

@allowed([
	'IPv4'
	'IPv6'
])
param ipVersion string
param publicIPPrefixLength int = 28

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'ippre')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource publicIPPrefixes 'Microsoft.Network/publicIPPrefixes@2023-04-01' = {
	name: instanceName
	location: location
	tags: fullTags
	properties: {
		prefixLength: publicIPPrefixLength
		publicIPAddressVersion: ipVersion
		ipTags: []
	}
	sku: {
		name: 'Standard'
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

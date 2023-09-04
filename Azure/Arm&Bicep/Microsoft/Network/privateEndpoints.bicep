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

param vnetName string
param vnetResourceGroup string
param privateLinkServiceId string
param targetSubResource array
param subnetName string
param privateDnsZoneName string

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'pep')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource vnet 'Microsoft.Network/virtualNetworks@2023-04-01' existing = {
	scope: resourceGroup(vnetResourceGroup)
	name: vnetName
	resource subnet 'subnets' existing = {
		name: subnetName
	}
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
	name: privateDnsZoneName
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-04-01' = {
	name: instanceName
	location: location
	tags: fullTags
	properties: {
		subnet: {
			id: vnet::subnet.id
		}
		privateLinkServiceConnections: [
			{
				name: instanceName
				properties: {
					privateLinkServiceId: privateLinkServiceId
					groupIds: targetSubResource
				}
			}
		]
	}

	resource privateEndpointName_default 'privateDnsZoneGroups@2023-04-01' = {
		name: 'default'
		properties: {
			privateDnsZoneConfigs: [
				{
					name: replace(privateDnsZone.name, '.', '-')
					properties: {
						privateDnsZoneId: privateDnsZone.id
					}
				}
			]
		}
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

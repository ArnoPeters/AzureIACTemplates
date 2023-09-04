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

param nextHopIpAddress string

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'rt')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource RouteTable_resource 'Microsoft.Network/routeTables@2023-04-01' = {
	name: instanceName
	tags: fullTags
	location: location
	properties: {
		disableBgpRoutePropagation: true
		routes: [
			{
				name: 'route01'
				properties: {
					addressPrefix: '0.0.0.0/0'
					nextHopType: 'VirtualAppliance'
					nextHopIpAddress: nextHopIpAddress
				}
			}
		]
	}

	resource RouteTable_route01 'routes' = {
		name: 'route01'
		properties: {
			addressPrefix: '0.0.0.0/0'
			nextHopType: 'VirtualAppliance'
			nextHopIpAddress: nextHopIpAddress
		}
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

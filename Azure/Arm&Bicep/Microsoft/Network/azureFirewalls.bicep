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

@description('The name of the firewall SKU.')
@allowed([
	'AZFW_Hub'
	'AZFW_Vnet'
])
param firewallSkuName string
@allowed([
	'Premium'
	'Standard'
])
@description('The tier of the firewall SKU.')
param firewallSkuTier string

@description('The IP configurations of the firewall.')
param ipConfigurations array

@description('The nat rules collection of the firewall.')
param natRuleCollections array

param networkRuleCollections array
param applicationRuleCollections array

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'afw')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource firewall 'Microsoft.Network/azureFirewalls@2020-05-01' = {
	name: instanceName
	tags: fullTags
	location: location
	properties: {
		sku: {
			name: firewallSkuName
			tier: firewallSkuTier
		}
		threatIntelMode: 'Deny'
		additionalProperties: {
			'Network.DNS.EnableProxy': 'true'
		}
		ipConfigurations: ipConfigurations
		networkRuleCollections: networkRuleCollections
		applicationRuleCollections: applicationRuleCollections
		natRuleCollections: natRuleCollections
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

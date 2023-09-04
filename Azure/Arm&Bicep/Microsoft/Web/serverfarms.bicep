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

@description('Possible SKU types')
@allowed([
	'Y1'
	'F1'
	'B1'
	'B2'
	'B3'
	'S1'
	'S2'
	'S3'
	'P1v2'
	'P1v3'
	'P2v2'
	'P2v3'
	'P3v2'
	'P3v3'
	'EP1'
	'EP2'
	'EP3'
])
param skuName string

@description('Number of instances assigned to the resource. Defaults to 1')
param skuCapacity int = 1

@description('Host type for the app service plan.')
@allowed([
	'app'
	'linux'
])
param kind string = 'app'

@description('Name of the log analytics workspace for the app service plan diagnostics')
param lawInstanceName string
param lawInstanceResourceGroup string

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'asp')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

var skus = {
	Y1: {
		name: 'Y1'
		tier: 'Dynamic'
		family: 'Y1'
		size: 'Y'
	}
	F1: {
		name: 'F1'
		tier: 'Free'
		size: 'F1'
		family: 'F'
		capacity: skuCapacity
	}
	B1: {
		name: 'B1'
		tier: 'Basic'
		size: 'B1'
		family: 'B'
		capacity: skuCapacity
	}
	B2: {
		name: 'B2'
		tier: 'Basic'
		size: 'B2'
		family: 'B'
		capacity: skuCapacity
	}
	B3: {
		name: 'B3'
		tier: 'Basic'
		size: 'B3'
		family: 'B'
		capacity: skuCapacity
	}
	S1: {
		name: 'S1'
		tier: 'Standard'
		size: 'S1'
		family: 'S'
		capacity: skuCapacity
	}
	S2: {
		name: 'S2'
		tier: 'Standard'
		size: 'S2'
		family: 'S'
		capacity: skuCapacity
	}
	S3: {
		name: 'S3'
		tier: 'Standard'
		size: 'S3'
		family: 'S'
		capacity: skuCapacity
	}
	P1v2: {
		name: 'P1v2'
		tier: 'PremiumV2'
		size: 'P1v2'
		family: 'Pv2'
		capacity: skuCapacity
	}
	P1v3: {
		name: 'P1v3'
		tier: 'PremiumV3'
		size: 'P1v3'
		family: 'Pv3'
		capacity: skuCapacity
	}
	P2v2: {
		name: 'P2v2'
		tier: 'PremiumV2'
		size: 'P2v2'
		family: 'Pv2'
		capacity: skuCapacity
	}
	P2v3: {
		name: 'P2v3'
		tier: 'PremiumV3'
		size: 'P2v3'
		family: 'Pv3'
		capacity: skuCapacity
	}
	P3v2: {
		name: 'P3v2'
		tier: 'PremiumV2'
		size: 'P3v2'
		family: 'Pv2'
		capacity: skuCapacity
	}
	P3v3: {
		name: 'P3v3'
		tier: 'PremiumV3'
		size: 'P3v3'
		family: 'Pv3'
		capacity: skuCapacity
	}
	EP1: {
		name: 'EP1'
		tier: 'ElasticPremium'
		size: 'EP1'
		family: 'EP'
		capacity: skuCapacity
	}
	EP2: {
		name: 'EP2'
		tier: 'ElasticPremium'
		size: 'EP2'
		family: 'EP'
		capacity: skuCapacity
	}
	EP3: {
		name: 'EP3'
		tier: 'ElasticPremium'
		size: 'EP3'
		family: 'EP'
		capacity: skuCapacity
	}
}

resource appServicePlan_instance 'Microsoft.Web/serverfarms@2022-09-01' = {
	name: instanceName
	location: location
	kind: kind
	sku: skus[skuName]
	tags: fullTags
	properties: {
		reserved: (kind == 'linux')
	}
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
	name: lawInstanceName
	scope: resourceGroup(lawInstanceResourceGroup)
}

//Use the json view in the portal when adding diagnostic settings to see what can be added and the correct json
//Or when configured export the existing resource .properties.logs output
resource logAnalyticsConfig 'Microsoft.Insights/diagnosticSettings@2021-05-01-preview' = {
	name: 'LogAnalytics'
	scope: appServicePlan_instance
	properties: {
		workspaceId: logAnalyticsWorkspace.id
		logs: []
		metrics: [
			{
				timeGrain: null
				enabled: true
				retentionPolicy: {
					days: 0
					enabled: false
				}
				category: 'AllMetrics'
			}
		]
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

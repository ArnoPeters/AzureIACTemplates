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

param serverInstanceName string

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'sqldb')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource servers 'Microsoft.Sql/servers@2022-11-01-preview' existing = {
	name: serverInstanceName

	resource databases 'databases' = {
		name: instanceName
		tags: fullTags
		location: location
		sku: {
			name: 'GP_S_Gen5'
			tier: 'GeneralPurpose'
			family: 'Gen5'
			capacity: 1
		}
		properties: {
			collation: 'SQL_Latin1_General_CP1_CI_AS'
			maxSizeBytes: 34359738368
			catalogCollation: 'SQL_Latin1_General_CP1_CI_AS'
			zoneRedundant: false
			readScale: 'Disabled'
			autoPauseDelay: 60
			requestedBackupStorageRedundancy: 'Local'
			minCapacity: json('0.5')
			maintenanceConfigurationId: subscriptionResourceId('Microsoft.Maintenance/publicMaintenanceConfigurations', 'SQL_Default')
			//'/subscriptions/2b240afd-7250-4208-847c-def07038c95a/providers/Microsoft.Maintenance/publicMaintenanceConfigurations/SQL_Default'
			isLedgerOn: false
			availabilityZone: 'NoPreference'
		}
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

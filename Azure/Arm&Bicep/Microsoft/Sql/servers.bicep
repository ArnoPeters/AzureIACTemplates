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

@secure()
param Admin_AADGroupName string

@secure()
param Admin_AADGroupSid string 

// ---- Deployment

@description ('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'sql') 

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

resource server 'Microsoft.Sql/servers@2022-11-01-preview' = {
	name: instanceName
	location: location
	tags: fullTags
	properties: {
		//administratorLogin: 'CloudSArandomstring' // Will be randomly generated anyway
		version: '12.0'
		minimalTlsVersion: '1.2'
		publicNetworkAccess:'Enabled' //  'Disabled'
		administrators: {
			administratorType: 'ActiveDirectory'
			principalType: 'Group'
			login: 'AAD_GROUP_${Admin_AADGroupName}' //TODO: does this need to be same as actual group name or is it ok to pre- / suffix the login
			sid: Admin_AADGroupSid
			tenantId: subscription().tenantId
			azureADOnlyAuthentication: true
		}
		restrictOutboundNetworkAccess: 'Disabled'
	}

	// resource azureADOnlyAuthentications 'azureADOnlyAuthentications' = {
	// 	name: 'Default'
	// 	properties: {
	// 		azureADOnlyAuthentication: true
	// 	}
	// }

	// resource symbolicname 'azureADOnlyAuthentications' = {
	// 	name: 'Default'
	// 	properties: {
	// 	  azureADOnlyAuthentication: true
	// 	}
	//  }

	// resource administrators 'administrators' = {
	// 	name: 'ActiveDirectory'
	// 	properties: {
	// 		administratorType: 'ActiveDirectory'
	// 		login: 'arnopeters_hotmail.com#EXT#@arnopetershotmail.onmicrosoft.com' //user principal name
	// 		sid: '8cc85493-5886-4ade-ae84-84d617066ee7'  // object ID
	// 		tenantId: 'ca3dc589-0f74-42a1-9e98-97aa9cf38e19' // TenantID obviously
	// 	}
	// }

	// resource advancedThreatProtectionSettings 'advancedThreatProtectionSettings' = {
	// 	name: 'Default'
	// 	properties: {
	// 		state: 'Disabled'
	// 	}
	// }

	// resource auditingSettings 'auditingSettings' = {
	// 	name: 'default'
	// 	properties: {
	// 		retentionDays: 0
	// 		auditActionsAndGroups: []
	// 		isStorageSecondaryKeyInUse: false
	// 		isAzureMonitorTargetEnabled: false
	// 		isManagedIdentityInUse: false
	// 		state: 'Disabled'
	// 		storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
	// 	}
	// }

	// resource connectionPolicies 'connectionPolicies' = {
	// 	name: 'default'
	// 	properties: {
	// 		connectionType: 'Default'
	// 	}
	// }

	// resource devOpsAuditingSettings 'devOpsAuditingSettings' = {
	// 	name: 'Default'
	// 	properties: {
	// 		isAzureMonitorTargetEnabled: false
	// 		isManagedIdentityInUse: false
	// 		state: 'Disabled'
	// 		storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
	// 	}
	// }

	// resource encryptionProtector 'encryptionProtector' = {
	// 	name: 'current'
	// 	properties: {
	// 		serverKeyName: 'ServiceManaged'
	// 		serverKeyType: 'ServiceManaged'
	// 		autoRotationEnabled: false
	// 	}
	// }

	// resource extendedAuditingSettings 'extendedAuditingSettings' = {
	// 	name: 'default'
	// 	properties: {
	// 		retentionDays: 0
	// 		auditActionsAndGroups: []
	// 		isStorageSecondaryKeyInUse: false
	// 		isAzureMonitorTargetEnabled: false
	// 		isManagedIdentityInUse: false
	// 		state: 'Disabled'
	// 		storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
	// 	}
	// }

	// resource keys 'keys' = {
	// 	name: 'ServiceManaged'
	// 	properties: {
	// 		serverKeyType: 'ServiceManaged'
	// 	}
	// }

	// resource securityAlertPolicies 'securityAlertPolicies' = {
	// 	name: 'Default'
	// 	properties: {
	// 		state: 'Disabled'
	// 		disabledAlerts: [
	// 			''
	// 		]
	// 		emailAddresses: [
	// 			''
	// 		]
	// 		emailAccountAdmins: false
	// 		retentionDays: 0
	// 	}
	// }

	// resource sqlVulnerabilityAssessments 'sqlVulnerabilityAssessments' = {
	// 	name: 'Default'
	// 	properties: {
	// 		state: 'Disabled'
	// 	}
	// }
}

//TODO CHECK THIS OUT

// @secure()
// param vulnerabilityAssessments_Default_storageContainerPath string

// resource Microsoft_Sql_servers_vulnerabilityAssessments_servers_aps_d_sqlsrv_name_Default 'Microsoft.Sql/servers/vulnerabilityAssessments@2022-11-01-preview' = {
// 	parent: server
// 	name: 'Default'
// 	properties: {
// 		recurringScans: {
// 			isEnabled: false
// 			emailSubscriptionAdmins: true
// 		}
// 		storageContainerPath: vulnerabilityAssessments_Default_storageContainerPath
// 	}
// }

// resource Microsoft_Sql_servers_auditingPolicies_servers_aps_d_sqlsrv_name_Default 'Microsoft.Sql/servers/auditingPolicies@2014-04-01' = {
// 	parent: server
// 	name: 'Default'
// 	properties: {
// 		auditingState: 'Disabled'
// 	}
// }

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs


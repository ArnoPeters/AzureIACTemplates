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

@description('Should the keyvault be created (=\'default\') or \'recovered\'')
@allowed([
	'default'
	'recover'
])
param createMode string

@description('SKU for the vault')
@allowed([
	'standard'
	'premium'
])
param vaultSku string = 'standard'

@description('Specifies if the vault is enabled for VM or Service Fabric deployment')
param enabledForDeployment bool = false

@description('Specifies if the vault is enabled for ARM template deployment')
param enabledForTemplateDeployment bool = false

@description('Specifies if the vault is enabled for volume encryption')
param enabledForDiskEncryption bool = false

@description('Requires an object [{ "objectId": "[your-identity.principalId]", "permissions": { "keys": [], "secrets": [ "Get" ], "certificates": [ ] } }]')
param accessPolicies array

// ---- Deployment

@description('https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/ready/azure-best-practices/resource-abbreviations')
var instanceName = format(instanceNameFormat, 'kv')

var fullTags = empty(displayName) ? tags : union(tags, { 'hidden-title': displayName })

//Ensure the correct tentant is always added to every access policy
var fixedAccessPolicies = [for item in accessPolicies: {
	tenantId: tenant().tenantId
	objectId: item.objectId
	permissions: item.permissions
}]

resource instance 'Microsoft.KeyVault/vaults@2023-02-01' = {
	name: instanceName
	location: location
	tags: fullTags
	properties: {
		createMode: createMode
		enabledForDeployment: enabledForDeployment
		enabledForTemplateDeployment: enabledForTemplateDeployment
		enabledForDiskEncryption: enabledForDiskEncryption
		enableSoftDelete: true
		softDeleteRetentionInDays: 90
		tenantId: subscription().tenantId
		sku: {
			name: vaultSku
			family: 'A'
		}
		accessPolicies: fixedAccessPolicies //not required in recovery mode, but this is cleaner.
	}
}

// ---- Standard outputs 

@description('Full instance name of the resource.')
output instanceName string = instanceName

// ---- Template specific outputs

var FullVaultUrl = 'https://${instanceName}${az.environment().suffixes.keyvaultDns}'
var referenceUrlFormat = '${FullVaultUrl}/secrets/{0}/'

@description('The URI root of the shared Keyvault')
output vaultUrl string = FullVaultUrl

@description('use format(resourceName.outputs.configurationStoreReferenceFormat, \'your_secret_name\') to construct a correct keyvault reference string.')
output configurationStoreReferenceFormat string = referenceUrlFormat

output configurationStoreReferenceContentType string = 'application/vnd.microsoft.appconfig.keyvaultref+json;charset=utf-8'

@description('use format(resourceName.outputs.keyVaultReferenceFormat, \'your_secret_name\') to construct a correct keyvault reference string.')
output appSettingsReferenceFormat string = '@Microsoft.KeyVault(SecretUri=${referenceUrlFormat})'

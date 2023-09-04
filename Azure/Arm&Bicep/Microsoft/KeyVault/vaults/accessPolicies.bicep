@description('Keyvault instance name')
param keyVaultInstanceName string

@allowed(
	[
		'add'
		'remove'
		'replace'
	]
)
param deploymentMode string = 'add'

@description('Requires an object [{ "objectId": "[your-identity.principalId]", "permissions": { "keys": [], "secrets": [ "Get" ], "certificates": [ ] } }]')
param accessPolicies array 

@description('Ensure that all policies have the correct tenant. Upload will fail otherwise.')
var fixedAccessPolicies = [for item in accessPolicies: {
	tenantId: tenant().tenantId
	objectId: item.objectId
	permissions: item.permissions
}]

resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
	name: keyVaultInstanceName

	resource accessPolicies 'accessPolicies' = {
		name: deploymentMode
		properties: {
			accessPolicies: fixedAccessPolicies
		}
	}
}

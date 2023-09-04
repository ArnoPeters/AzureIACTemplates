@description('Specifies the name of the key vault.')
param keyVaultInstanceName string

@description('An array of strings with names of secrets that already exist in the keyvault, and should NOT be overwritten.')
param existingSecretNames array = []

@description('Requires an object [{ "name": "your_secret_name", "value": "your_secret_value", "enabled": true (or false) }]')
param secrets array = []

var nonExistingSecrets = [for item in secrets: (contains(existingSecretNames, item.name) ? null : item)]

@description('Smart merge to only add new secrets with empty values, filtering out the nulls')
var newSecretsToDeploy = intersection(secrets, nonExistingSecrets)

resource kv 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
	name: keyVaultInstanceName

	resource keyVaultInstanceName_newSecretsToDeploy_name 'secrets' = [for item in newSecretsToDeploy: {
		name: item.name
		properties: {
			value: item.value
			attributes: {
				enabled: item.enabled
			}
		}
	}]
}

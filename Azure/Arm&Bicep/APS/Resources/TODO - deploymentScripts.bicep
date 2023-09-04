//Deployment scripts
//https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep
//https://learn.microsoft.com/en-us/azure/templates/microsoft.resources/deploymentscripts?pivots=deployment-language-bicep

//create install script - user assigned identity - with the right roles and permissions
//https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/deployment-script-bicep#configure-the-minimum-permissions

//Create AAD group for SQL with admin role.

resource runPowerShellInline 'Microsoft.Resources/deploymentScripts@2020-10-01' = {
	name: 'runPowerShellInline'
	location: location
	kind: 'AzureCLI'
	tags: {
		tagName1: 'tagValue1'
		tagName2: 'tagValue2'
	}
	identity: {
		type: 'UserAssigned'
		userAssignedIdentities: {
			'/subscriptions/01234567-89AB-CDEF-0123-456789ABCDEF/resourceGroups/myResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/myID': {}
		}
	}
	properties: {
		forceUpdateTag: '1'
		containerSettings: {
			containerGroupName: 'mycustomaci'
		}
		storageAccountSettings: {
			storageAccountName: 'myStorageAccount'
			storageAccountKey: 'myKey'
		}
		//azPowerShellVersion: '9.7' // or azCliVersion: '2.47.0'
		azCliVersion: '2.47.0'
		arguments: '-name \\"John Dole\\"'
		environmentVariables: [
			{
				name: 'UserName'
				value: 'jdole'
			}
			{
				name: 'Password'
				secureValue: 'jDolePassword'
			}
		]
		scriptContent: '''
		 param([string] $name)
		 $output = \'Hello {0}. The username is {1}, the password is {2}.\' -f $name,\${Env:UserName},\${Env:Password}
		 Write-Output $output
		 $DeploymentScriptOutputs = @{}
		 $DeploymentScriptOutputs[\'text\'] = $output
	  '''// or primaryScriptUri: 'https://raw.githubusercontent.com/Azure/azure-docs-bicep-samples/main/samples/deployment-script/inlineScript.ps1'
		supportingScriptUris: []
		timeout: 'PT30M'
		cleanupPreference: 'OnSuccess'
		retentionInterval: 'P1D'
	}
}

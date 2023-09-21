/*
   Creates a shared keyvault for use during deployments. 
*/

targetScope = 'subscription'

// ---- Standard parameters

@description('Date in simple variant on ISO 8601. Required to create unique names for linked template deployments, to prevent Azure from overwriting the history of those deployments. Always leave this one to its default!')
param deploymentDateTimeStamp string = utcNow('yyyyMMdd-HHmm')

@description('Specifies the location for the resources.')
param location string

@description('Optional. Any tags that should be added to this resource.')
param tags object = {}

@description('Short code (1 to 5 chars) to be used as prefix for resources to identify the owner.')
param ownerPrefix string

@secure()
param ownerContactEmail string

// ---- Template specific parameters

param keyVaultAccessPolicies array
//param keyvaultSecretsPlaceholders array

// ---- Deployment

@description('This var is used deliberately: it is not possible to set a SCOPE on resources that will be deployed using output variables. The value is required to be known beforehand.')
var resourceGroupNames = {
  keyVault: '${ownerPrefix}-deployment-rg'
}

module keyVaultRG '../../Azure/Arm&Bicep/APS/Resources/resourceGroups.bicep' = {
//module keyVaultRG 'ts/SharedTemplates:APS.Resources.resourceGroups:0.1.6-Temp-CVGenerator' = {
  //module keyVaultRG 'APS/Resources/resourceGroups.bicep' = {
  name: '${deploymentDateTimeStamp}-keyVaultRG'
  params: {
    location: location
    resourceGroupName: resourceGroupNames.keyVault
    context: {
      environment: ''
      namingPrefix: ownerPrefix
      partOf: 'deployment'
    }
    tags: tags
    ownerContactEmail: ownerContactEmail
  }
}

module keyVault '../../Azure/Arm&Bicep/Microsoft/KeyVault/vaults.bicep' = {
//module keyVault 'ts/SharedTemplates:Microsoft.KeyVault.vaults:0.1.6-Temp-CVGenerator' = {
  //module keyVault 'Microsoft/KeyVault/vaults.bicep' = {
  scope: resourceGroup(resourceGroupNames.keyVault)
  name: '${deploymentDateTimeStamp}-keyVault'
  params: {
    location: location
    tags: keyVaultRG.outputs.resourceTags
    displayName: 'Secrets for deployment'
    createMode: 'default'
    instanceNameFormat: keyVaultRG.outputs.formats.instanceName
    enabledFor: {
      templateDeployment: true
    }
    accessPolicies: keyVaultAccessPolicies
  }
}

//Disabled: 
//This will bork by overwriting any and all secrets unless existingSecretNames are provided to determine what to skip. ARM/Bicep does not support getting existing secrets. A deploymentscript is an option but requires additional settings for the agent.

//module keyVaultSecrets 'ts/SharedTemplates:Microsoft.KeyVault.vaults:0.1.6-Temp-CVGenerator' = {
module keyVaultSecrets '../../Azure/Arm&Bicep/Microsoft/KeyVault/vaults/secrets.bicep' = {
  scope: resourceGroup(resourceGroupNames.keyVault)
  name: take('${deploymentDateTimeStamp}-keyVaultSecrets', 64)
  params: {
    keyVaultInstanceName: keyVault.outputs.instanceName
    secrets: [ {
        name: 'ownerContactEmail' //subteams can create secrets like 'teamNameContactEmail' in the same keyvault.
        value: ownerContactEmail  
        enabled: true
      }
      {
        name: 'ownerPrefix' //subteams can create secrets like 'teamNamePrefix' in the same keyvault.
        value: ownerPrefix   
        enabled: true
      } ]
  }
}

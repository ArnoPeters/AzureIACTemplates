targetScope = 'subscription'

// The code below is based on the code found in Barbara Forbes's blog: 
// https://4bes.nl/2022/01/16/build-and-test-an-azure-tagging-strategy-in-bicep/
// https://4bes.nl/2021/10/10/get-a-consistent-azure-naming-convention-with-bicep-modules/
// 
//
// The most interesting issue that Barbara  addresses is that you cannot create resources directly with the naming format from an output: 
// Bicep requires names to be known on compile time, not runtime. This is also true for any Scope set on a resource. 
// Therefore resource groups are treated specially and no naming output is generated because it would currently not be properly usable. 
// Any other resources should be created in modules which do allow using parameters for passing of instance names based on the output of this template.

@description('Di not override - auto generates a date stamp for the tags. ')
param deploymentDate string = utcNow('yyyy-MM-dd')

@secure()
@description('The contact email of the group or person that is responsible for the created resource instances.')
param ownerContactEmail string

@minLength(0)
@maxLength(5)
@description('Short code (1 to 5 chars) to be used as prefix for resources to identify the owner.')
param ownerPrefix string

@allowed([
  ''
  'd'
  'a'
  'p'
])
@description('The environment that these resources are part of.')
param environment string

@description('Optional. Any extra tags that should be added to the resources.')
param additionalTags object

// @description('Optional. The costcenter for the resources.') //It is also suggested to use the subscription to seperate out the cost center as this makes setting budget tresholds easier.
// param costCenter string = ''

@description('Name to identify the shared purpose of the resources.')
param partOf string

@minLength(0)
@maxLength(5)
@description('Short code (1 to 5 chars) identify the shared purpose of the resources.')
param partOfAbbreviation string = ''

@description('An index number. This enables you to have some sort of versioning or to create redundancy')
param index int = 0

@description('Specifies the location for the resource group.')
param location string

@description('The name of the resource group. Determine this in the calling module because scope() attributes that would target the resource group won\'t work with outputs anyway.')
param resourceGroupName string

var indexSuffix = (index == 0 ? '' : '-${padLeft(index, 2, '0')}')

// First, we create shorter versions of the function and the owner. 
// This is used for resources with a limited length to the name.
// There is a risk to doing at this way, as results might be non-desirable.
// Can be overridden using the partOfAbbreviation parameter. 
var partOfShort = empty(partOfAbbreviation) ? take(partOf, 5) : partOf
var ownerPrefixShort = take(ownerPrefix, 5)
var environmentShortName = empty(environment) ? 'ANY' : (environment == 'd' ? 'DEV' : (environment == 'a' ? 'ACC' : 'PRD'))
var environmentInfix = empty(environment) ? '' : '-${environment}'

// var costCenterTagsObject = empty(costCenter)? {} : {
//   CostCenter: costCenter
// }

var baseTagsObject = {
  Owner: toLower(ownerContactEmail)
  Environment: environmentShortName
  DeploymentDate: deploymentDate
  PartOf: '${toUpper(take(partOf, 1))}${skip(partOf, 1)}' //auto-caps for first letter of PartOf
}

//var tagsObject = union(costCenterTagsObject, baseTagsObject)
var tagsObject = baseTagsObject

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  location: location
  tags: tagsObject
  name: resourceGroupName
}

// Outputs are created to give the results back to the main template

@description('3-letter shortcode for the environment')
output environmentShortName string = environmentShortName

@description('Descriptive name of the environment')
output environmentFullName string = empty(environment) ? 'Global' : (environment == 'd' ? 'Development' : (environment == 'a' ? 'Acceptance' : 'Production'))

@description('Use \'format(your_naming_resource.outputs.resourceNameFormat, \'resourcetype_shortcode\')\' to generate a resource name')
output instanceNameFormat string = '${ownerPrefix}${environmentInfix}-${partOf}-{0}${indexSuffix}'

@description('Max 17 char length, excluding the value for {0}. Use \'format(your_naming_resource.outputs.resourceNameShortFormat, \'resourcetype_shortcode\')\' to insert a resource name.')
output instanceNameShortFormat string = '${ownerPrefix}${environmentInfix}-${partOfShort}-{0}${indexSuffix}'

// Storage accounts have specific limitations. The correct convention is created here
@description('Max 17 char length of 24 allowed, leaving 7 for suffixing in consuming template. Any input values used will be enforced to use lower case.')
output storageAccountNameFormat string = '${toLower(ownerPrefix)}${toLower(environment)}${toLower(partOfShort)}sta${indexSuffix}'

// VM names create computer names. These can be a max of 15 characters. So a different structure is required
@description('Max 14 char length of 15 allowed, leaving 1 for suffixing in consuming template.')
output vmName string = take('${ownerPrefixShort}${environment}${partOfShort}${indexSuffix}', 15)

@description('Tags that should be applied to all resources that are PartOf the same purpose.')
output tags object = union(additionalTags, tagsObject) //by setting 'tags' first in the union, the other properties of the 'tagsobject' will not be overwritten

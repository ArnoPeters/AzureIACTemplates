targetScope = 'subscription'

// The code below is based on and inspired by the code found in Barbara Forbes's blog: 
// https://4bes.nl/2022/01/16/build-and-test-an-azure-tagging-strategy-in-bicep/
// https://4bes.nl/2021/10/10/get-a-consistent-azure-naming-convention-with-bicep-modules/
// 
//
// The most interesting issue that Barbara addresses is that you cannot create resources directly with the naming format from an output: 
// Bicep requires names to be known on compile time, not runtime. This is also true for any Scope set on a resource. 
// Therefore resource groups are treated specially and no naming output is generated because it would currently not be properly usable. 
// Any other resources should be created in modules which do allow using parameters for passing of instance names based on the output of this template.

@description('Do not override - auto generates a date stamp for the tags. ')
param deploymentDate string = utcNow('yyyy-MM-dd')

@description('Information to identify the owner of the resources.')
param owner {
  @secure()
  @description('The contact email of the group or person that is responsible for the created resource instances.')
  contactEmail: string

  @minLength(0)
  @maxLength(5)
  @description('Short code (1 to 5 chars) to be used as prefix for resources to identify the owner.')
  namingPrefix: string
}

type environmentString = '' | 'd' | 'a' | 'p'

@description('Information about the context of the resources.')
param context {
  @description('The environment that these resources are deployed to.')
  environment: environmentString
  
  @description('Name to identify the shared purpose of the resources.')
  partOf: string
  
  @minLength(0)
  @maxLength(5)
  @description('Short code (1 to 5 chars) identify the shared purpose of the resources. Takes the first 5 parts of \'partOf\' if omitted ')
  partOfAbbreviation: string?
  
  @description('Optional. The costcenter for the resources.') //It is also suggested to use the subscription to seperate out the cost center as this makes setting budget tresholds easier.
  costCenter: string?
}

@description('Optional. Any extra tags that should be added to the resources.')
param additionalTags object

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
var partOfShort = empty(context.partOfAbbreviation) ? take(context.partOf, 5) : context.partOf
var environmentInfix = empty(context.environment) ? '' : '-${context.environment}'

var formatInfo = {
  instanceName: '${owner.namingPrefix}${environmentInfix}-${context.partOf}-{0}${indexSuffix}'
  instanceNameShort: '${owner.namingPrefix}${environmentInfix}-${partOfShort}-{0}${indexSuffix}'
  // Storage accounts have specific limitations. The correct convention is created here
  storageAccountNameFormat: '${toLower(owner.namingPrefix)}${toLower(context.environment)}${toLower(partOfShort)}sta${indexSuffix}'
  // VM names create computer names. These can be a max of 15 characters. So a different structure is required
  vmName: take('${take(owner.namingPrefix, 3)}${context.environment}${partOfShort}${indexSuffix}', 15)
}

var environmentInfo = {
  shortName: empty(context.environment) ? 'ANY' : (context.environment == 'd' ? 'DEV' : (context.environment == 'a' ? 'ACC' : 'PRD'))
  fullName: empty(context.environment) ? 'Global' : (context.environment == 'd' ? 'Development' : (context.environment == 'a' ? 'Acceptance' : 'Production'))
}

var baseTagsObject = {
  Owner: toLower(owner.contactEmail)
  Environment: environmentInfo.shortName
  DeploymentDate: deploymentDate
  PartOf: '${toUpper(take(context.partOf, 1))}${skip(context.partOf, 1)}' //auto-caps for first letter of PartOf
}

var costCenterTagsObject = empty(context.costCenter) ? {} : {
  CostCenter: context.costCenter
}

var tagsObject = union(costCenterTagsObject, baseTagsObject)
//var tagsObject = baseTagsObject

resource resourceGroup 'Microsoft.Resources/resourceGroups@2020-10-01' = {
  location: location
  tags: tagsObject
  name: resourceGroupName
}

// Outputs are created to give the results back to the main template
@description('Formats to construct instance names. Can be suffixed with additional naming before passing on to a module: use (for example) \'\${your_naming_resource.outputs.formats.instanceName}-your_suffix\' as the instanceNameFormat property.')
output formats {
  @description('Use \'format(your_naming_resource.outputs.formats.instanceName, \'resourcetype_shortcode\')\' to generate a resource name')
  instanceName: string
  @description('Max 17 char length, excluding the value for {0}. Use \'format(your_naming_resource.outputs.formats.instanceNameShort, \'resourcetype_shortcode\')\' to insert a resource name.')
  instanceNameShort: string
  // Storage accounts have specific limitations. The correct convention is created here
  @description('Max 17 char length of 24 allowed, leaving 7 for suffixing in consuming template. Any input values used will be enforced to use lower case.')
  storageAccountNameFormat: string
  // VM names create computer names. These can be a max of 15 characters. So a different structure is required
  @description('Max 14 char length of 15 allowed, leaving 1 for suffixing in consuming template.')
  vmName: string
} = formatInfo

@description('Information on the environment')
output environment {
  @description('3-letter shortcode for the environment')
  shortName: string
  @description('Descriptive name of the environment')
  fullName: string
} = environmentInfo

@description('Tags that should be applied to all resources that are PartOf the same purpose, and any additional tags that were provided.')
output tags {
  Owner: string
  Environment: string
  DeploymentDate: string
  PartOf: string
  //*: string
  #disable-next-line outputs-should-not-contain-secrets //Email is not exactly a secret, but it may come from from keyvault and then @secure is mandatory
} = union(additionalTags, tagsObject) //by setting 'tags' first in the union, the other properties of the 'tagsobject' will not be overwritten

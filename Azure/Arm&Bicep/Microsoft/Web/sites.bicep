@description('Location for all resources.')
param location string = resourceGroup().location

@description('This is an internally used template, and should only be called by web-app.json of function-app.json Toggle to determine web- or functionapp.')
@allowed([
  'functionApp'
  'webApp'
])
param type string

@description('Full instance name of the User Assigned Identity including pre- and suffixes as provided by the outputs of app-identity.json')
param identityName string //TODO: If not user assigned, use system assigned

@description('Identifier for the environment where the application will be deployed.')
@allowed([
  'd'
  'a'
  'p'
  'e'
])
param environment string

@description('Name (without prefix or suffix) of the app service plan to run the app on.')
param aspName string

@description('Base name (without prefix or suffix) of the service to which this resource belongs.')
param serviceName string


@description('The instrumentation key from a Microsoft.Insights/components (application insights) resource.')
param appInsights_InstrumentationKey string

@description('requires an object { \'Name_of_your_connectionstring\' : { \'value\': \'Value_of_your_connectionstring\', \'type\': \'See the Settings -> Configuration -> Connection strings section in Azure for the supported types\' } }')
param connectionStrings object = {}

@description('Optional. Any tags that should be added to this resource.')
param tags object = {}

@description('This object can contain values like always on that is in the general settings for the webapp.')
param siteConfig object = {}

@description('requires an object { "value": { "Setting": "SettingValue" , "Setting2": "Setting2Value" } } that provides key-value pairs for the Settings -> Configuration -> Application Settings section in Azure.')
param appSettings object = {}

@description('API URL suffix. Leave blank if APIM is not used.')
param apimSuffix string = ''

@description('Set to \'true\' to enable logging to the File System of the app. See Azure -> app -> Monitoring -> App Service Logs')
param enableAppServiceLogs bool = true

@description('Required to create unique names and prevent Azure from overwriting the history of linked template deployments ')
param deploymentDateTimeStamp string

@description('The URI root of the shared Configuration as provided by the outputs of app-identity.json')
param appConfigUri string



@description('Flag if deployment slots are to be deployed and used. This will mean that slot settings are used instead of \'normal\' settings, and the slot needs to be swapped. Otherwise the deployed application will not work!')
param useDeploymentSlots bool

@description('Used for forward compatibility. Currently we will only use linux ASP\'s (and web apps), but this might change in the future.')
@allowed([
  'app'
  'linux'
])
param kind string = 'linux'

@description('The version of .NET to run. Currently defaults to .NET Core 3.1, .NET 6 is also supported')
@allowed([
  'Framework48'
  '3.1'
  '6.0'
])
param dotnetVersion string = '3.1'

@description('Configure the threshold (in minutes) until a failing instance is deemed unhealthy and removed from the load balancer. The number of pings and minutes is equal as Azure pings the healthcheck every minute.')
@minValue(2)
@maxValue(10)
param websiteHealthCheckMaxPingFailures int = 10
 
@description('Name of the resource')
param instanceName string

param stagingSlotName string = 'Staging'
var serviceDisplayName = '${toUpper(take(serviceName, 1))}${skip(serviceName, 1)}'


@description('Settings that go for all slots and both web- and functionapps, that will not overwrite any config for a RUNNING application')
var appSettingsDefaults_allslots = {
  ApplicationInsightsAgent_EXTENSION_VERSION: '~2'
}

@description('//Settings specific for functionapps, that should be applied to the slot where the application will be deployed.')
var appSettingsDefaults_functionApps = {
  FUNCTIONS_WORKER_RUNTIME: 'dotnet'
  FUNCTIONS_EXTENSION_VERSION: ((dotnetVersion == '3.1') ? '~3' : '~4')
  AzureWebJobsStorage: function_backingStorageAccount.outputs.connectionString
}
@description('Settings that are used for both web- and functionapps, that should be applied to the slot where the application will be deployed.')
var appSettingsDefaults_allApps = {
  AZURE_CLIENT_ID: userManagedIdentity.properties.clientId
  ASPNETCORE_ENVIRONMENT: ((environment == 'p') ? 'Production' : ((environment == 'a') ? 'Acceptance' : 'Development'))
  APPINSIGHTS_INSTRUMENTATIONKEY: appInsights_InstrumentationKey
  XDT_MicrosoftApplicationInsights_Mode: 'default'
  //AppConfig__Uri: appConfigUri  //TODO: is this universal or customer specific? 
  WEBSITES_ENABLE_APP_SERVICE_STORAGE: 'false'
  WEBSITE_HEALTHCHECK_MAXPINGFAILURES: websiteHealthCheckMaxPingFailures
  WEBSITE_TIME_ZONE: ((kind == 'linux') ? 'Europe/Amsterdam' : 'W. Europe Standard Time')
  WEBSITE_RUN_FROM_PACKAGE: '1'
}

@description('Appsettings for all app types and all slots')
var baseAppSettings = union(appSettingsDefaults_allApps, appSettingsDefaults_allslots, appSettings)

@description('Sum of the app settings for the deployment slot.')
var deploymentSlotAppSettings= (type == 'functionApp') ? union(baseAppSettings, appSettingsDefaults_functionApps) : baseAppSettings

@description('When using deployment slots, the production slot should NOT have settings overwritten or it will break the RUNNING application. Use a minimal set of appsettings.')
var productionSlotAppSettings = (useDeploymentSlots ? union(existing_appsettings, appSettingsDefaults_allslots) : deploymentSlotAppSettings)

var config_web = {
  base: {
    alwaysOn: true
    apiManagementConfig: (empty(apimSuffix) ? {} : {
      id: app_apim.outputs.api_id
    })
  }
  linux: {
    linuxFxVersion: '${((type == 'functionApp') ? 'DOTNET' : 'DOTNETCORE')}|${dotnetVersion}'
  }
  windows: {
    remoteDebuggingVersion: 'VS2019'
    use32BitWorkerProcess: false
  }
}

var config = {
  web: ((kind == 'linux') ? union(config_web.base, config_web.linux) : union(config_web.base, config_web.windows))
  logs: {
    httpLogs: {
      fileSystem: {
        retentionInMb: 35
        retentionInDays: 7
        enabled: enableAppServiceLogs
      }
    }
  }
}



var alltags = union({
    Service: serviceDisplayName
  }, tags)

var defaultSiteConfig = {
  metadata: [
    {
      name: 'CURRENT_STACK'
      value: ((dotnetVersion == 'Framework48') ? 'dotnet' : 'dotnetcore')
    }
  ]
  alwaysOn: true
  http20Enabled: true
  minTlsVersion: '1.2'
  ftpsState: 'Disabled'
  healthCheckPath: '/live'
  ipSecurityRestrictions: [
    {
      vnetSubnetResourceId: VNET::appgwHtmlSubnet.id
      action: 'Allow'
      tag: 'Default'
      priority: 400
      name: 'Allow Access through AppGW-HTML'
    }
    {
      vnetSubnetResourceId: VNET::apimSubnet.id
      action: 'Allow'
      tag: 'Default'
      priority: 500
      name: 'Allow Access through APIM'
    }
    {
      ipAddress: 'AzureEventGrid'
      action: 'Allow'
      tag: 'ServiceTag'
      priority: 600
      name: 'Eventgrid'
      description: 'Allow EventGrid for webhooks'
    }
    {
      ipAddress: 'Any'
      action: 'Deny'
      priority: 2147483647
      name: 'Deny all'
      description: 'Deny all access'
    }
  ]
  vnetRouteAllEnabled: true
}

var siteProperties = {
  serverFarmId: serverFarm.id
  siteConfig: union(defaultSiteConfig, siteConfig)
  httpsOnly: true
  clientAffinityEnabled: false
  keyVaultReferenceIdentity: userManagedIdentity.id
}

// ------------ Existing resources --------------

resource VNET 'Microsoft.Network/virtualNetworks@2022-11-01' existing = {
  name: 'aps-${environment}-vnet'
  scope: resourceGroup('aps-${environment}-rg-vn')
  resource appServicePlanSubnet 'subnets@2022-11-01' existing = {
    name: 'aps-${environment}-sub-${aspName}'
  }
  resource apimSubnet 'subnets@2022-11-01' existing = {
    name: 'aps-${environment}-sub-apim'
  }
  resource appgwHtmlSubnet 'subnets@2022-11-01' existing = {
    name: 'aps-${environment}-sub-AppgwHTML'
  }
}

resource serverFarm 'Microsoft.Web/serverfarms@2022-09-01' existing = {
  name: 'aps-${environment}-asp-${aspName}'
  scope: resourceGroup('aps-${environment}-rg-asp')
}

@description('existing user assigned managed identity')
resource userManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: identityName
}

module function_backingStorageAccount 'storageAccount.bicep' = if (type == 'functionApp') {
  name: take('${deploymentDateTimeStamp}-${instanceName}-Function-BackingStorageAccount', 64)
  params: {
    instanceName: uniqueString('${instanceName}-Function-BackingStorageAccount')
    tags: tags
    deploymentDateTimeStamp: deploymentDateTimeStamp
    location: location
  }
}

// --------------- 
// When using staging slots, do NOT reconfigure the production slot - there is an app running there. Use the existing settings to prevent breaking it. 
// Only setup the staging slot with brand new settings. 


@description('An object containing all the current appsettings.')
var existing_appsettings =  (useDeploymentSlots? list('${resourceId('Microsoft.Web/sites', instanceName)}/config/appsettings', '2020-06-01') : {})

// --------------- WebApp setup

resource app 'Microsoft.Web/sites@2022-09-01' = {
  name: instanceName
  kind: ((type == 'functionApp') ? 'functionapp,linux,container' : ((kind == 'linux') ? 'app,linux' : 'app'))
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${userManagedIdentity.id}': {}
    }
  }
  location: location
  tags: union(alltags, {
      'hidden-related:${serverFarm.id}': 'empty'
    })
  properties: siteProperties

  resource app_appsettings 'config@2022-09-01' = {
    name: 'appsettings'
    properties: productionSlotAppSettings
  }

  resource app_logs 'config@2022-09-01' = {
    name: 'logs'
    properties: config.logs
    dependsOn: [
      app_appsettings
    ]
  }

  resource app_web 'config@2022-09-01' = {
    name: 'web'
    properties: config.web
  }

  resource app_connectionstrings 'config@2022-09-01' = if ((!useDeploymentSlots) && (!empty(connectionStrings))) {
    name: 'connectionstrings'
    properties: connectionStrings
  }

  resource app_virtualNetwork 'networkConfig@2022-09-01' = {
    name: 'virtualNetwork'
    properties: {
      subnetResourceId: VNET::appServicePlanSubnet.id
      swiftSupported: true
    }
  }

  resource app_stagingSlot 'slots@2022-09-01' = if (useDeploymentSlots) {
    name: stagingSlotName
    identity: {
      type: 'UserAssigned'
      userAssignedIdentities: {
        '${userManagedIdentity.id}': {}
      }
    }
    kind: ((type == 'functionApp') ? 'functionapp,linux,container' : ((kind == 'linux') ? 'app,linux' : 'app'))
    location: location
    tags: alltags
    properties: siteProperties

    resource app_stagingSlotName_appsettings 'config@2022-09-01' = if (useDeploymentSlots) {
      name: 'appsettings'
      properties: deploymentSlotAppSettings
    }

    resource app_stagingSlotName_logs 'config@2022-09-01' = if (useDeploymentSlots) {
      name: 'logs'
      properties: config.logs
      dependsOn: [
        app_stagingSlotName_appsettings
      ]
    }

    resource app_stagingSlotName_web 'config@2022-09-01' = if (useDeploymentSlots) {
      name: 'web'
      properties: config.web
    }
    resource app_stagingSlotName_virtualNetwork 'networkConfig@2022-09-01' = if (useDeploymentSlots) {
      name: 'virtualNetwork'
      properties: {
        subnetResourceId: VNET::appServicePlanSubnet.id
        swiftSupported: true
      }
    }

    resource app_stagingSlotName_connectionstrings 'config@2022-09-01' = if (useDeploymentSlots) {
      name: 'connectionstrings'
      properties: connectionStrings
    }
  }
}

// --------------- Locks

resource app_lock 'Microsoft.Authorization/locks@2020-05-01' = if ((!empty(environment)) && (environment != 'd')) {
  name: instanceName
  scope: app
  properties: {
    level: 'CanNotDelete'
    notes: 'Site should not be deleted.'
  }
}

resource app_stagingSlotName_lock 'Microsoft.Authorization/locks@2020-05-01' = if (useDeploymentSlots && (!empty(environment)) && (environment != 'd')) {
  name: stagingSlotName
  scope: app::app_stagingSlot
  properties: {
    level: 'CanNotDelete'
    notes: 'Web App Slot should not be deleted.'
  }
}

// --------------- APIM backend setup

module app_apim '../ApiManagement/service_app.bicep' = if (!empty(apimSuffix)) {
  name: '${deploymentDateTimeStamp}-apim-${instanceName}'
  scope: resourceGroup(apimRG)
  params: {
    environment: environment
    appName: instanceName
    serviceDisplayName: serviceDisplayName
    serviceName: serviceName
    apimSuffix: apimSuffix
    appResourceGroupName: resourceGroup().name
  }
}

@description('Resource ID of the app.')
output appResourceId string = app.id
@description('Resource ID of the stating slot (if applicable).')
output appStagingSlotResourceId string = (useDeploymentSlots? app::app_stagingSlot.id : '')

@description('Root url of the app')
output rootUrl string = 'https://${app.properties.defaultHostName}'


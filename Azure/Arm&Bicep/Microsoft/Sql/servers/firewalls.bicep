@description('The SQL Server name.')
param serverInstanceName string

param ruleName string

param startIpAddress string

param endIpAddress string

resource server 'Microsoft.Sql/servers@2022-11-01-preview' existing = {
  name: serverInstanceName

  resource firewallRules 'firewallRules' = {
    name: ruleName
    properties: {
      startIpAddress: startIpAddress
      endIpAddress: endIpAddress
    }
  }
}

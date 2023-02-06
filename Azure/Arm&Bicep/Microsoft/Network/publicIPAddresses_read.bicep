@description('Name of the public IP resource')
param instanceName string = 'ar-d-fw-hybridautomation-pip'

output currentIpAddress string = reference(resourceId('Microsoft.Network/publicIPAddresses', instanceName), '2020-11-01', 'Full').properties.ipAddress

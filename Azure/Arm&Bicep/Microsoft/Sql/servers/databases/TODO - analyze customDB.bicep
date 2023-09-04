@description('Specifies the location for resources.')
param location string

param serverInstanceName string
param databaseInstanceName string

resource server 'Microsoft.Sql/servers@2022-11-01-preview' existing = {
	name: serverInstanceName

	resource database 'databases' = {
		name: databaseInstanceName
		location: location

		resource auditingPolicies 'auditingPolicies@2014-04-01' = {
			name: 'Default'
			properties: {
				auditingState: 'Disabled'
			}
		}

		resource auditingSettings 'auditingSettings' = {
			name: 'default'
			properties: {
				retentionDays: 0
				isAzureMonitorTargetEnabled: false
				state: 'Disabled'
				storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
			}
		}

		resource extendedAuditingSettings 'extendedAuditingSettings' = {
			name: 'default'
			properties: {
				retentionDays: 0
				isAzureMonitorTargetEnabled: false
				state: 'Disabled'
				storageAccountSubscriptionId: '00000000-0000-0000-0000-000000000000'
			}
		}

		resource backupLongTermRetentionPolicies 'backupLongTermRetentionPolicies' = {
			name: 'default'
			properties: {
				weeklyRetention: 'PT0S'
				monthlyRetention: 'PT0S'
				yearlyRetention: 'PT0S'
				weekOfYear: 0
			}
		}

		resource backupShortTermRetentionPolicies 'backupShortTermRetentionPolicies' = {
			name: 'default'
			properties: {
				retentionDays: 7
				diffBackupIntervalInHours: 12
			}
		}

		resource geoBackupPolicies 'geoBackupPolicies' = {
			name: 'Default'
			properties: {
				state: 'Disabled'
			}
		}

		resource advancedThreatProtectionSettings 'advancedThreatProtectionSettings' = {
			name: 'Default'
			properties: {
				state: 'Disabled'
			}
		}

		resource ledgerDigestUploads 'ledgerDigestUploads' = {
			name: 'Current'
			properties: {}
		}

		resource securityAlertPolicies 'securityAlertPolicies' = {
			name: 'Default'
			properties: {
				state: 'Disabled'
				disabledAlerts: [
					''
				]
				emailAddresses: [
					''
				]
				emailAccountAdmins: false
				retentionDays: 0
			}
		}

		resource transparentDataEncryption 'transparentDataEncryption' = {
			name: 'Current'
			properties: {
				state: 'Enabled'
			}
		}

		resource vulnerabilityAssessments 'vulnerabilityAssessments' = {
			name: 'Default'
			properties: {
				recurringScans: {
					isEnabled: false
					emailSubscriptionAdmins: true
				}
			}
		}
	}
}

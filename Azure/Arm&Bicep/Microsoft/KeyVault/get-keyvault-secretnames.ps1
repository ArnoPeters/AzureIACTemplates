Param(
  [ValidateSet("d", "a", "p")]
  [Parameter(Mandatory = $true)]
  [string] $environment,
  
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $keyVaultName,
  
  [parameter()]
  [ValidateNotNullOrEmpty()]
  [string] $outputParameterName = "keyvaultExistingSecretNames"
)

if ($vaultName.StartsWith("`$")) {
  return; #protection against Azure Devops Variables with no value. 
}

$currentSubscription = (Get-AzContext).Subscription.Name
 
$existingSecretNames = New-Object System.Collections.ArrayList
if(Get-AzKeyVault -VaultName $keyVaultName){
  Write-host "Retreiving existing secret names from $keyVaultName"
  $(Get-AzKeyVaultSecret -VaultName $keyVaultName).foreach{ $existingSecretNames.Add($_.Name) } | Out-Null
} else {
  Write-host "Keyvault '$keyVaultName' not found on subscription '$currentSubscription'. Use 'Set-AzContext' to switch to a different subscription."
}

$secretsJson = (ConvertTo-Json($existingSecretNames) -Compress)
Write-Host "##vso[task.setvariable variable=$outputParameterName;]$secretsJson"

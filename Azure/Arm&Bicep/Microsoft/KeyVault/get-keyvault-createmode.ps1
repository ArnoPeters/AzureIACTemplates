Param(
  [ValidateSet("d", "a", "p")]
  [Parameter(Mandatory = $true)]
  [string] $environment,
  
  [parameter(Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $keyVaultName,
  
  [parameter()]
  [ValidateNotNullOrEmpty()]
  [string] $outputParameterName = "keyvaultCreateMode"
)

if ($vaultName.StartsWith("`$")) {
  return; #protection against Azure Devops Variables with no value. 
}

$currentSubscription = (Get-AzContext).Subscription.Name

if (Get-AzKeyVault -VaultName $keyVaultName) {
  Write-host "Setting create mode to 'recover' : Keyvault '$keyVaultName' was found on subscription '$currentSubscription'"
  $keyvaultCreateMode = "recover"
} else {
  Write-host "Setting create mode to 'default' : Keyvault '$keyVaultName' not found on subscription '$currentSubscription'. Use 'Set-AzContext' to switch to a different subscription if applicable."
  $keyvaultCreateMode = "default";
}

Write-Host "##vso[task.setvariable variable=$outputParameterName;]$keyvaultCreateMode"
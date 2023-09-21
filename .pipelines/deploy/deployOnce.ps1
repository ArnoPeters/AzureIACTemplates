#TODO: docs
Param
(
  ##[Parameter (Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $deploymentLogLocation = 'WestEurope',  
	
  #[Parameter (Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $resourceLocation = 'west europe',

  [Parameter (Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [string] $ownerPrefix ,

  [Parameter (Mandatory = $true)]
  [ValidateNotNullOrEmpty()]
  [securestring] $ownerContactEmail  
)

TODO: Bicep requires template specs to be already available. 
This in turn should generate the correct bicepconfig.json
perhaps add correct info as output to template specs upload as well? 


#TODO: make this actually run once ;) (or request permission to overwrite)

az deployment sub create --location $deploymentLogLocation --template-file "deployment.bicep" --parameters location=$resourceLocation ownerPrefix=$ownerPrefix  ownerContactEmail=$ownerContactEmail --parameters "deployment.parameters.d.json"
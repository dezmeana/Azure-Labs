# Preferences
$WarningPreference = 'SilentlyContinue'

# Variables
$region = "eastus"
$westRegion = "westus"
$username = "AzureAdmin" # username for the VM
# SECURITY ISSUE: Consider using Get-Credential instead of hardcoding password
$plainPassword = "Password!123" # your VM password
$VMSize = "Standard_B1s"

# Creating VM credential
$password = ConvertTo-SecureString $plainPassword -AsPlainText -Force
$credential = New-Object System.Management.Automation.PSCredential ($username, $password)

# Create Resource Group
$rg = "2vnet-seperatePIP-lab-$(Get-Date -Format 'yyyyMMdd')"
New-AzResourceGroup -Name $rg -Location $region

Write-Host "Creating VNETs and Subnets for East US" -ForegroundColor Green
# Create vnet-01 in East US
New-AzVirtualNetwork -ResourceGroupName $rg -Name 'vnet-01' -Location $region -AddressPrefix '10.0.0.0/16'
$vnet01 = Get-AzVirtualNetwork -Name 'vnet-01' -ResourceGroupName $rg
$vnet01 = Add-AzVirtualNetworkSubnetConfig -Name 'JumpboxSubnet' -AddressPrefix '10.0.1.0/24' -VirtualNetwork $vnet01
$vnet01 = Add-AzVirtualNetworkSubnetConfig -Name 'WorkloadSubnet1' -AddressPrefix '10.0.2.0/24' -VirtualNetwork $vnet01
$vnet01 | Set-AzVirtualNetwork

# Create vnet-02 in West US
Write-Host "Creating VNETs and Subnets for West US" -ForegroundColor Green
New-AzVirtualNetwork -ResourceGroupName $rg -Name 'vnet-02' -Location $westRegion -AddressPrefix '10.1.0.0/16'
$vnet02 = Get-AzVirtualNetwork -Name 'vnet-02' -ResourceGroupName $rg
$vnet02 = Add-AzVirtualNetworkSubnetConfig -Name 'WorkloadSubnet2' -AddressPrefix '10.1.1.0/24' -VirtualNetwork $vnet02
$vnet02 | Set-AzVirtualNetwork

# Create Jumpbox VM
Write-Host "Creating Jumpbox VM" -ForegroundColor Green
New-AzVm `
    -ResourceGroupName $rg `
    -Name 'jumpboxVM' `
    -Location $region `
    -ImageName 'Ubuntu2204' `
    -Size $VMSize `
    -PublicIpAddressName 'jumpbox-vm-pip' `
    -OpenPorts 22 `
    -Credential $credential `
    -VirtualNetworkName 'vnet-01' `
    -SubnetName 'JumpboxSubnet'
  
# Create VM-01
Write-Host "Creating VM-01" -ForegroundColor Green 
New-AzVm `
    -ResourceGroupName $rg `
    -Name 'vm-01' `
    -Location $region `
    -ImageName 'Ubuntu2204' `
    -Size $VMSize `
    -OpenPorts 22 `
    -Credential $credential `
    -VirtualNetworkName 'vnet-01' `
    -SubnetName 'WorkloadSubnet1'

# Create VM-02
Write-Host "Creating VM-02" -ForegroundColor Green
New-AzVm `
    -ResourceGroupName $rg `
    -Name 'vm-02' `
    -Location $westRegion `
    -ImageName 'Ubuntu2204' `
    -Size $VMSize `
    -PublicIpAddressName 'vm-02-pip' `
    -OpenPorts 22 `
    -Credential $credential `
    -VirtualNetworkName 'vnet-02' `
    -SubnetName 'WorkloadSubnet2'

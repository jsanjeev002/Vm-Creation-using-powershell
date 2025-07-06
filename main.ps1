# 1. Create resource group
$resourceGroupName = "vmresourcegroup"
$location = "central us"
$rgSplat = @{
    Name     = $resourceGroupName
    Location = $location
}
New-AzResourceGroup @rgSplat

# 2. Create subnet 
$subnetName = "subnetA"
$subnetAddressSpace = "10.0.0.0/24"
$subnet = New-AzVirtualNetworkSubnetConfig -Name $subnetName -AddressPrefix $subnetAddressSpace

# 3. Create virtual network
$virtualNetworkName = "app-network"
$virtualNetworkAddressSpace = "10.0.0.0/16"
$vnetSplat = @{
    Name              = $virtualNetworkName
    ResourceGroupName = $resourceGroupName
    Location          = $location
    AddressPrefix     = $virtualNetworkAddressSpace
    Subnet            = $subnet
}
$virtualNetwork = New-AzVirtualNetwork @vnetSplat

# Retrieve subnet from virtual network
$virtualNetwork = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName
$subnet  = Get-AzVirtualNetworkSubnetConfig -Name $subnetName -VirtualNetwork $virtualNetwork

# 4. Create network interface
$networkInterfaceName = "app-interface"
$nicSplat = @{
    Name              = $networkInterfaceName
    ResourceGroupName = $resourceGroupName
    Location          = $location
    Subnet            = $subnet
}
$networkInterface = New-AzNetworkInterface @nicSplat

# 5. Create public IP address
$publicIpAddressName = "app-ip"
$ipSplat = @{
    Name              = $publicIpAddressName
    ResourceGroupName = $resourceGroupName
    Location          = $location
    Sku               = "Standard"
    AllocationMethod  = "Static"
}
$publicIpAddress = New-AzPublicIpAddress @ipSplat

# . Attach public IP to NIC
# Retrieve NIC and IP config
$networkInterface = Get-AzNetworkInterface -Name $networkInterfaceName -ResourceGroupName $resourceGroupName
$ipConfig = Get-AzNetworkInterfaceIpConfig -NetworkInterface $networkInterface

$ipConfigSplat = @{
    PublicIpAddress    = $publicIpAddress
    Name               = $ipConfig.Name
    NetworkInterface   = $networkInterface
}

Set-AzNetworkInterfaceIpConfig @ipConfigSplat

# Apply the changes
Set-AzNetworkInterface -NetworkInterface $networkInterface

# Create RDP rule
$rdpRuleSplat = @{
    Name                    = "Allow-RDP"
    Description             = "Allow RDP access"
    Access                  = "Allow"
    Protocol                = "Tcp"
    Direction               = "Inbound"
    Priority                = 100
    SourceAddressPrefix     = "*SourcePortRange*”
    DestinationAddressPrefix= "*DestinationPortRange 3389*"
   
}
$nsgRuleRDP = New-AzNetworkSecurityRuleConfig @rdpRuleSplat

# 6. Create NSG
$networkSecurityGroupName = "vm-nsg"
$nsgSplat = @{
    Name              = $networkSecurityGroupName
    ResourceGroupName = $resourceGroupName
    Location          = $location
    SecurityRules   = $nsgRuleRDP
}
$networkSecurityGroup = New-AzNetworkSecurityGroup @nsgSplat

# . Assign NSG to subnet
$virtualNetwork = Get-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName

$subnetUpdateSplat = @{
    Name                = $subnetName
    VirtualNetwork      = $virtualNetwork
    AddressPrefix       = $subnetAddressSpace
    NetworkSecurityGroup= $networkSecurityGroup
}
Set-AzVirtualNetworkSubnetConfig @subnetUpdateSplat

Set-AzVirtualNetwork -VirtualNetwork $virtualNetwork

# 7. Create VM configuration
$nic = Get-AzNetworkInterface -Name $networkInterfaceName -ResourceGroupName $resourceGroupName

$vmName = "vmdemo"
$vmSize = "Standard_DS2_v3"
$username = "powershell-user"
$cred = Get-Credential

$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize
$vmConfig = Set-AzVMOperatingSystem -VM $vmConfig -Windows -ComputerName $vmName  -Credential $cred -ProvisionVMAgent -EnableAutoUpdate
$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id
$vmConfig = Set-AzVMSourceImage -VM $vmConfig `
    -PublisherName 'MicrosoftWindowsServer' -Offer 'WindowsServer' `
    -Skus '2019-Datacenter' -Version 'latest'

# 7.2. Create the VM
$vmSplat = @{
    ResourceGroupName = $resourceGroupName
    Location          = $location
    VM                = $vmConfig
    Verbose           = $true
}
New-AzVM @vmSplat

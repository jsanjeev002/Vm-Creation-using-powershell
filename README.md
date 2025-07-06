# Azure VM Deployment using PowerShell

This PowerShell script automates the deployment of a Windows Server 2019 virtual machine on Microsoft Azure. It includes steps to create a resource group, virtual network, subnet, public IP, network interface, network security group (NSG), and a virtual machine.

## 🚀 Features

- Creates a resource group and virtual network
- Sets up subnet, NSG with RDP rule, and public IP
- Creates and configures a NIC and attaches it to the VM
- Deploys a Windows Server 2019 VM
- Uses parameter splatting for clean, readable code

## 📂 Structure

1. Create Resource Group
2. Configure Virtual Network and Subnet
3. Create Public IP and Network Interface
4. Set up NSG with RDP access
5. Assign NSG to Subnet
6. Configure and Deploy the VM

## 🔧 Requirements

- PowerShell 7+
- Azure PowerShell Module (`Az`)
- Azure Subscription
- Proper permissions to create Azure resources


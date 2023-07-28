/*
Author: Robert Barker
Date: 26/07/2023
Version: 1.0
Description: This module creates Web virtual machines for the WebApp project.
*/


// Passed in parameters
@description('The Azure region into which resources will be deployed.')
param location string

@description('The environment type such as Production or NonProduction')
param environmentType string

@description('Enter the Admin user Name.')
param adminUserName string

@description('Enter the Admin user password')
@secure()
param adminUserPassword string

@description('Availability set for this project.')
param availabilitySetID string

@description('Storage endpoint used for diagnostic data collection.')
param storageEndpoint string
// End of passed in parameters


// Local parameters
//Virtual Network for the VMs listed in the vmNames array
@description('Virtual network name.')
param virtualNetworkName string = 'vnet-webapp'

//Subnet for the VMs listed in the vmNames array
@description('The VNet subnet.')
param virtualNetworkSubnetName string = 'sn-webapp-01'

//An array used to hold names of the Web virtual machines
@description('The Virtual Machine name.')
param vmNames array = [
  'web-webapp-01'
  //Comment out the next line to save costs.
  //'web-webapp-02'
]


//This parameter block facilitates the use of different resources based on environment type.
@description('SKU type names are case-sensitive. A public IP sku must match the sku of the Load Balancer with which it is used')
var environmentSettings = {
  Production: {
    vmSize: 'Standard_D2s_v3'
    diskSizeGB: 1024
  }
  NonProduction: {
    vmSize: 'Standard_B1ms'
    diskSizeGB: 250
  }
}


//Call generic CreateVM module to create the VMs listed in the vmNames array
module createVM '../Generic/CreateVM.bicep' = [for vmName in vmNames: {
  name: '${vmName}-VM'
  params: {
    adminUserName: adminUserName
    adminUserPassword: adminUserPassword
    availabilitySetID: availabilitySetID
    location: location
    storageEndpoint: storageEndpoint
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkSubnetName
    vmName: vmName
    vmSize: environmentSettings[environmentType].vmSize
    diskSizeGB: environmentSettings[environmentType].diskSizeGB
    dataDisks: 0
  }
}]



//Install the web server feature
resource virtualMachine_IIS 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = [for vmName in vmNames: {
  name: '${vmName}/IIS'
  location: location
  properties: {
    autoUpgradeMinorVersion: true
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      commandToExecute: 'powershell Add-WindowsFeature Web-Server -IncludeManagementTools; powershell Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value $($env:computername); powershell Add-Content -Path "C:\\inetpub\\wwwroot\\Default.htm" -Value located-in-Azure'
    }
  }
  dependsOn: [
    createVM
  ]
}]





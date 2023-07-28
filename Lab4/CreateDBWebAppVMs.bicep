/*
Author: Robert Barker
Date: 26/07/2023
Version: 1.0
Description: This module creates database virtual machines for the WebApp project.
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
param virtualNetworkSubnetName string = 'sn-webapp-02'

//An array used to hold names of the database virtual machines
@description('The Virtual Machine name.')
param vmNames array = [
  'db-webapp-01'
  //The next line is commented out to save cost
  //'db-webapp-02'
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
    dataDisks: 2
  }
}]








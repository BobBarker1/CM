/*
Author: Robert Barker
Date: 16/06/2023
Version: 1.0
Description: Creates a network interface card assigned to a virtual network.
*/


// The following parameters get their value passed through.
@description('The Azure datacentre region into which this resource will be created.')
param location string

@description('NIC name.')
param nicName string

@description('The virtual network name.')
param virtualNetworkName string

@description('The virtual subnet name.')
param virtualNetworkSubnetName string
// End of passed through parameters



resource networkInterface 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: nicName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, virtualNetworkSubnetName)
          }
        }
      }
    ]
  }
}

output NicID string = networkInterface.id

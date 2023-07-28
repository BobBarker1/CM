/*
Author: Robert Barker
Date: 24/07/2023
Version: 1.0
Description: This module creates a Virtual Private Network to my home lab.
*/


@description('The Azure region into which resources will be deployed.')
param location string

@description('The name of the Virtual Network Gateway.')
param vngName string = 'gw-webapp'

@description('The type of Virtual Network Gateway.')
param vngType string = 'Vpn'

@description('VPN type of this gateway.')
param vngVpnType string = 'RouteBased'

@description('The SKU for this Virtual Network Gateway.')
param vngSku string = 'VpnGw2'

@description('On which network should this gateway be placed?')
param vngVirtualNetwork string = 'vnet-webapp'

@description('This gateway will use which public IP address?')
param vngPublicIPAddress string = 'pip-webapp-gw'

@description('Provide a name for the Local Network Gateway')
param localNetworkGatewayName string = 'ln-chingfordhq'

@description('The on-premise local network')
param addressPrefixes string =  '192.168.2.0/24'

@description('The public IP address of the on-premise VPN device')
param gatewayIpAddress string =  '146.200.100.252'

@description('Name of the VPN connection')
param vpnVnetConnectionName string = 'gw-webapp-${localNetworkGatewayName}'

@description('VPN connection type')
param connectionType string = 'IPsec'

@description('Shared secrect key')
@secure()
param sharedKey string 



//Declare a variable to the public IP address used by this gateway
resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2022-09-01' existing = {
  name: vngPublicIPAddress
}

//Declare a variable to the subnet used by this gateway
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  name: 'vnet-webapp/GatewaySubnet'
}


//Create the gateway
resource virtualNetworkGateway 'Microsoft.Network/virtualNetworkGateways@2022-09-01' = {
  name:  vngName
  location: location
  properties: {
    activeActive: false
    enableBgp: false
    ipConfigurations: [
      {
        name: vngVirtualNetwork
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet.id
          }
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    sku: {
      name: vngSku
      tier: vngSku
    }
    gatewayType: vngType
    vpnType: vngVpnType
    vpnGatewayGeneration: 'Generation2'
  }
}


//Create a local network gateway
resource localNetworkGateway 'Microsoft.Network/localNetworkGateways@2022-11-01' = {
  name: localNetworkGatewayName
  location: location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        addressPrefixes
      ]
    }
    gatewayIpAddress: gatewayIpAddress
  }
}


//Create a Connection
resource vpnVnetConnection 'Microsoft.Network/connections@2022-11-01' = {
  name: vpnVnetConnectionName
  location: location
  properties: {
    virtualNetworkGateway1: {
      id: virtualNetworkGateway.id
      properties:{}
    }
    localNetworkGateway2: {
      id: localNetworkGateway.id
      properties:{}
    }
    connectionType: connectionType
    routingWeight: 0
    sharedKey: sharedKey
  }
}









/*
Auther: Robert Barker
Date: 25/07/2023
Version: 1.0
Description: Establish virtual network peering
*/


@description('Set the local VNet name')
param LocalVirtualNetworkName string

@description('Set the remote VNet name')
param RemoteVirtualNetworkName string

@description('Sets the remote VNet Resource group')
param RemoteVirtualNetworkResourceGroupName string

resource existingLocalVirtualNetworkName_peering_to_remote_vnet 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2022-11-01' = {
  name: '${LocalVirtualNetworkName}/peering-to-remote-vnet'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: false
    allowGatewayTransit: false
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(RemoteVirtualNetworkResourceGroupName, 'Microsoft.Network/virtualNetworks', RemoteVirtualNetworkName)
    }
  }
}


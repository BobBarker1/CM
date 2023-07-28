/*
Author: Robert Barker
Date: 02/05/2023
Version: 1.0
Description: Creates a virtual network as per instructions in the Cloud Machanix training course v1.9 Lab3.
*/


//Tags
@description('A brief description for this resource, such as its intended use.')
param tagDescription string = 'Virtual Network and Subnets for the Cloud Machanix Test Lab'
@description('Who is responsible for this resource?')
param tagOwner string = 'IT Department'

//Location
@description('The Azure region into which resources will be deployed.')
param location string

//Environment Type
@description('Resource class will likely change depending on selection')
param environmentType string

//Virtual Network
@description('The name given to this virtual network.')
param virtualNetworkName string = 'vnet-webapp'
@description('The address prefix for this virtual network.')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

//First Subnet
@description('The name given to this virtual subnet.')
param virtualNetworkSubnet00Name string = 'sn-webapp-00'
@description('The address prefix for this virtual subnet.')
param virtualNetworkSubnet00AddressPrefix string = '10.0.0.0/24'

//Second Subnet
@description('The name given to this virtual subnet.')
param virtualNetworkSubnet01Name string = 'sn-webapp-01'
@description('The address prefix for this virtual subnet.')
param virtualNetworkSubnet01AddressPrefix string = '10.0.1.0/24'

//Third Subnet
@description('The name given to this virtual subnet.')
param virtualNetworkSubnet02Name string = 'sn-webapp-02'
@description('The address prefix for this virtual subnet.')
param virtualNetworkSubnet02AddressPrefix string = '10.0.2.0/24'

//Gateway Subnet
@description('This subnet must be called GatewaySubnet in order for Aure to recognise it properly.')
param virtualNetworkGatewaySubnet string = 'GatewaySubnet'
@description('The address prefix for this virtual subnet.')
param virtualNetworkGatewaySubnetAddressPrefix string = '10.0.254.0/24'

//DDos Protection
@description('Is DDOS required?')
param dDosRequired bool
@description('The name of the DDosProtectionPlan.')
param ddosProtectionPlanName string = 'vnet-webapp-ddosProtection'


//On-Premise DNS server
@description('Enter the IP Address of the local DNS server.')
param onPremiseDNSServer string = '192.168.2.1'


//Network Security Groups
@description('The name of the Network Security Group applying to the Web Servers')
param webServersNSGName string = 'nsg-webapp-sn01'
@description('The name of the Network Security Group applying to the Database Servers')
param databaseServersNSGName string = 'nsg-webapp-sn02'

@description('Load network security group rules from json file.')
var webServerNSGRules = loadJsonContent('NSGWebServers.json', 'securityRules')
@description('Load network security group rules from json file.')
var databaseServerNSGRules = loadJsonContent('NSGDatabaseServers.json', 'securityRules')


//Resources

//Create a Network Security Group for the web servers subnet
resource webNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: webServersNSGName
  location: location
  properties: {
    securityRules: webServerNSGRules
  }
}

//Create a Network Security Group for the database servers subnet
resource databaseNetworkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-09-01' = {
  name: databaseServersNSGName
  location: location
  properties: {
    securityRules: databaseServerNSGRules
  }
}

//Create a DDOS proection plan
resource ddosProtectionPlan 'Microsoft.Network/ddosProtectionPlans@2022-09-01' = if (dDosRequired) {
  name: ddosProtectionPlanName
  location: location
}

//Create the virtual network with subnets and additional features
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-09-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]      
    }    
    subnets: [
      {
        name: virtualNetworkSubnet00Name
        properties: {
          addressPrefix: virtualNetworkSubnet00AddressPrefix
        }
      }
      {
        name: virtualNetworkSubnet01Name
        properties: {
          addressPrefix: virtualNetworkSubnet01AddressPrefix
          networkSecurityGroup: {
            id: webNetworkSecurityGroup.id
          }
        }
      }
      {
        name: virtualNetworkSubnet02Name
        properties: {
          addressPrefix: virtualNetworkSubnet02AddressPrefix
          networkSecurityGroup: {
            id: databaseNetworkSecurityGroup.id
          }
        }
      }
      {
        name: virtualNetworkGatewaySubnet
        properties: {
          addressPrefix: virtualNetworkGatewaySubnetAddressPrefix         
        }
      }
    ]        
    enableDdosProtection: dDosRequired ? dDosRequired : null
    ddosProtectionPlan:  dDosRequired ? {id: ddosProtectionPlan.id} : null
    dhcpOptions: {
      dnsServers: [
        onPremiseDNSServer
      ]
    }
  }
}

//Create resource tags
resource mainTags 'Microsoft.Resources/tags@2022-09-01' = {
  name: 'default'
  scope: virtualNetwork
  properties: {
    tags: {
      Description: tagDescription
      Owner: tagOwner
      Environment: environmentType
    }
  }
}



//Virtual Network peering
//When considering local and remote, remember the terms relate to scope of the resource group.
module peerFirstvNetToSecondvNet 'vNetPeering.bicep' = {
  dependsOn: [
    virtualNetwork
  ]
  name: 'peerFirstToSecond'
  scope: resourceGroup('cm')
  params: {
    LocalVirtualNetworkName: virtualNetworkName
    RemoteVirtualNetworkName: 'vnet-jumpbox'
    RemoteVirtualNetworkResourceGroupName: 'cmjumpbox'
  }
}


//Virtual Network peering
//When considering local and remote, remember the terms relate to scope of the resource group.
module peerSecondvNetToFirstvNet 'vNetPeering.bicep' = {
  dependsOn: [
    virtualNetwork
  ]
  name: 'peerSecondToFirst'
  scope: resourceGroup('cmjumpbox')
  params: {
    LocalVirtualNetworkName: 'vnet-jumpbox'
    RemoteVirtualNetworkName: virtualNetworkName
    RemoteVirtualNetworkResourceGroupName: 'cm'
  }
}




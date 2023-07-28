/*
Author: Robert Barker
Date: 02/05/2023
Version: 1.0
Description: Creates the lab as per Cloud Machanix training course v1.9.
*/


@description('The Azure region into which resources will be deployed.')
param location string = resourceGroup().location

@description('The environment type such as Production or NonProduction')
@allowed([
  'NonProduction'
  'Production'
])
param environmentType string

@description('Enable DDOS Protection?')
param dDOSRequired bool = false

@description('Enter the Admin user Name.')
param adminUserName string


@description('Enter the Admin user password')
@secure()
param adminUserPassword string

@description('The name of the webapp gateway public IP resource.')
param webappPublicIPAddressName string = 'pip-webapp-gw'

@description('The name of the jumpbox public IP resource.')
param jumpboxPublicIPAddressName string = 'pip-jumpbox-lb'

@description('The domain name label prefix for the webapp public IP address.')
param webappDNL string = 'cmwebapp'

@description('The domain name label prefix for the jumpbox public IP address.')
param jumpboxDNL string = 'cmjump'

@description('The name of the wag gateway public IP resource.')
param wagPublicIPAddressName string = 'pip-webapp-wag'

@description('The domain name label prefix for the wag public IP address.')
param wagDNL string = 'cmwag'

@description('Availability set for this project.')
param availabilitySetName string = 'as-webapp-db'


// Key vault resources
var subscriptionId = subscription().subscriptionId
var kvResourceGroup = 'templatespecs'
var kvName = 'cmkeyvault01'
var vpnSecret = 'ChingfordSharedVPNKey'


//Resources

//Create a storage account
module storageModule 'Lab2/StorageAccount.bicep' = {
  name: 'storageDeploy'
  params: {
    environmentType: environmentType
    location: location
  }
}

//Create a virtual network with DDOS Protection
module virtualNetworkModuleDDOS 'Lab3/VirtualNetworkDDOS.bicep' = {
  name: 'virtualNetworkDeployDDOS'
  params: {
    environmentType: environmentType
    location: location
    dDosRequired: dDOSRequired
  }
}


//Create a Public IP Address for the webapp gateway
module webappPublicIPAddressModule 'Generic/PublicIPAddresses.bicep' = {
  name: '${webappPublicIPAddressName}Deploy'
  params: {
    environmentType: environmentType
    location: location
    publicIPAddressName: webappPublicIPAddressName
    domainNameLabelPrefix: webappDNL
  }
}



//Create a Public IP Address for the jumpbox
module jumpboxPublicIPAddressModule 'Generic/PublicIPAddresses.bicep' = {
  name: '${jumpboxPublicIPAddressName}Deploy'
  params: {
    environmentType: environmentType
    location: location
    publicIPAddressName: jumpboxPublicIPAddressName
    domainNameLabelPrefix: jumpboxDNL
  }
}


//Create a Public IP Address for the wagWebApp gateway
module wagPublicIPAddressModule 'Generic/PublicIPAddresses.bicep' = {
  name: '${wagPublicIPAddressName}Deploy'
  params: {
    environmentType: environmentType
    location: location
    publicIPAddressName: wagPublicIPAddressName
    domainNameLabelPrefix: wagDNL
  }
}


// Create a reference to the key vault
resource keyVault 'Microsoft.KeyVault/vaults@2023-02-01' existing = {
  name: kvName
  scope: resourceGroup(subscriptionId, kvResourceGroup )
}


//Create a VPN Gateway
module vpnGateway 'Lab3/VPNGateway.bicep' = {
  name: 'vpnGatewayDeploy'
  dependsOn: [
    virtualNetworkModuleDDOS
  ]
  params: {
    location: location
    sharedKey: keyVault.getSecret(vpnSecret)
  }
}


//Create a web application gateway
module webAppGateway 'Lab3/WebAppGateway.bicep' = {
  name: 'webAppGatewayDeploy'
  dependsOn: [
    vpnGateway
  ]
  params: {
    location: location
  }
}


//Create an Availabilty Set
module availabilitySet 'Generic/AvailabilitySet.bicep' = {
  name: availabilitySetName
  params: {
    availabilitySetName: availabilitySetName
    location: location
  }
}


// Create database VMs.
module createDBVMs 'Lab4/CreateDBWebAppVMs.bicep' = {
  name: 'DBVMs'
  params: {
    location: location
    adminUserName: adminUserName
    adminUserPassword: adminUserPassword
    availabilitySetID: availabilitySet.outputs.availabilitySetID
    environmentType: environmentType
    storageEndpoint: storageModule.outputs.endpoint
  }
}


//Create web VMs.
module CreateWebVMs 'Lab4/CreateWebWebAppVMs.bicep' = {
  name: 'WebVMs'
  params: {
    adminUserName: adminUserName
    adminUserPassword: adminUserPassword
    availabilitySetID: availabilitySet.outputs.availabilitySetID
    environmentType: environmentType
    location: location
    storageEndpoint: storageModule.outputs.endpoint
  }
}



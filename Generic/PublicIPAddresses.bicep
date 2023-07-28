/*
Author: Robert Barker
Date: 26/07/2023
Version: 1.0
Description: This module creates a Public IP Address for the WebApp project.
*/


//These values are passed through from main.bicep
param location string
param publicIPAddressName string
param domainNameLabelPrefix string
param environmentType string


@description('Create a unique value for a pulic IP address domain name label.')
var domainNameLabel = '${domainNameLabelPrefix}${uniqueString(resourceGroup().id)}'


//This parameter block facilitates the use of different resources based on environment type.
@description('SKU type names are case-sensitive. A public IP sku must match the sku of the Load Balancer with which it is used')
var environmentSettings = {
  Production: {
    publicIPAddressSkuName: 'Standard'
    tier: 'Regional'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: '4'
    publicIPAddressVersion: 'IPv4'
    domainNameLabel: domainNameLabel
  }
  NonProduction: {
    publicIPAddressSkuName: 'Standard' // Note: The web application gateway requires NonProduction to have these values as a minimum.
    tier: 'Regional'
    publicIPAllocationMethod: 'Static' 
    idleTimeoutInMinutes: '4'
    publicIPAddressVersion: 'IPv4'
    domainNameLabel: domainNameLabel
  }
}


//Create the Public IP Address
resource publicIP 'Microsoft.Network/publicIPAddresses@2022-09-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: environmentSettings[environmentType].publicIPAddressSkuName
    tier: environmentSettings[environmentType].tier
  }
  properties: {
    publicIPAllocationMethod: environmentSettings[environmentType].publicIPAllocationMethod
    idleTimeoutInMinutes: environmentSettings[environmentType].idleTimeoutInMinutes
    publicIPAddressVersion: environmentSettings[environmentType].publicIPAddressVersion
    dnsSettings: {
      domainNameLabel: environmentSettings[environmentType].domainNameLabel
    }    
  }
}






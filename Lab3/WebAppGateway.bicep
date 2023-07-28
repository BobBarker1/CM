/*
Author: Robert Barker
Date: 26/07/2023
Version: 1.0
Description: This module creates an Application Gateway for the web servers of this project.
*/



@description('The Azure region into which resources will be deployed.')
param location string

@description('What will this Application Gateway be called?')
param wagName string = 'wag-webapp'

@description('The public IP address for this gateway')
param wagPublicIPAddress string = 'pip-webapp-wag'

@description('This Gateway will serve which virtual network?')
param wagVirtualNetwork string = 'vnet-webapp'

@description('Sku for the Application Gateway')
var wagSku = 'WAF_V2'

@description('Tier for the Application Gateway')
var wagTier = 'WAF_V2'

var frontEndName = '${wagName}-FrontEnd'
var backendAddressPool1 = '${wagName}-BackEndPool1'
var backendHttpSettings = 'HTTP-Settings'
var listenerPort80 = 'Listner-Port-80'



//Create a variable to the public IP address used by this gateway
resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2022-09-01' existing = {
  name: wagPublicIPAddress
}


//Create a variable to the subnet used by this gateway
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2022-09-01' existing = {
  name: 'vnet-webapp/sn-webapp-00'
}



resource webApplicationGateway 'Microsoft.Network/applicationGateways@2021-03-01' = {
  name: wagName
  location: location
  properties: {
    sku: {
      name:  wagSku
      tier:  wagTier
    }
    gatewayIPConfigurations: [
      {
        name: wagVirtualNetwork
        properties: {
          subnet: {
            id: subnet.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: frontEndName
        properties: {
          publicIPAddress: {
             id: publicIPAddress.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'port_80'
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: backendAddressPool1
        properties: {
          backendAddresses: [
            {
              ipAddress: '10.0.1.4'
            }
            {
              ipAddress: '10.0.1.5'
            }
            {
              fqdn: 'KWWeb1.KnobblyWidgets.com'
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: backendHttpSettings
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
        }
      }
    ]
    httpListeners: [
      {
        name: listenerPort80
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', wagName, frontEndName)
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', wagName, 'port_80')
          }
          protocol: 'Http'
          requireServerNameIndication: false
        }
      }
    ]
    requestRoutingRules: [
       {
         name: 'rule1'
         properties: {
          ruleType: 'Basic'
           httpListener: {
             id: resourceId('Microsoft.Network/applicationGateways/httpListeners', wagName, listenerPort80)
           }
           backendAddressPool: {
             id:  resourceId('Microsoft.Network/applicationGateways/backendAddressPools', wagName, backendAddressPool1)
           }
           backendHttpSettings: {
             id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', wagName, backendHttpSettings)
           }
         }
       }
    ]
    enableHttp2: false
    autoscaleConfiguration: {
      minCapacity: 0
       maxCapacity: 2
    }
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.0'
      
    }
  }
}




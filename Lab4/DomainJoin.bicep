/*
Author: Robert Barker
Date: 14/07/2023
Version: 1.0
Description: Used to join an Azure VM to a local domain
*/


@description('The Azure region into which resources will be deployed.')
param location string = resourceGroup().location

@description('Password for the local domain admin account.')
@secure()
param localDomainAdministratorPassword string

//Azure virtual machine to be domain joined
@description('The Virtual Machine name.')
param vmName string 



var domain = 'knobblywidgets.com'
var ouPath = 'OU=Servers,DC=KnobblyWidgets,DC=com'
var administratorAccountUsername = 'knobadmin@knobblywidgets.com'


resource windowsVM 'Microsoft.Compute/virtualMachines@2023-03-01' existing = {
  name: vmName
  resource vm_joindomain 'extensions@2023-03-01' = {
    location: location
    name: '${vmName}-joinDomain'
    properties: {
      publisher: 'Microsoft.Compute'
      type: 'JsonADDomainExtension'
      typeHandlerVersion: '1.3'
      autoUpgradeMinorVersion: false
      settings: {
        name: domain
        ouPath: ouPath
        user: administratorAccountUsername
        restart: 'true'
        options: '3'
      }
      protectedSettings: {
        password: localDomainAdministratorPassword
      }
    }
  }
}



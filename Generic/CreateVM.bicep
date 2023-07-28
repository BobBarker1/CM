/*
Author: Robert Barker
Date: 20/06/2023
Version 1.0
Description: Generic bicep code to create a virtual machine.  All key parmeters are passed into this module.
*/


// The following parameters get their value passed from main.bicep
@description('The Azure datacentre region into which this VM will be created.')
param location string

@description('Passed by main.bicep, this value represents a Storage Account endpoint that will be used by this VM for diagnostic data collection.')
param storageEndpoint string

@description('The Virtual Machine name.')
param vmName string

@description('Administrator username for this VM.')
param adminUserName string

@description('The Administrator password.')
@secure()
param adminUserPassword string

@description('Availability set for this project.')
param availabilitySetID string


// Virtual Network Adapters belong to a virtual network, not a virtual machine.
// Create a vNIC once the virtual network/subnet of the VM is known.

//Virtual Network
@description('Virtual network name.')
param virtualNetworkName string

//Subnet
@description('The VNet subnet.')
param virtualNetworkSubnetName string

//VM Sku
@description('The virtual machine Sku.')
param vmSize string

//Disk size in GB for empty disks
@description('Disk size in GB for empty disks.')
param diskSizeGB int

//Data disks
@description('How many data disks are required?')
param dataDisks int

// End of passed through parameters



var vmNicName = '${vmName}-Nic1'
var osDiskName = '${vmName}-OSdisk'
var dataDiskName = '${vmName}-Data'
var vmPublisher = 'MicrosoftWindowsServer'
var vmOffer = 'WindowsServer'
var vmSku = '2016-Datacenter-gensecond'
var vmVersion = 'latest'
var vmCaching = 'ReadWrite'
var vmOSDiskCreateOption = 'FromImage'
var vmOSDiskSize = 128
var vmDataDiskCreateOption = 'Empty'
var vmDiskStorageAccountType = 'Premium_LRS'
var vmOSType = 'Windows'
var vmTimeZone = 'GMT Standard Time'



//This VM will need a NIC
module vNic '../Generic/CreateNic.bicep' = {
  name: vmNicName
  params: {
    location: location
    nicName: vmNicName
    virtualNetworkName: virtualNetworkName
    virtualNetworkSubnetName: virtualNetworkSubnetName
  }
}


//Build the virtual machine.
resource windowsVM 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminUserPassword
      windowsConfiguration: {
        enableAutomaticUpdates: true
        provisionVMAgent: true
        timeZone: vmTimeZone
      }
    }
    storageProfile: {
      imageReference: {
        publisher: vmPublisher
        offer: vmOffer
        sku: vmSku
        version: vmVersion
      }
      osDisk: {
        name: osDiskName
        caching: vmCaching
        createOption: vmOSDiskCreateOption
        osType: vmOSType
        diskSizeGB: vmOSDiskSize
        managedDisk: {
          storageAccountType: vmDiskStorageAccountType
        }
      }
      dataDisks: [for i in range(0, dataDisks): {
          createOption: vmDataDiskCreateOption
          lun: i
          diskSizeGB: diskSizeGB
          name: '${dataDiskName}${i}'
          caching: vmCaching
          managedDisk: {
            storageAccountType: vmDiskStorageAccountType
          }
        }]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: vNic.outputs.NicID
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageEndpoint
      }
    }
    availabilitySet: {
      id: availabilitySetID
    }
  }
}



// Add the Network Watcher agent to the VM

resource netwatch 'Microsoft.Compute/virtualMachines/extensions@2023-03-01' = {
  parent: windowsVM
  location: location
  name: 'AzureNetworkWatcherExtension'
  properties: {
    publisher: 'Microsoft.Azure.NetworkWatcher'
    type: 'NetworkWatcherAgentWindows'
    typeHandlerVersion: '1.4'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true    
  }
}



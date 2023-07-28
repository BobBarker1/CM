/*
Author: Robert Barker
Date: 27/04/2023
Version: 1.0
Description: Creates a storage account as per the instructions found in the Cloud Machanix training course Lab2.
*/


@description('A brief description for this resource, such as its intended use.')
param tagDescription string = 'Default Storage Account for the Cloud Machanix Test Lab'

@description('Who is responsible for this resource?')
param tagOwner string = 'IT Department'

@description('The Azure region into which resources will be deployed.')
param location string

@description('A globally unique name for the storage account. Storage account names must be between 3 and 24 characters in length and may contain numbers and lowercase letters only.')
@minLength(3)
@maxLength(24)
param storageAccountName string = 'cmlab${uniqueString(resourceGroup().id)}'

@description('The environment type')
param environmentType string

param storageAccountKind string = 'StorageV2'
param storageAccountAccessTier string = 'Hot' //The Hot Tier is for common usage such as regular read and write.

@description('SKU type names are case-sensitive')
var storageAccountSkuName = (environmentType == 'Production') ? 'Standard_GRS' : 'Standard_LRS'


resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  kind: storageAccountKind
  sku: {
    name: storageAccountSkuName
  }
  properties: {
    accessTier: storageAccountAccessTier
  }
}


resource mainTags 'Microsoft.Resources/tags@2022-09-01' = {
  name: 'default'
  scope: storageAccount
  properties: {
    tags: {
      Description: tagDescription
      Owner: tagOwner
      Environment: environmentType
    }
  }
}

output endpoint string = storageAccount.properties.primaryEndpoints.blob



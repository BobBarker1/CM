/*
Author: Robert Barker
Date: 16/06/2023
Version: 1.0
Description: Creates an Availabilty Set and returns the set ID.
*/



// The following parameters get their value passed from main.bicep
@description('The Azure datacentre region into which this VM will be created.')
param location string

@description('Availability set name.')
param availabilitySetName string
// End of passed through parameters


//Create an availability set.
resource availabilitySet 'Microsoft.Compute/availabilitySets@2023-03-01' = {
  name: availabilitySetName
  location: location
  sku: {
    name: 'Aligned' //Note that Aligned is necessary for managed disks
  }
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 5
  }
}


output availabilitySetID string = availabilitySet.id




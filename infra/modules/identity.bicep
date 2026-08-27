@description('The name of the user-assigned managed identity used by the function app.')
param functionUserManagedIdentityName string

@description('The location where the identity will be deployed.')
param location string

resource functionUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: functionUserManagedIdentityName
  location: location
}

output id string = functionUserManagedIdentity.id
output name string = functionUserManagedIdentity.name
output principalId string = functionUserManagedIdentity.properties.principalId
output clientId string = functionUserManagedIdentity.properties.clientId

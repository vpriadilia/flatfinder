@description('The name of the user-assigned managed identity used by the function app.')
param functionUserManagedIdentityName string

@description('The location where the identity will be deployed.')
param location string

@description('The name of the Key Vault the identity needs access to for reading secrets.')
param keyVaultName string

@description('The name of the resource group containing the Key Vault, if different from the deployment resource group.')
param keyVaultResourceGroupName string = resourceGroup().name

resource functionUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: functionUserManagedIdentityName
  location: location
}

module keyVaultAccess 'keyVaultAccess.bicep' = {
  name: 'keyVaultAccess'
  scope: resourceGroup(keyVaultResourceGroupName)
  params: {
    keyVaultName: keyVaultName
    identityResourceId: functionUserManagedIdentity.id
    principalId: functionUserManagedIdentity.properties.principalId
  }
}

output id string = functionUserManagedIdentity.id
output name string = functionUserManagedIdentity.name
output principalId string = functionUserManagedIdentity.properties.principalId
output clientId string = functionUserManagedIdentity.properties.clientId

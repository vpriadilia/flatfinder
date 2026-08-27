@description('The name of the Key Vault to grant access to. Deployed at the scope of the resource group containing it.')
param keyVaultName string

@description('The resource ID of the identity being granted access, used as a deterministic seed for the role assignment name.')
param identityResourceId string

@description('The principal ID of the identity being granted access.')
param principalId string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
}

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identityResourceId, keyVault.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

@description('The name of the storage account.')
param storageAccountName string

@description('The location where the storage account will be deployed.')
param location string

@description('The name of the blob service.')
param blobServiceName string = 'default'

@description('The name of the table service.')
param tableServiceName string = 'default'

@description('The name of the blob container used for deployment packages.')
param deploymentContainerName string

@description('The name of the blob container used for Facebook scraper state.')
param statesContainerName string

@description('The name of the blob container used for scraper configuration.')
param configContainerName string

@description('The name of the table used for deduplication of seen posts.')
param seenPostsTableName string

@description('The name of the identity that needs data-plane access to this storage account.')
param functionUserManagedIdentityName string

@description('The principal ID of the identity that needs data-plane access to this storage account.')
param principalId string

var identityId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', functionUserManagedIdentityName)

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-09-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
  resource blobService 'blobServices@2022-09-01' = {
    name: blobServiceName
    properties: {
      deleteRetentionPolicy: {
        enabled: true
        days: 7
      }
      isVersioningEnabled: true
    }
    resource blobContainerDeployment 'containers@2022-09-01' = {
      name: deploymentContainerName
      properties: {
        publicAccess: 'None'
      }
    }
    resource blobContainerStates 'containers@2022-09-01' = {
      name: statesContainerName
      properties: {
        publicAccess: 'None'
      }
    }
    resource blobContainerConfig 'containers@2022-09-01' = {
      name: configContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }
  resource tableService 'tableServices@2022-09-01' = {
    name: tableServiceName
    resource seenPostsTable 'tables@2022-09-01' = {
      name: seenPostsTableName
    }
  }
}

resource storageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identityId, storageAccount.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output name string = storageAccount.name
output id string = storageAccount.id

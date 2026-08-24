targetScope = 'resourceGroup'

param location string = resourceGroup().location

param storageAccountName string = 'flatfinderdevsa'
param blobServiceName string = 'default'
param deploymentContainerName string = 'deployment'
param tableServiceName string = 'default'
param seenPostsTableName string = 'SeenFacebookPosts'

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
    resource blobContainer 'containers@2022-09-01' = {
      name: deploymentContainerName
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

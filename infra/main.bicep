targetScope = 'resourceGroup'

param location string = resourceGroup().location

param storageAccountName string = 'flatfinderdevsa'

param blobServiceName string = 'default'
param tableServiceName string = 'default'

param deploymentContainerName string = 'deployment'
param statesContainerName string = 'states'
param configContainerName string = 'config'
param seenPostsTableName string = 'flatfinderseenposts'

param serviceBusNamespaceName string = 'flatfinder-dev-sbns'
param serviceBusQueueName string = 'flatfinder-dev-sbq'

param functionUserManagedIdentityName string = 'flatfinderdev-func-identity'

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

resource namespace 'Microsoft.ServiceBus/namespaces@2022-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    capacity: 0
    name: 'Standard'
    tier: 'Standard'
  }
  properties: {
    disableLocalAuth: false
    publicNetworkAccess: 'Enabled'
    zoneRedundant: false
  }
}

resource queue 'Microsoft.ServiceBus/namespaces/queues@2021-06-01-preview' = {
  name: serviceBusQueueName
  parent: namespace
  properties: {
    deadLetteringOnMessageExpiration: false
    enableBatchedOperations: true
    enableExpress: false
    enablePartitioning: true
    maxDeliveryCount: 10
    maxSizeInMegabytes: 1024
    requiresDuplicateDetection: false
    requiresSession: false
    status: 'Active'
  }
}

resource functionUserManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: functionUserManagedIdentityName
  location: location
}

resource storageAccountRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionUserManagedIdentity.id, storageAccount.id, 'Storage Blob Data Contributor')
  scope: storageAccount
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: functionUserManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource serviceBusRoleAssignmentSender 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionUserManagedIdentity.id, namespace.id, 'Azure Service Bus Data Sender')
  scope: namespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39')
    principalId: functionUserManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource serviceBusRoleAssignmentReceiver 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionUserManagedIdentity.id, namespace.id, 'Azure Service Bus Data Receiver')
  scope: namespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0')
    principalId: functionUserManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

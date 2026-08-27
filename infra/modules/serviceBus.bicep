@description('The name of the Service Bus namespace.')
param serviceBusNamespaceName string

@description('The name of the Service Bus queue.')
param serviceBusQueueName string

@description('The location where the Service Bus namespace will be deployed.')
param location string

@description('The name of the identity that needs data-plane access to this Service Bus namespace.')
param functionUserManagedIdentityName string

@description('The principal ID of the identity that needs data-plane access to this Service Bus namespace.')
param principalId string

var identityId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', functionUserManagedIdentityName)


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

resource serviceBusRoleAssignmentSender 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identityId, namespace.id, 'Azure Service Bus Data Sender')
  scope: namespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '69a216fc-b8fb-44d8-bc22-1f3c2cd27a39')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

resource serviceBusRoleAssignmentReceiver 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(identityId, namespace.id, 'Azure Service Bus Data Receiver')
  scope: namespace
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0')
    principalId: principalId
    principalType: 'ServicePrincipal'
  }
}

output name string = namespace.name
output queueName string = queue.name
output serviceBusEndpoint string = namespace.properties.serviceBusEndpoint

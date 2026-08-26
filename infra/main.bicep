targetScope = 'resourceGroup'


@description('The name of the resource group where the resources will be deployed.')
param resourceGroupName string

@description('The subscription ID where the resources will be deployed.')
param subscriptionId string 

@description('The name of the Key Vault where the secrets will be stored.')
param keyVaultName string

@description('The name of the secret in Key Vault that contains the Anthropic API key.')
param location string = resourceGroup().location

@description('The name of the secret in Key Vault that contains the Telegram bot token.')
param storageAccountName string = 'flatfinderdevsa'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param blobServiceName string = 'default'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param tableServiceName string = 'default'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param deploymentContainerName string = 'deployment'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param statesContainerName string = 'states'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param configContainerName string = 'config'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param seenPostsTableName string = 'flatfinderseenposts'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param serviceBusNamespaceName string = 'flatfinder-dev-sbns'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param serviceBusQueueName string = 'flatfinder-dev-sbq'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param functionUserManagedIdentityName string = 'flatfinderdev-func-identity'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param appServicePlanName string = 'flatfinderdev-func-asp1'

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param functionAppName string = 'flatfinderdev-func'

@description('The name of the Application Insights resource to create.')
param appInsightsName string = 'flatfinderdev-ai'

@description('The Api key for Anthropic API, stored as a secret in Key Vault.')
@secure()
param anthropicApiKey string

@description('The Telegram bot token, stored as a secret in Key Vault.')
@secure()
param telegramBotToken string

@description('The Telegram chat ID, stored as a secret in Key Vault.')
@secure()
param telegramChatId string

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

// existing key vault
resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
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

resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionUserManagedIdentity.id, keyVault.id, 'Key Vault Secrets User')
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '4633458b-17de-408a-b874-0445c86b69e6')
    principalId: functionUserManagedIdentity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource appInsightsComponents 'Microsoft.Insights/components@2020-02-02' = {
  name: appInsightsName
  location: location
  kind: 'web'
  properties: {
    Application_Type: 'web'
    DisableIpMasking: false
    DisableLocalAuth: false
    ForceCustomerStorageForProfiler: false
    RetentionInDays: 90
    SamplingPercentage: 100
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  kind: 'functionapp'
  sku: {
    tier: 'FlexConsumption'
    name: 'FC1'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${functionUserManagedIdentity.id}': {}
    }
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsComponents.properties.ConnectionString
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccount.name
        }
        {
          name: 'FLATFINDER_ANTHROPIC_API_KEY'
          value: anthropicApiKey
        }
        {
          name: 'TELEGRAM_BOT_TOKEN'
          value: telegramBotToken
        }
        {
          name: 'TELEGRAM_CHAT_ID'
          value: telegramChatId
        }
        {
          name: 'ServiceBusConnection__queueName'
          value: serviceBusQueueName
        }
        {
          name: 'ServiceBusConnection__fullyQualifiedNamespace'
          value: namespace.properties.serviceBusEndpoint
        }
        {
          name: 'FACEBOOK_STATE_BLOB_CONTAINER'
          value: statesContainerName
        }
        {
          name: 'FACEBOOK_STATE_BLOB_NAME'
          value: 'state.json'
        }
        {
          name: 'SCRAPER_CONFIG_BLOB_CONTAINER'
          value: configContainerName
        }
        {
          name: 'SCRAPER_CONFIG_BLOB_NAME'
          value: 'scraper-config.json'
        }
        {
          name: 'DEDUPLICATION_PARTITION_KEY'
          value: seenPostsTableName
        }
        {
          name: 'DEDUPLICATION_TABLE_NAME'
          value: seenPostsTableName
        }
      ]
    }
    functionAppConfig: {
      scaleAndConcurrency: {
        instanceMemoryMB: 512
        maximumInstanceCount: 10
      }
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${storageAccount.properties.primaryEndpoints.blob}${deploymentContainerName}'
          authentication: {
            type: 'UserAssignedIdentity'
            userAssignedIdentityResourceId: functionUserManagedIdentity.id
          }
        }
      }
      runtime: {
        name: 'dotnet-isolated'
        version: '10.0'
      }
    }
  }
}


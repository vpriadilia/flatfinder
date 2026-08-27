@description('The location where the resources will be deployed.')
param location string

@description('The name of the Container Apps environment hosting the containerized function app.')
param containerAppsEnvironmentName string

@description('The name of the Log Analytics workspace backing the Container Apps environment.')
param logAnalyticsWorkspaceName string

@description('The name of the Azure Container Registry storing the function app image.')
param containerRegistryName string

@description('The name of the container image (repository) for the function app.')
param containerImageName string

@description('The tag of the container image to deploy. Overridden per-build by CI (e.g. the commit SHA).')
param imageTag string

@description('The name of the function app.')
param functionAppName string

@description('The name of the user-assigned managed identity to attach to the function app.')
param functionUserManagedIdentityName string

@description('The principal ID of the user-assigned managed identity, used for the ACR pull role assignment.')
param functionUserManagedIdentityPrincipalId string

@description('The client ID of the user-assigned managed identity, used for AzureWebJobsStorage auth.')
param functionUserManagedIdentityClientId string

var functionUserManagedIdentityId = resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', functionUserManagedIdentityName)

@description('The connection string for Application Insights.')
param appInsightsConnectionString string

@description('The name of the storage account backing the function app.')
param storageAccountName string

@description('The name of the Service Bus queue.')
param serviceBusQueueName string

@description('The fully qualified Service Bus namespace endpoint.')
param serviceBusEndpoint string

@description('The name of the blob container used for Facebook scraper state.')
param statesContainerName string

@description('The name of the blob container used for scraper configuration.')
param configContainerName string

@description('The name of the table used for deduplication of seen posts.')
param seenPostsTableName string

@description('The Anthropic model used for post extraction.')
param anthropicModel string

@description('The max tokens for the Anthropic extraction response.')
param anthropicMaxTokens string

@description('The Api key for Anthropic API, stored as a secret in Key Vault.')
@secure()
param anthropicApiKey string

@description('The Telegram bot token, stored as a secret in Key Vault.')
@secure()
param telegramBotToken string

@description('The Telegram chat ID, stored as a secret in Key Vault.')
@secure()
param telegramChatId string

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2022-10-01' existing = {
  name: logAnalyticsWorkspaceName
}

resource containerAppsEnvironment 'Microsoft.App/managedEnvironments@2024-03-01' = {
  name: containerAppsEnvironmentName
  location: location
  properties: {
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalyticsWorkspace.properties.customerId
        sharedKey: logAnalyticsWorkspace.listKeys().primarySharedKey
      }
    }
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
  }
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: containerRegistryName
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    adminUserEnabled: false
  }
}

resource acrPullRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(functionUserManagedIdentityId, containerRegistry.id, 'AcrPull')
  scope: containerRegistry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '7f951dda-4ed3-4680-a7ca-43fe172d538d')
    principalId: functionUserManagedIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux,container,azurecontainerapps'
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${functionUserManagedIdentityId}': {}
    }
  }
  properties: {
    managedEnvironmentId: containerAppsEnvironment.id
    workloadProfileName: 'Consumption'
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${containerRegistry.properties.loginServer}/${containerImageName}:${imageTag}'
      acrUseManagedIdentityCreds: true
      acrUserManagedIdentityID: functionUserManagedIdentityId
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: appInsightsConnectionString
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storageAccountName
        }
        {
          name: 'AzureWebJobsStorage__credential'
          value: 'managedidentity'
        }
        {
          name: 'AzureWebJobsStorage__clientId'
          value: functionUserManagedIdentityClientId
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: containerRegistry.properties.loginServer
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
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
          value: serviceBusEndpoint
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
        {
          name: 'ANTHROPIC_MODEL'
          value: anthropicModel
        }
        {
          name: 'ANTHROPIC_MAX_TOKENS'
          value: anthropicMaxTokens
        }
      ]
    }
  }
  dependsOn: [
    acrPullRoleAssignment
  ]
}

output name string = functionApp.name
output containerRegistryLoginServer string = containerRegistry.properties.loginServer

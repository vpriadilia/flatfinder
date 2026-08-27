targetScope = 'resourceGroup'

@description('The name of the secret in Key Vault that contains the Anthropic API key.')
param location string = resourceGroup().location

@description('The name of the secret in Key Vault that contains the Telegram bot token.')
param storageAccountName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param blobServiceName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param tableServiceName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param deploymentContainerName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param statesContainerName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param configContainerName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param seenPostsTableName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param serviceBusNamespaceName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param serviceBusQueueName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param functionUserManagedIdentityName string

@description('The name of the secret in Key Vault that contains the Telegram chat ID.')
param functionAppName string

@description('The name of the Key Vault where the secrets are stored.')
param keyVaultName string

@description('The name of the resource group containing the Key Vault, if different from the deployment resource group.')
param keyVaultResourceGroupName string

@description('The name of the Application Insights resource to create.')
param appInsightsName string

@description('The name of the Log Analytics workspace backing the Container Apps environment.')
param logAnalyticsWorkspaceName string

@description('The name of the Container Apps environment hosting the containerized function app.')
param containerAppsEnvironmentName string

@description('The name of the Azure Container Registry storing the function app image.')
param containerRegistryName string

@description('The name of the container image (repository) for the function app.')
param containerImageName string

@description('The tag of the container image to deploy. Overridden per-build by CI (e.g. the commit SHA).')
param imageTag string

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

module identity 'modules/identity.bicep' = {
  name: 'identity'
  params: {
    functionUserManagedIdentityName: functionUserManagedIdentityName
    location: location
  }
}

module storage 'modules/storage.bicep' = {
  name: 'storage'
  params: {
    storageAccountName: storageAccountName
    location: location
    blobServiceName: blobServiceName
    tableServiceName: tableServiceName
    deploymentContainerName: deploymentContainerName
    statesContainerName: statesContainerName
    configContainerName: configContainerName
    seenPostsTableName: seenPostsTableName
    functionUserManagedIdentityName: functionUserManagedIdentityName
    principalId: identity.outputs.principalId
  }
}

module serviceBus 'modules/serviceBus.bicep' = {
  name: 'serviceBus'
  params: {
    serviceBusNamespaceName: serviceBusNamespaceName
    serviceBusQueueName: serviceBusQueueName
    location: location
    functionUserManagedIdentityName: functionUserManagedIdentityName
    principalId: identity.outputs.principalId
  }
}

module monitoring 'modules/monitoring.bicep' = {
  name: 'monitoring'
  params: {
    appInsightsName: appInsightsName
    logAnalyticsWorkspaceName: logAnalyticsWorkspaceName
    location: location
  }
}

module functionApp 'modules/functionApp.bicep' = {
  name: 'functionApp'
  params: {
    location: location
    containerAppsEnvironmentName: containerAppsEnvironmentName
    logAnalyticsWorkspaceName: monitoring.outputs.logAnalyticsWorkspaceName
    containerRegistryName: containerRegistryName
    containerImageName: containerImageName
    imageTag: imageTag
    functionAppName: functionAppName
    functionUserManagedIdentityName: functionUserManagedIdentityName
    functionUserManagedIdentityPrincipalId: identity.outputs.principalId
    functionUserManagedIdentityClientId: identity.outputs.clientId
    appInsightsConnectionString: monitoring.outputs.appInsightsConnectionString
    storageAccountName: storage.outputs.name
    serviceBusQueueName: serviceBus.outputs.queueName
    serviceBusEndpoint: serviceBus.outputs.serviceBusEndpoint
    statesContainerName: statesContainerName
    configContainerName: configContainerName
    seenPostsTableName: seenPostsTableName
    anthropicModel: anthropicModel
    anthropicMaxTokens: anthropicMaxTokens
    anthropicApiKey: anthropicApiKey
    telegramBotToken: telegramBotToken
    telegramChatId: telegramChatId
  }
}

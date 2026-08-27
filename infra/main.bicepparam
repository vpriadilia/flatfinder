using 'main.bicep'

param storageAccountName = 'flatfinderdevsa'
param blobServiceName = 'default'
param tableServiceName = 'default'
param deploymentContainerName = 'deployment'
param statesContainerName = 'states'
param configContainerName = 'config'
param seenPostsTableName = 'flatfinderseenposts'
param serviceBusNamespaceName = 'flatfinder-dev-sbns'
param serviceBusQueueName = 'flatfinder-dev-sbq'
param functionUserManagedIdentityName = 'flatfinderdev-func-identity'
param functionAppName = 'flatfinderdev-func'
param containerAppsEnvironmentName = 'flatfinderdev-cae'
param containerRegistryName = 'flatfinderdevacr'
param containerImageName = 'flatfinder-func'
param imageTag = 'latest'
param appInsightsName = 'flatfinderdev-ai'
param logAnalyticsWorkspaceName = 'flatfinderdev-law'

param anthropicModel = 'claude-haiku-4-5-20251001'
param anthropicMaxTokens = '300'

param keyVaultName = 'internal-apps-kv1'
param keyVaultResourceGroupName = 'secrets'

param anthropicApiKey = getSecret(
  'abc0537b-c817-41b9-b296-16986ec847db', keyVaultResourceGroupName,
  keyVaultName, 'AnthropicApiKey')

param telegramBotToken = getSecret(
  'abc0537b-c817-41b9-b296-16986ec847db', keyVaultResourceGroupName,
  keyVaultName, 'TelegramBotToken')

param telegramChatId = getSecret(
  'abc0537b-c817-41b9-b296-16986ec847db', keyVaultResourceGroupName,
  keyVaultName, 'TelegramChatId')

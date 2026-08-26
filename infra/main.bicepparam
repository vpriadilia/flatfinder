using 'main.bicep'

param subscriptionId = 'abc0537b-c817-41b9-b296-16986ec847db'
param resourceGroupName = 'flatfinder-dev-rg'
param keyVaultName = 'flatfinder-dev-kv'

param anthropicApiKey = getSecret(
  subscriptionId, resourceGroupName, 
  keyVaultName, 'AnthropicApiKey')

param telegramBotToken = getSecret(
  subscriptionId, resourceGroupName, 
  keyVaultName, 'TelegramBotToken')

param telegramChatId = getSecret(
  subscriptionId, resourceGroupName, 
  keyVaultName, 'TelegramChatId')

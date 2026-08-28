<img width="1232" height="552" alt="image" src="https://github.com/user-attachments/assets/e5f68f48-e9e3-4006-bb8c-70e27e9a754d" />

#### Used Services
- Azure Service Bus - queue used to decouple the group scraper from the post processor
- Azure Key Vault - stores the Anthropic API key and Telegram bot secrets, injected at deploy time (external vault, separate resource group)
- Azure Container Apps Environment
  - Azure Function App (container) - scrapes Facebook groups, extracts/filters posts, and sends Telegram notifications
- Azure Container Registry - stores the Function App's Docker image, built and pushed by CI
- Azure Storage Account
  - Blob storage - Facebook session state, scraper config, and deployment packages
  - Table storage - post deduplication
- Azure Application Insights (+ Log Analytics) - monitoring and logging for the Function App
- Azure Managed Identity (user-assigned) - grants the Function App access to Storage, Service Bus, and Key Vault without secrets
- Microsoft Entra ID App Registration (federated credential) - lets GitHub Actions deploy via OIDC, no stored client secret

#### Examples:

FlatFinder monitors a set of Facebook groups for new apartment rental posts, uses Anthropic to
extract structured details (type, price, description) from each post, filters out irrelevant
ones, and forwards new matches to a Telegram channel - each message includes the extracted
summary plus a link back to the original Facebook post

<img width="695" height="1030" alt="image" src="https://github.com/user-attachments/assets/61499775-e38a-4727-9e07-ca552466bf0f" />

<img width="501" height="952" alt="image" src="https://github.com/user-attachments/assets/09482152-3216-4be9-bde0-3b3d21954f56" />

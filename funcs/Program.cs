using Anthropic;
using Azure.Core;
using Azure.Data.Tables;
using Azure.Identity;
using Azure.Messaging.ServiceBus;
using Azure.Monitor.OpenTelemetry.Exporter;
using Azure.Storage.Blobs;
using funcs.Abstractions;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using funcs.Services;
using Microsoft.Extensions.Configuration;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

var storageAccountName = builder.Configuration["AzureWebJobsStorage:accountName"];
var apiKey = Environment.GetEnvironmentVariable("FLATFINDER_ANTHROPIC_API_KEY");
var tableName = Environment.GetEnvironmentVariable("DEDUPLICATION_TABLE_NAME")!;
var credential = new DefaultAzureCredential(new DefaultAzureCredentialOptions
{
    ManagedIdentityClientId = builder.Configuration["AzureWebJobsStorage:clientId"]
});

builder.Services.AddSingleton(
    _ => new AnthropicClient
    {
        ApiKey = apiKey
    });

builder.Services.AddSingleton(
    _ => new TableClient(
        new Uri($"https://{storageAccountName}.table.core.windows.net"),
        tableName,
        credential,
        new TableClientOptions
        {
            Retry =
            {
                Mode = RetryMode.Exponential,
                Delay = TimeSpan.FromSeconds(1),
                MaxDelay = TimeSpan.FromSeconds(30),
                MaxRetries = 5
            }
        }));

builder.Services.AddSingleton(
    _ => new BlobServiceClient(
        new Uri($"https://{storageAccountName}.blob.core.windows.net"),
        credential));

var fullyQualifiedNamespace = builder.Configuration.GetValue<string>("ServiceBusConnection:fullyQualifiedNamespace");
var queueName = builder.Configuration.GetValue<string>("ServiceBusConnection:queueName");
var userManagedClientId = builder.Configuration.GetValue<string>("ServiceBusConnection:clientId");
builder.Services.AddSingleton(_ =>
{
    var credentialOptions = new DefaultAzureCredentialOptions
    {
        ManagedIdentityClientId = userManagedClientId
    };
    var azureCredential = new DefaultAzureCredential(credentialOptions);
    var serviceBusClient = new ServiceBusClient(fullyQualifiedNamespace, azureCredential);
    return serviceBusClient.CreateSender(queueName);
});

builder.Services.AddSingleton<IExtractor, AnthropicExtractor>();
builder.Services.AddSingleton<IDeduplicator, TableDeduplicator>();
builder.Services.AddSingleton<IFacebookSessionStateStore, BlobFacebookSessionStateStore>();
builder.Services.AddSingleton<IScraperConfigProvider, BlobScraperConfigProvider>();
builder.Services.AddSingleton<IPostBatchPublisher, ServiceBusPostPublisher>();
builder.Services.AddScoped<IPostScraper, PlaywrightPostScraper>();
builder.Services.AddHttpClient<TelegramNotifier>();
builder.Services.AddScoped<INotifier>(sp => sp.GetRequiredService<TelegramNotifier>());

if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING")))
{
    builder.Services.AddOpenTelemetry()
        .UseFunctionsWorkerDefaults()
        .UseAzureMonitorExporter();
}

builder.Build().Run();
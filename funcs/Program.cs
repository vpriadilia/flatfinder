using Anthropic;
using Azure.Monitor.OpenTelemetry.Exporter;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Azure.Functions.Worker.Builder;
using Microsoft.Azure.Functions.Worker.OpenTelemetry;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using OpenTelemetry;
using funcs.Services;

var builder = FunctionsApplication.CreateBuilder(args);

builder.ConfigureFunctionsWebApplication();

var apiKey = builder.Configuration.GetSection("ApiKey").Value;
var tableName = Environment.GetEnvironmentVariable("DEDUPLICATION_TABLE_NAME")!;

// var accountName = configuration["AzureWebJobsStorage:accountName"];
// var serviceClient = new TableServiceClient(
//     new Uri($"https://{accountName}.table.core.windows.net"),
//     new DefaultAzureCredential());

builder.Services.AddScoped(
    _ => new AnthropicClient
    {
        ApiKey = apiKey
    });

builder.Services.AddScoped(
    _ => new Azure.Data.Tables.TableClient(
        Environment.GetEnvironmentVariable("AzureWebJobsStorage")!,
        tableName,
        new Azure.Data.Tables.TableClientOptions
        {
            Retry =
            {
                Mode = Azure.Core.RetryMode.Exponential,
                Delay = TimeSpan.FromSeconds(1),
                MaxDelay = TimeSpan.FromSeconds(30),
                MaxRetries = 5
            }
        }));


builder.Services.AddSingleton<AnthropicExtractor>();
builder.Services.AddSingleton<TableDeduplicator>();
builder.Services.AddHttpClient<TelegramNotifier>();



if (!string.IsNullOrEmpty(Environment.GetEnvironmentVariable("APPLICATIONINSIGHTS_CONNECTION_STRING")))
{
    builder.Services.AddOpenTelemetry()
        .UseFunctionsWorkerDefaults()
        .UseAzureMonitorExporter();
}

builder.Build().Run();
using System.Text;
using System.Text.Json;
using Azure;
using Azure.Storage.Blobs;
using funcs.Abstractions;
using funcs.Models;
using Microsoft.Extensions.Logging;

namespace funcs.Services;

public class BlobScraperConfigProvider(BlobServiceClient blobServiceClient, ILogger<BlobScraperConfigProvider> logger)
    : IScraperConfigProvider
{
    private readonly string _containerName = Environment.GetEnvironmentVariable("SCRAPER_CONFIG_BLOB_CONTAINER")!;
    private readonly string _blobName = Environment.GetEnvironmentVariable("SCRAPER_CONFIG_BLOB_NAME")!;

    private static readonly ScraperConfig DefaultConfig = new(
        Groups: [],
        OnlyOfferings: true,
        AllowedTypes: null,
        MinPrice: null,
        MaxPrice: null);

    public async Task<ScraperConfig> GetConfigAsync(CancellationToken ct = default)
    {
        var containerClient = blobServiceClient.GetBlobContainerClient(_containerName);
        var blobClient = containerClient.GetBlobClient(_blobName);
        try
        {
            var response = await blobClient.DownloadContentAsync(ct);
            var config = response.Value.Content.ToObjectFromJson<ScraperConfig>(new JsonSerializerOptions
            {
                PropertyNameCaseInsensitive = true
            });
            return config ?? DefaultConfig;
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            logger.LogWarning(
                "Scraper config blob not found at {Container}/{Blob}; seeding it with the default config",
                _containerName,
                _blobName);
            await SeedDefaultConfigAsync(containerClient, blobClient, ct);
            return DefaultConfig;
        }
    }

    private static async Task SeedDefaultConfigAsync(BlobContainerClient containerClient, BlobClient blobClient, CancellationToken ct)
    {
        await containerClient.CreateIfNotExistsAsync(cancellationToken: ct);

        var json = JsonSerializer.Serialize(DefaultConfig, new JsonSerializerOptions
        {
            WriteIndented = true,
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        await using var stream = new MemoryStream(Encoding.UTF8.GetBytes(json));
        try
        {
            await blobClient.UploadAsync(stream, overwrite: false, cancellationToken: ct);
        }
        catch (RequestFailedException ex) when (ex.Status == 409)
        {
            // another instance already seeded it concurrently — nothing to do.
        }
    }
}

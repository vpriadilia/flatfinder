using System.Text.Json;
using Azure.Messaging.ServiceBus;
using funcs.Abstractions;
using funcs.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace funcs.Functions;

public class FacebookPostProcessorQueue(
    ILogger<FacebookPostProcessorQueue> logger,
    IExtractor extractor,
    IScraperConfigProvider configProvider,
    INotifier notifier)
{
    [Function(nameof(FacebookPostProcessorQueue))]
    public async Task Run(
        [ServiceBusTrigger("%POSTS_QUEUE_NAME%", Connection = "ServiceBusConnection")]
        ServiceBusReceivedMessage message)
    {
        var post = JsonSerializer.Deserialize<RawPost>(message.Body.ToString(), new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });
        if (post is null)
        {
            logger.LogWarning("Could not deserialize message {MessageId} into a post; skipping", message.MessageId);
            return;
        }

        var extracted = await extractor.ExtractAsync(post.Text);
        if (extracted is null)
        {
            logger.LogWarning("Extraction returned no data for post {Hash}; skipping", post.Hash);
            return;
        }

        var config = await configProvider.GetConfigAsync();
        if (!PassesFilter(extracted, config))
        {
            return;
        }

        await notifier.NotifyNewListingAsync(extracted, post.Link);
    }

    private static bool PassesFilter(ExtractedPost extracted, ScraperConfig config)
    {
        if (config.OnlyOfferings && !extracted.IsOffering)
        {
            return false;
        }

        if (config.AllowedTypes is { Length: > 0 } &&
            (extracted.Type is null || !config.AllowedTypes.Contains(extracted.Type, StringComparer.OrdinalIgnoreCase)))
        {
            return false;
        }

        if (config.MinPrice is { } minPrice && extracted.Price is { } minCheckPrice && minCheckPrice < minPrice)
        {
            return false;
        }

        if (config.MaxPrice is { } maxPrice && extracted.Price is { } maxCheckPrice && maxCheckPrice > maxPrice)
        {
            return false;
        }

        return true;
    }
}

using funcs.Abstractions;
using funcs.Exceptions;
using funcs.Models;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace funcs.Functions;

public class FacebookScrapperTimer(
    ILogger<FacebookScrapperTimer> logger,
    IPostScraper postScraper,
    IDeduplicator deduplicator,
    IPostBatchPublisher publisher,
    IScraperConfigProvider configProvider,
    INotifier notifier)
{
    [Function("FacebookScrapperTimer")]
    public async Task Run(
        [TimerTrigger("*/120 * * * * *")]
        TimerInfo myTimer)
    {
        var config = await configProvider.GetConfigAsync();
        if (config.Groups is not { Length: > 0 })
        {
            logger.LogWarning("No Facebook groups configured to monitor; skipping this run");
            return;
        }

        IReadOnlyList<RawPost> posts;
        try
        {
            posts = await postScraper.ScrapePostsAsync(config.Groups);
        }
        catch (FacebookSessionInvalidException ex)
        {
            logger.LogWarning(ex, "Skipping this run because the Facebook session is invalid or expired");
            await notifier.SendMessageAsync(
                "Facebook session expired or missing — call the FacebookLogin function to log in again.");
            return;
        }

        logger.LogInformation("Found {Count} posts across {GroupCount} groups", posts.Count, config.Groups.Length);

        var newPosts = new List<RawPost>();
        foreach (var post in posts)
        {
            if (!await deduplicator.IsSeenAsync(post.Hash))
            {
                newPosts.Add(post);
            }
        }

        if (newPosts.Count == 0)
        {
            return;
        }

        logger.LogInformation("Publishing {Count} new posts to Service Bus", newPosts.Count);
        await publisher.PublishAsync(newPosts);

        foreach (var post in newPosts)
        {
            await deduplicator.MarkSeenAsync(post.Hash);
        }
    }
}

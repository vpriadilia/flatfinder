using System.Text.RegularExpressions;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Microsoft.Playwright;
using funcs.Services;

namespace funcs.Functions;

public class FacebookScrapperTimer(
    ILogger<FacebookScrapperTimer> logger,
    AnthropicExtractor anthropicExtractor,
    TableDeduplicator tableDeduplicator,
    TelegramNotifier telegramNotifier)
{
    private readonly string _stateFilePath = Environment.GetEnvironmentVariable("FACEBOOK_STATE_FILE_PATH")!;

    [Function("FacebookScrapperTimer")]
    public async Task Run(
        [TimerTrigger("*/30 * * * * *")]
        TimerInfo myTimer)
    {
        if (!File.Exists(_stateFilePath))
        {
            logger.LogWarning(
                "Facebook session state not found at {Path}. Call the FacebookLogin HTTP function once to create it.",
                _stateFilePath);
            return;
        }
        
        using var playwright = await Playwright.CreateAsync();
        await using var browser = await playwright.Chromium.LaunchAsync(
            new BrowserTypeLaunchOptions
            {
                Headless = true
            });
        await using var context = await browser.NewContextAsync(new BrowserNewContextOptions
        {
            StorageStatePath = _stateFilePath
        });
        var page = await context.NewPageAsync();
        await page.GotoAsync(
            "https://www.facebook.com/groups/807812386001622",
            new PageGotoOptions
            {
                WaitUntil = WaitUntilState.DOMContentLoaded
            });
        await page.WaitForTimeoutAsync(5000);
        
        var posts = page.Locator("[role='article']");
        var count = await posts.CountAsync();
        
        logger.LogInformation("Found {Count} posts in the group", count);
        var seeMoreButton = new Regex("Більше|See more|Show more|Zobraziť viac", RegexOptions.IgnoreCase);

        for (var i = 0; i < count; i++)
        {
            var post = posts.Nth(i);

            var seeMore = post.GetByText(seeMoreButton);
            if (await seeMore.CountAsync() > 0)
            {
                try
                {
                    await seeMore.First.ClickAsync();
                }
                catch
                {
                    // ignore — text may already be expanded or the button detached
                }
            }

            var text = await post.InnerTextAsync();
            var link = await GetPostLinkAsync(post);

            var hash = TableDeduplicator.Hash(link ?? text);
            if (await tableDeduplicator.IsSeenAsync(hash))
            {
                continue;
            }

            var extracted = await anthropicExtractor.ExtractAsync(text);

            logger.LogInformation(
                "POST {Index}: offering={IsOffering} type={Type} price={Price} {Currency} link={Link}\n{Description}",
                i,
                extracted?.IsOffering,
                extracted?.Type,
                extracted?.Price,
                extracted?.Currency,
                extracted?.Description,
                link);

            if (extracted is { IsOffering: true })
            {
                await telegramNotifier.SendMessageAsync(
                    $"Type: {extracted.Type}\n" +
                    $"Price: {extracted.Price} {extracted.Currency}\n" +
                    $"{extracted.Description}\n" +
                    $"{link}");
            }

            await tableDeduplicator.MarkSeenAsync(hash);
        }
    }

    private static async Task<string?> GetPostLinkAsync(ILocator post)
    {
        var link = post.Locator("a[href*='/posts/'], a[href*='/permalink/']").First;
        if (await link.CountAsync() == 0)
        {
            return null;
        }

        var href = await link.GetAttributeAsync("href");
        return href is null
            ? null
            : new Uri(new Uri("https://www.facebook.com"), href).GetLeftPart(UriPartial.Path);
    }
}
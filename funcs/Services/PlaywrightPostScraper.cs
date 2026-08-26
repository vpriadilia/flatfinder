using funcs.Abstractions;
using funcs.Exceptions;
using funcs.Models;
using funcs.Utils;
using Microsoft.Playwright;

namespace funcs.Services;

public class PlaywrightPostScraper(IFacebookSessionStateStore stateStore) : IPostScraper
{
    public async Task<IReadOnlyList<RawPost>> ScrapePostsAsync(IReadOnlyList<string> groupUrls, CancellationToken ct = default)
    {
        var stateJson = await stateStore.LoadStateAsync(ct);
        if (stateJson is null)
        {
            throw new FacebookSessionInvalidException(
                "Facebook session state not found. Call the FacebookLogin HTTP function once to create it.");
        }

        using var playwright = await Playwright.CreateAsync();
        await using var browser = await playwright.Chromium.LaunchAsync(
            new BrowserTypeLaunchOptions
            {
                Headless = true
            });
        await using var context = await browser.NewContextAsync(new BrowserNewContextOptions
        {
            StorageState = stateJson
        });

        var result = new List<RawPost>();

        foreach (var groupUrl in groupUrls)
        {
            var page = await context.NewPageAsync();
            try
            {
                await ScrapeGroupAsync(page, groupUrl, result);
            }
            finally
            {
                await page.CloseAsync();
            }
        }
        return result;
    }

    private static async Task ScrapeGroupAsync(IPage page, string groupUrl, List<RawPost> result)
    {
        await page.GotoAsync(
            groupUrl,
            new PageGotoOptions
            {
                WaitUntil = WaitUntilState.DOMContentLoaded
            });
        await page.WaitForTimeoutAsync(5000);

        if (IsLoginRedirect(page.Url))
        {
            throw new FacebookSessionInvalidException(
                $"Facebook redirected to a login/checkpoint page while scraping {groupUrl}; " +
                "the session has likely expired. Call the FacebookLogin HTTP function again.");
        }

        var posts = page.Locator("[role='article']");
        var count = await posts.CountAsync();

        for (var i = 0; i < count; i++)
        {
            var post = posts.Nth(i);

            await FacebookUtils.ExpandSeeMoreAsync(post);

            var text = await post.InnerTextAsync();
            var link = await FacebookUtils.GetPostLinkAsync(post);
            var hash = PostHasher.Hash(link ?? text);

            result.Add(new RawPost(hash, text, link));
        }
    }

    // Facebook redirects unauthenticated navigations to a login/checkpoint URL instead of
    // returning an error, so the redirected URL shape is the only reliable expiry signal.
    private static bool IsLoginRedirect(string url) =>
        url.Contains("/login", StringComparison.OrdinalIgnoreCase) ||
        url.Contains("/checkpoint", StringComparison.OrdinalIgnoreCase);
}

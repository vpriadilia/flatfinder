using System.Text.RegularExpressions;
using Microsoft.Playwright;

namespace funcs.Utils;

public static class FacebookUtils
{
    private static readonly Regex SeeMoreButton = new("Більше|See more|Show more|Zobraziť viac", RegexOptions.IgnoreCase);

    public static async Task ExpandSeeMoreAsync(ILocator post)
    {
        var seeMore = post.GetByText(SeeMoreButton);
        if (await seeMore.CountAsync() == 0)
        {
            return;
        }

        try
        {
            await seeMore.First.ClickAsync();
        }
        catch
        {
            // ignore — text may already be expanded or the button detached
        }
    }

    public static async Task<string?> GetPostLinkAsync(ILocator post)
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

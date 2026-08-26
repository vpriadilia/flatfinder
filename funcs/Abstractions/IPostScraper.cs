using funcs.Models;

namespace funcs.Abstractions;

public interface IPostScraper
{
    Task<IReadOnlyList<RawPost>> ScrapePostsAsync(IReadOnlyList<string> groupUrls, CancellationToken ct = default);
}

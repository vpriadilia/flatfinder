using funcs.Models;

namespace funcs.Abstractions;

public interface IScraperConfigProvider
{
    Task<ScraperConfig> GetConfigAsync(CancellationToken ct = default);
}

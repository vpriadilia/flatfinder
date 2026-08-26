namespace funcs.Models;

public record ScraperConfig(
    string[] Groups,
    bool OnlyOfferings,
    string[]? AllowedTypes,
    decimal? MinPrice,
    decimal? MaxPrice);

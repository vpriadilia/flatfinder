namespace funcs.Models;

public record ExtractedPost(
    bool IsOffering,
    string? Type,
    decimal? Price,
    string? Currency,
    string Description);

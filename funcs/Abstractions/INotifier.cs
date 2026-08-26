using funcs.Models;

namespace funcs.Abstractions;

public interface INotifier
{
    Task SendMessageAsync(string text);

    Task NotifyNewListingAsync(ExtractedPost extracted, string? link);
}

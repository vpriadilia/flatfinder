using funcs.Models;

namespace funcs.Abstractions;

public interface IExtractor
{
    Task<ExtractedPost?> ExtractAsync(string postText);
}

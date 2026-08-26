using funcs.Models;

namespace funcs.Abstractions;

public interface IPostBatchPublisher
{
    Task PublishAsync(IReadOnlyList<RawPost> posts, CancellationToken ct = default);
}

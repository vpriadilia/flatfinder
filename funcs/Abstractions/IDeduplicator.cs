namespace funcs.Abstractions;

public interface IDeduplicator
{
    Task<bool> IsSeenAsync(string hash);

    Task MarkSeenAsync(string hash);
}

namespace funcs.Abstractions;

public interface IFacebookSessionStateStore
{
    Task<string?> LoadStateAsync(CancellationToken ct = default);

    Task SaveStateAsync(string stateJson, CancellationToken ct = default);
}

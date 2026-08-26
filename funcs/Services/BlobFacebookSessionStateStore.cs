using Azure;
using Azure.Storage.Blobs;
using funcs.Abstractions;

namespace funcs.Services;

public class BlobFacebookSessionStateStore(BlobServiceClient blobServiceClient) : IFacebookSessionStateStore
{
    private readonly string _containerName = Environment.GetEnvironmentVariable("FACEBOOK_STATE_BLOB_CONTAINER")!;
    private readonly string _blobName = Environment.GetEnvironmentVariable("FACEBOOK_STATE_BLOB_NAME")!;

    public async Task<string?> LoadStateAsync(CancellationToken ct = default)
    {
        var blobClient = blobServiceClient.GetBlobContainerClient(_containerName).GetBlobClient(_blobName);
        try
        {
            var response = await blobClient.DownloadContentAsync(ct);
            return response.Value.Content.ToString();
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return null;
        }
    }

    public async Task SaveStateAsync(string stateJson, CancellationToken ct = default)
    {
        var containerClient = blobServiceClient.GetBlobContainerClient(_containerName);
        await containerClient.CreateIfNotExistsAsync(cancellationToken: ct);

        var blobClient = containerClient.GetBlobClient(_blobName);
        await using var stream = new MemoryStream(System.Text.Encoding.UTF8.GetBytes(stateJson));
        await blobClient.UploadAsync(stream, overwrite: true, cancellationToken: ct);
    }
}

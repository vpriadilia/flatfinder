using System.Security.Cryptography;
using funcs.Abstractions;
using Azure.Data.Tables;
using System.Text;
using Azure;

namespace funcs.Services;

public class TableDeduplicator(TableClient tableClient) : IDeduplicator
{
    private readonly string _partitionKey = Environment.GetEnvironmentVariable("DEDUPLICATION_PARTITION_KEY")!;
    
    public static string Hash(string postText)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(postText));
        return Convert.ToHexString(bytes);
    }

    public async Task<bool> IsSeenAsync(string hash)
    {
        try
        {
            await tableClient.GetEntityAsync<TableEntity>(_partitionKey, hash);
            return true;
        }
        catch (RequestFailedException ex) when (ex.Status == 404)
        {
            return false;
        }
    }

    public async Task MarkSeenAsync(string hash)
    {
        var entity = new TableEntity(_partitionKey, hash);
        await tableClient.UpsertEntityAsync(entity);
    }
}

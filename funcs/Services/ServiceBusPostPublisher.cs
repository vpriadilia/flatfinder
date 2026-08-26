using System.Text.Json;
using Azure.Messaging.ServiceBus;
using funcs.Abstractions;
using funcs.Models;

namespace funcs.Services;

public class ServiceBusPostPublisher(ServiceBusSender sender) : IPostBatchPublisher
{
    public async Task PublishAsync(IReadOnlyList<RawPost> posts, CancellationToken ct = default)
    {
        if (posts.Count == 0)
        {
            return;
        }

        var batch = await sender.CreateMessageBatchAsync(ct);

        foreach (var post in posts)
        {
            var message = new ServiceBusMessage(JsonSerializer.Serialize(post))
            {
                MessageId = post.Hash
            };

            if (batch.TryAddMessage(message))
            {
                continue;
            }

            if (batch.Count == 0)
            {
                throw new InvalidOperationException(
                    $"Post with hash {post.Hash} is too large to fit in a Service Bus message batch.");
            }

            await sender.SendMessagesAsync(batch, ct);

            batch = await sender.CreateMessageBatchAsync(ct);
            if (!batch.TryAddMessage(message))
            {
                throw new InvalidOperationException(
                    $"Post with hash {post.Hash} is too large to fit in a Service Bus message batch.");
            }
        }

        if (batch.Count > 0)
        {
            await sender.SendMessagesAsync(batch, ct);
        }
    }
}

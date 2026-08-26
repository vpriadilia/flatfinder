using System.Text.Json;
using Anthropic;
using Anthropic.Models.Messages;
using funcs.Abstractions;
using funcs.Models;

namespace funcs.Services;

public class AnthropicExtractor(AnthropicClient client) : IExtractor
{
    private readonly string _model = Environment.GetEnvironmentVariable("ANTHROPIC_MODEL")!;
    private readonly int _maxTokens = int.Parse(Environment.GetEnvironmentVariable("ANTHROPIC_MAX_TOKENS")!);

    private static readonly Dictionary<string, JsonElement> Schema = new()
    {
        ["type"] = JsonSerializer.SerializeToElement("object"),
        ["properties"] = JsonSerializer.SerializeToElement(new
        {
            isOffering = new
            {
                type = "boolean",
                description = "true if the author is offering a place to live, false if they are looking for one"
            },
            type = new
            {
                type = new[] { "string", "null" },
                description = "room, apartment, studio, house, or other; null if not mentioned"
            },
            price = new
            {
                type = new[] { "number", "null" },
                description = "monthly price or budget as a plain number; null if not mentioned"
            },
            currency = new
            {
                type = new[] { "string", "null" },
                description = "currency code such as EUR; null if not mentioned"
            },
            description = new
            {
                type = "string",
                description = "short English summary of the post"
            }
        }),
        ["required"] = JsonSerializer.SerializeToElement(new[]
        {
            "isOffering",
            "type",
            "price",
            "currency",
            "description"
        }),
        ["additionalProperties"] = JsonSerializer.SerializeToElement(false)
    };

    public async Task<ExtractedPost?> ExtractAsync(string postText)
    {
        var response = await client.Messages.Create(new MessageCreateParams
        {
            Model = _model,
            MaxTokens = _maxTokens,
            Messages =
            [
                new MessageParam
                {
                    Role = Role.User,
                    Content = 
                    $"""
                        Extract structured data from this Facebook housing group post:\n\n{postText}"
                    """
                }
            ],
            OutputConfig = new OutputConfig
            {
                Format = new JsonOutputFormat
                {
                    Schema = Schema
                }
            }
        });

        var json = response.Content
            .Select(b => b.Value)
            .OfType<TextBlock>()
            .FirstOrDefault()?.Text;
        if (json is null)
        {
            return null;
        }

        return JsonSerializer.Deserialize<ExtractedPost>(json, new JsonSerializerOptions
        {
            PropertyNameCaseInsensitive = true
        });
    }
}

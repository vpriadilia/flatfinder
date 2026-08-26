using System.Net.Http.Json;
using funcs.Abstractions;
using funcs.Models;

namespace funcs.Services;

public class TelegramNotifier(HttpClient httpClient) : INotifier
{
    private readonly string _botToken = Environment.GetEnvironmentVariable("TELEGRAM_BOT_TOKEN")!;
    private readonly string _chatId = Environment.GetEnvironmentVariable("TELEGRAM_CHAT_ID")!;

    private static readonly Dictionary<string, string> TypeLabelsUk = new(StringComparer.OrdinalIgnoreCase)
    {
        ["room"] = "кімната",
        ["apartment"] = "квартира",
        ["studio"] = "студія",
        ["house"] = "будинок",
        ["other"] = "інше"
    };

    public Task NotifyNewListingAsync(ExtractedPost extracted, string? link) =>
        SendMessageAsync(
            $"Тип: {ToUkrainianType(extracted.Type)}\n" +
            $"Ціна: {extracted.Price} {extracted.Currency}\n" +
            $"{extracted.Description}\n" +
            $"{link}");

    private static string ToUkrainianType(string? type) =>
        type is not null && TypeLabelsUk.TryGetValue(type, out var label) ? label : type ?? "не вказано";

    public async Task SendMessageAsync(string text)
    {
        var response = await httpClient.PostAsJsonAsync(
            $"https://api.telegram.org/bot{_botToken}/sendMessage",
            new { chat_id = _chatId, text });

        response.EnsureSuccessStatusCode();
    }
}

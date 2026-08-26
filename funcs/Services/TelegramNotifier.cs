using System.Net.Http.Json;
using funcs.Abstractions;
using funcs.Models;

namespace funcs.Services;

public class TelegramNotifier(HttpClient httpClient) : INotifier
{
    private readonly string _botToken = Environment.GetEnvironmentVariable("TELEGRAM_BOT_TOKEN")!;
    private readonly string _chatId = Environment.GetEnvironmentVariable("TELEGRAM_CHAT_ID")!;

    public Task NotifyNewListingAsync(ExtractedPost extracted, string? link) =>
        SendMessageAsync(
            $"Type: {extracted.Type}\n" +
            $"Price: {extracted.Price} {extracted.Currency}\n" +
            $"{extracted.Description}\n" +
            $"{link}");

    public async Task SendMessageAsync(string text)
    {
        var response = await httpClient.PostAsJsonAsync(
            $"https://api.telegram.org/bot{_botToken}/sendMessage",
            new { chat_id = _chatId, text });

        response.EnsureSuccessStatusCode();
    }
}

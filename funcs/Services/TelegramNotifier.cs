using System.Net.Http.Json;
using funcs.Abstractions;

namespace funcs.Services;

public class TelegramNotifier(HttpClient httpClient) : INotifier
{
    private readonly string _botToken = Environment.GetEnvironmentVariable("TELEGRAM_BOT_TOKEN")!;
    private readonly string _chatId = Environment.GetEnvironmentVariable("TELEGRAM_CHAT_ID")!;

    public async Task SendMessageAsync(string text)
    {
        var response = await httpClient.PostAsJsonAsync(
            $"https://api.telegram.org/bot{_botToken}/sendMessage",
            new { chat_id = _chatId, text });

        response.EnsureSuccessStatusCode();
    }
}

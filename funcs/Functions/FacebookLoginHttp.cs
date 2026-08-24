using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Playwright;

namespace funcs.Functions;

public class FacebookLoginHttp
{
    private readonly string _stateFilePath = Environment.GetEnvironmentVariable("FACEBOOK_STATE_FILE_PATH")!;

    [Function("FacebookLogin")]
    public async Task<IActionResult> Run(
        [HttpTrigger(AuthorizationLevel.Anonymous, "get")] HttpRequest req)
    {
        using var playwright = await Playwright.CreateAsync();
        await using var browser = await playwright.Chromium.LaunchAsync(
            new BrowserTypeLaunchOptions
            {
                Headless = false
            });

        var context = await browser.NewContextAsync();
        var page = await context.NewPageAsync();

        await page.GotoAsync("https://www.facebook.com/login");

        var tcs = new TaskCompletionSource();
        page.Close += (_, _) => tcs.TrySetResult();

        await tcs.Task;

        await context.StorageStateAsync(
            new BrowserContextStorageStateOptions
            {
                Path = _stateFilePath
            });

        return new OkObjectResult(
            $"Session state saved to {_stateFilePath}");
    }
}

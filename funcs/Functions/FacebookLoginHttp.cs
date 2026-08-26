using funcs.Abstractions;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Playwright;

namespace funcs.Functions;

public class FacebookLoginHttp(IFacebookSessionStateStore stateStore)
{
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

        var stateJson = await context.StorageStateAsync();
        await stateStore.SaveStateAsync(stateJson);

        return new OkObjectResult("Facebook session state saved to blob storage");
    }
}

using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace funcs.Functions;

public class ScrapperFacebook(
    ILogger<ScrapperFacebook> logger)
{
    [Function("ScrapperFacebook")]
    public void Run(
        [TimerTrigger("0 */5 * * * *")] 
        TimerInfo myTimer)
    {
        
    }
}
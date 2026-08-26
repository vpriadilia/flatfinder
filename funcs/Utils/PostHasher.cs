using System.Security.Cryptography;
using System.Text;

namespace funcs.Utils;

public static class PostHasher
{
    public static string Hash(string postText)
    {
        var bytes = SHA256.HashData(Encoding.UTF8.GetBytes(postText));
        return Convert.ToHexString(bytes);
    }
}

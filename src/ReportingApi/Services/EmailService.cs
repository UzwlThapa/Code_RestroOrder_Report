using MailKit.Net.Smtp;
using MailKit.Security;
using MimeKit;

namespace ReportingApi.Services;

public class EmailService
{
    private readonly IConfiguration _config;
    public EmailService(IConfiguration config) => _config = config;

    public async Task SendReportAsync(string toEmail, string subject, string body, byte[] attachment, string attachmentName)
    {
        var smtp = _config.GetSection("Smtp");
        var msg = new MimeMessage();
        msg.From.Add(MailboxAddress.Parse(smtp["FromAddress"]));
        msg.To.Add(MailboxAddress.Parse(toEmail));
        msg.Subject = subject;

        var builder = new BodyBuilder { TextBody = body };
        builder.Attachments.Add(attachmentName, attachment);
        msg.Body = builder.ToMessageBody();

        using var client = new SmtpClient();
        await client.ConnectAsync(smtp["Host"], int.Parse(smtp["Port"] ?? "587"), SecureSocketOptions.StartTls);
        await client.AuthenticateAsync(smtp["Username"], smtp["Password"]);
        await client.SendAsync(msg);
        await client.DisconnectAsync(true);
    }
}

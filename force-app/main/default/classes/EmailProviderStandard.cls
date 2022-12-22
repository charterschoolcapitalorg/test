public class EmailProviderStandard implements EmailProvider {
    public void sendEmail(List<Messaging.SingleEmailMessage> emails) {
        Messaging.sendEmail(emails);
    }
}
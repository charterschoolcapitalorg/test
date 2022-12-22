@isTest
public class EmailProviderMock implements EmailProvider {
    public List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

    public void sendEmail(List<Messaging.SingleEmailMessage> emails) {
        this.emails.addAll(emails);
    }
}
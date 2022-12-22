public interface EmailProvider {
    void sendEmail(List<Messaging.SingleEmailMessage> emails);
}
public class QueueableEmails implements Queueable {
    private static final Integer EMAIL_QUEUE_LIMIT = 50;

    private final List<QueueableEmail> queuedEmails;

    @testVisible
    private static EmailProvider emailSvc = new EmailProviderStandard();

    public QueueableEmails(List<QueueableEmail> queuedEmails) {
        this.queuedEmails = queuedEmails;
    }

    public void enqueueJob() {
        if (!this.queuedEmails.isEmpty()) {
            System.enqueueJob(this);
        }
    }

    public void execute(QueueableContext ctx) {
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        List<QueueableEmail> remainingEmails = new List<QueueableEmail>();

        for (QueueableEmail queuedEmail: queuedEmails) {
            if (emails.size() < EMAIL_QUEUE_LIMIT) {
                Messaging.SingleEmailMessage email = queuedEmail.render();
                emails.add(email);
            } else {
                remainingEmails.add(queuedEmail);
            }
        }

        emailSvc.sendEmail(emails);

        new QueueableEmails(remainingEmails).enqueueJob();
    }

    public interface QueueableEmail {
        Messaging.SingleEmailMessage render();
    }
}
@isTest
private class EmailProviderTest {
    @isTest
    private static void testSend() {
        Test.startTest();
        Integer invocationsBefore = Limits.getEmailInvocations();
        Messaging.SingleEmailMessage msg = new Messaging.SingleEmailMessage();
        msg.setTargetObjectId(UserInfo.getUserId());
        msg.setSubject('Test Email');
        msg.setPlainTextBody('Test Email');
        msg.setSaveAsActivity(false);
        new EmailProviderStandard().sendEmail(new List<Messaging.SingleEmailMessage> { msg });
        Integer invocationsAfter = Limits.getEmailInvocations();
        Test.stopTest();

        System.assertEquals(0, invocationsBefore);
        System.assertEquals(1, invocationsAfter);
    }
}
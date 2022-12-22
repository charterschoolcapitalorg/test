/* ============================================================
 * Contributor: Caleb Sidel
 * 
 * This code is part of the "apex-lang" open source project avaiable at:
 * 
 *      http://code.google.com/p/apex-lang/
 *
 * This code is licensed under the Apache License, Version 2.0.  You may obtain a 
 * copy of the License at:
 * 
 *      http://www.apache.org/licenses/LICENSE-2.0
 * ============================================================
 */
@IsTest
private class EmailUtilsTest {

    static testMethod void testsendEmail_test() {
        List<String> recepients=new String[]{'test@test.com','test2@test.com'};
        EmailUtils.sendTextEmail(recepients,'Test method', 'This is to test the sendTextNotificationEmail method');
        EmailUtils.sendHTMLEmail(recepients,'Test method', 'This is to test the sendTextNotificationEmail method');
    } 
    
    static testMethod void testsendEmailNoReceipients_test() {
        List<String> recepients=null;
        EmailUtils.sendTextEmail(recepients,'Test method', 'This is to test the sendTextNotificationEmail method');
        
        recepients=new List<String>();
        EmailUtils.sendHTMLEmail(recepients,'Test method', 'This is to test the sendTextNotificationEmail method');
    }
    
    static testMethod void testsendEmailWithAttachment_test() {
        List<String> recepients=new String[]{'test@test.com','test2@test.com'};
        List<Attachment> stdAttachments = new List<Attachment>();
        Attachment a = new Attachment();
        a.Name = 'Test';
        a.Body = EncodingUtil.base64Decode('Test Body');
        stdAttachments.add(a);
        EmailUtils.sendEmailWithStandardAttachments(recepients,'Test method', 'This is to test the sendTextNotificationEmail method',false,stdAttachments);
    }
    
    static testMethod void testsendEmailWithAttachmentIDs_test() {
        List<String> recepients=new String[]{'test@test.com','test2@test.com'};
        List<ID> stdAttachments = new List<ID>();
        
        Account acc = new Account(name='Test Foo__c');
        insert acc;
        
        Attachment a = new Attachment();
        a.ParentId = acc.Id;
        a.Name = 'Test';
        a.Body = EncodingUtil.base64Decode('Test Body');
        insert a;
        stdAttachments.add(a.Id);
        EmailUtils.sendEmailWithStandardAttachments(recepients,'Test method', 'This is to test the sendTextNotificationEmail method',false,stdAttachments);
    }

    private static testmethod void testIsNotValidEmailAddress(){
        //test:  global static Boolean isNotValidEmailAddress(String str)
        System.assertEquals(true,EmailUtils.isNotValidEmailAddress(null));
        System.assertEquals(true,EmailUtils.isNotValidEmailAddress('  '));
        System.assertEquals(true,EmailUtils.isNotValidEmailAddress('x'));
        System.assertEquals(true,EmailUtils.isNotValidEmailAddress('x@'));
        System.assertEquals(true,EmailUtils.isNotValidEmailAddress('x@x'));
        System.assertEquals(false,EmailUtils.isNotValidEmailAddress('x@x.x'));
    }


    private static testMethod void testSendSingleEmail(){
        Account a = new Account(Name = 'Test');
        insert a;
        Opportunity o = new Opportunity(Name = 'Test', StageName = 'Stage 1', CloseDate = Date.today(), AccountId = a.Id);
        insert o;
        Contact c1 = new Contact(FirstName = 'John', LastName = 'Caughie', Email = 'test1@example.com');
        insert c1;
        List<String> emails = new List<String>{'kirk@example.com', 'picard@example.com'};
        EmailTemplate template =  [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName = 'CSC_Client_Portal' LIMIT 1];
        EmailUtils.sendSingleEmailNotification(emails, template.Id, o.Id);        
    }

    private static testMethod void testsendUserHTMLEmail(){
        User u = [Select Id FROM User LIMIT 1];
        Integer emails = 0;
        Test.startTest();
            EmailUtils.sendUserHTMLEmail(u.Id, null, 'Test Subject', 'Test Body');
            emails = Limits.getEmailInvocations();
        Test.stopTest();
        System.assertEquals(1, emails, 'One email should have been sent');
    }
    
}
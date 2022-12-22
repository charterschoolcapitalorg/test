@isTest
private class TestSmartContactSearchExtension {

    static testMethod void myUnitTest() {
        ApexPages.StandardController sc;
        createData();
        SmartContactSearchExtension controller = new SmartContactSearchExtension(sc);
        controller.contactFirstNameToSearch = 'Test';
        controller.contactLastNameToSearch = 'TestLast';
        controller.contactEmail='TestLast@appiro.com';
        
       
        controller.performSearch();
        System.assert(55<=controller.searchCount);
        System.assertEquals(1,controller.showingFrom);
        System.assertEquals(20,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(false,controller.hasPrevious);
        
        controller.nextContactPage();
        System.assertEquals(21,controller.showingFrom);
        System.assertEquals(40,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        
        controller.previousContactPage();
        
        controller.requestedPage = '3';
        controller.requestedContactPage();
        System.assertEquals(41,controller.showingFrom);
        System.assertEquals(55,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(false,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        
        controller.sortData();
        controller.cancel();
        
        controller.requestedPage = '5';
        controller.requestedContactPage();
        
        controller.contactFirstNameToSearch = 'dert';
        controller.contactLastNameToSearch = 'wee';
        controller.performSearch();
        
        controller.contactEmail='TestLast';
        controller.performSearch();
    }
    static void CreateData() {
      Account acc = new Account();
           acc.Name = '00TestAccount0' ;
           acc.BillingCountry = 'Germany';
           insert acc;    
       list<Contact> cntList = new list<Contact>();
       for(Integer i=0;i<55;i++) {
           Contact cnt = new Contact();
           cnt.AccountID = acc.id;
           cnt.LastName='TestLast'+ i;
           cnt.FirstName='Test'+  i;
           cnt.MailingCountry = 'United States';
           cnt.MailingState = 'CA';
           cnt.email = 'TestLast@appiro.com';
           cntList.add(cnt);
       }
       
       insert cntList;
    }
}
@isTest
private class TestSmartLeadSearchExtension {

        static testMethod void myUnitTest() {
        ApexPages.StandardController sc;
        createData();
        SmartLeadSearchExtension controller = new SmartLeadSearchExtension(sc);
        controller.leadFirstNameToSearch = 'Test';
        controller.leadLastNameToSearch = 'TestLast';
        controller.leadEmail='TestLast@appiro.com';
        controller.performSearch();
        
        System.assert(55<=controller.searchCount);
        System.assertEquals(1,controller.showingFrom);
        System.assertEquals(20,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(false,controller.hasPrevious);
        
        controller.nextLeadPage();
        System.assertEquals(21,controller.showingFrom);
        System.assertEquals(40,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(true,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        
        controller.previousLeadPage();
        
        controller.requestedPage = '3';
        controller.requestedLeadPage();
        System.assertEquals(41,controller.showingFrom);
        System.assertEquals(55,controller.showingTo);
        System.assertEquals(3,controller.totalPage);
        System.assertEquals(false,controller.hasNext);
        System.assertEquals(true,controller.hasPrevious);
        
        controller.sortData();
        controller.cancel();
        
        controller.requestedPage = '5';
        controller.requestedLeadPage();
        
        controller.leadFirstNameToSearch = 'dert';
        controller.leadLastNameToSearch = 'wee';
        controller.performSearch();
        
        controller.leadEmail='TestLast';
        controller.performsearch();
    }
    
    
    static void CreateData() {
       list<Lead> leadList = new list<Lead>();
       for(Integer i=0;i<55;i++) {
           Lead leadObj = new Lead();
           leadObj.LastName='TestLast'+ i;
           leadObj.FirstName='Test'+  i;
           leadObj.email = 'TestLast@appiro.com';
           leadObj.Company='Company'+ i;
           leadList.add(leadObj);
       }
       insert leadList;
    }
}
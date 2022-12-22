/**
* @description Test Class for the ConductorFromListViewController Class
*/
@isTest
private class ConductorFromListViewControllerTest {
    /**
    * @description setup - test data setup method
    */
    @testSetup
    static void setup(){
        List<Account> testAccounts = new List<Account>();

        Account a = new Account();
        a.Name = 'ABC Company, Inc.';
        testAccounts.add(a);

        Account acct = new Account();
        acct.Name = 'XYZ Company, Inc.';
        testAccounts.add(acct);

        insert testAccounts;

        List<Redemption__c> testRedemptions = new List<Redemption__c>();

        for (Integer i = 0; i < 10; i++) {
            Redemption__c r = new Redemption__c();
            r.Date_Received__c = Date.today();
            r.Date_Cleared__c = Date.today();
            r.Amount_Received__c = 10000;
            if(Math.mod(i, 2) == 0){
                r.School__c = testAccounts[0].Id;
            } else {
                r.School__c = testAccounts[1].Id;
            }
            testRedemptions.add(r);
        }
        insert testRedemptions;

    }
    /**
    * @description testMethod1 - Test Happy Path of code
    */
    static testMethod void testMethod1() {
        List<sObject> reds = (List<Redemption__c>)[Select Id From Redemption__c];
        System.debug(reds);
        ApexPages.StandardSetController ssc = new ApexPages.StandardSetController(reds);
        ssc.setSelected(reds);
        ConductorFromListViewController cn = new ConductorFromListViewController(ssc);
        cn.prepareConductorUrl();
        Test.startTest();
        PageReference pr = cn.prepareConductorUrl();
        String fieldName = pr.getParameters().get('UrlFieldName');
        System.assertEquals('Conga_Conductor_Docs__c',fieldName, 'The UrlFieldName parameter is not set' );
        Test.stopTest();
    }  
}
/*=====================================================================
 * Charter School Capital, Inc
 * Name: CharterSummaryExtTests
 * Description: Test classes
 * Created Date: [04/20/2015]
 * Created By: [John Caughie]
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]               [FirstName LastName]         [Short description for changes]
 =====================================================================*/


@isTest
private class CharterSummaryExtTests {
    
    static testmethod void Test_CharterExtension() {

        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, School_Attendance__c, RPA__c, Terms_Letter__c, Program_Fee_c, Funded_Receivable__c');

        Account bop = createAccount('BOP');
        Account charter = createAccount('Charter');
        charter.Bop__c = bop.Id;
        update charter;
        Account school1 = createAccount('School1');
        school1.Charter_Holder__c = charter.Id;
        update school1;
        Account school2 = createAccount('School2');
        school2.Charter_Holder__c = charter.Id;
        update school2;

        RPA__c rpa = new RPA__c(Account__c = charter.Id);
        insert rpa;

        School_Attendance__c sa1 = new School_Attendance__c();
        sa1 = createSchoolAttendance(school1);
        sa1.Total_Attendance_manual__c = 500;
        update sa1;

        School_Attendance__c sa2 = new School_Attendance__c();
        sa2 = createSchoolAttendance(school2);
        sa2.Total_Attendance_manual__c = 500;
        update sa2;

        School_Attendance__c sa3 = new School_Attendance__c();
        sa3 = createSchoolAttendance(school1);
        sa3.Total_Attendance_manual__c = 500;
        sa3.Report_Date__c = date.today().addYears(-1);
        update sa3;

        School_Attendance__c sa4 = new School_Attendance__c();
        sa4 = createSchoolAttendance(school2);
        sa4.Total_Attendance_manual__c = 500;
        sa4.Report_Date__c = date.today().addYears(-1);
        update sa4;

        Funded_Receivable__c fr1 = new Funded_Receivable__c();
        fr1 = createFundedReceivables(charter, school1, rpa);

        Funded_Receivable__c fr2 = new Funded_Receivable__c();
        fr2 = createFundedReceivables(charter, school2, rpa);

        Test.startTest();
        ApexPages.StandardController stdController = new ApexPages.StandardController(charter);
        CharterSummaryExt charterExt = new CharterSummaryExt(stdController);
        String bopName = charterExt.getBop();
        List<AggregateResult> getSA = charterExt.getSchoolAtt();
        List<AggregateResult> getFRS= charterExt.getFundedRecSummary();
        List<AggregateResult> getCRS = charterExt.getCharterRecSummary();
        Test.stopTest();

        System.assertEquals((sa1.Total_Attendance_manual__c + sa2.Total_Attendance_manual__c), getSA[0].get('total'));
        System.assertEquals((sa3.Total_Attendance_manual__c + sa4.Total_Attendance_manual__c), getSA[1].get('total'));
        System.assertEquals((date.today().year()), getSA[0].get('yr')); 
        System.assertEquals((date.today().addYears(-1).year()), getSA[1].get('yr'));     
        System.assertEquals(bop.name, bopName);
        System.assertEquals(160000, getFRS[0].get('fv'));
        System.assertEquals(date.today().year(), getFRS[0].get('yr'));
        System.assertEquals(160000, getCRS[0].get('fv'));
        System.debug(getSA);
        System.debug(getFRS);
        System.debug(getCRS);

    }

    //helper to create necessary records
    private static Account createAccount(String accName){

        Account acc = new Account(name = accName);
        insert acc;
        return acc;

    }

    private static Funded_Receivable__c createFundedReceivables(Account charter, Account school, RPA__c rpa){
        
            Funded_Receivable__c fr = new Funded_Receivable__c(
                                        Charter_Holder__c = charter.Id,
                                        School__c = school.Id,
                                        Purchase_Date__c = date.today(),
                                        GRV_Amount__c = 100000.00,
                                        FV_Amount__c = 80000.00,
                                        Upfront_Purchase_Price__c = 75000.00,
                                        Max_Deferred_Purchase_Price__c = 20000.00,
                                        RPA__c = rpa.id
                                    );
            insert fr;
            system.debug('frs: ' + fr);
            return fr;
    
    }

    private static School_Attendance__c createSchoolAttendance(Account schAtt){
           
            School_Attendance__c attendance = new School_Attendance__c();
            attendance.School__c = schAtt.Id;
            attendance.Report_Date__c = date.today();
            attendance.Active__c = true;
            insert attendance;
            return attendance;

    }

}
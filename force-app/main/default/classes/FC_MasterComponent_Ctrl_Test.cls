@IsTest
private class FC_MasterComponent_Ctrl_Test {
   
    @testSetup static void FC_Details(){
        TestHelper.createCustomSettingToByPassTriggersAndRules('Account, CSC_Action_List__c, RPA__c, Opportunity, Opp_School__c');
        TestHelper.createSeedDataForTesting();
        Opportunity originalOpp = [SELECT Id, Name, RecordType.Name, AccountId, StageName, CloseDate, Amount FROM Opportunity];
        List<Opp_School__c> oppSchools = [SELECT Id, Name, Opportunity__c, School__c FROM Opp_School__c];
        FCFormUtils.createFCForms(originalOpp);
        // FCFormUtils.createFCDetails(oppSchools);
        // CSC_Action_List__c cal = new CSC_Action_List__c();
        // cal.Opportunity__c = originalOpp.Id;
        // insert cal;

        Opportunity newOpportunity = originalOpp.clone(false, false, false, false);
        newOpportunity.CloseDate = Date.today().addDays(3);
        newOpportunity.Interest_Rate__c = 3.00;
        insert newOpportunity;
        Opp_School__c newOppSchool = new Opp_School__c();
        newOppSchool.Opportunity__c = newOpportunity.Id;
        newOppSchool.School__c = oppSchools[0].School__c;
        insert newOppSchool;
        List<Opp_School__c> newOppSchools = [SELECT Id, Name, Opportunity__c, School__c FROM Opp_School__c];
        FCFormUtils.createFCForms(newOpportunity);
        FCFormUtils.createFCDetails(newOppSchools);


        //update FC Details on original opp
        List<FC_Details__c> details = [SELECT id, Name, Academic_Performance_Comments__c FROM FC_Details__c WHERE FC_Form__r.Opportunity__c =: originalOpp.Id];
        for(FC_Details__c fcd : details){
            fcd.Academic_Performance_Comments__c = 'original record';
            fcd.Current_Funding_Comments__c = 'original record';
        }
        update details;

        //update FC Forms on original opp
        List<FC_Form__c> forms = [SELECT id, Name, Underwriting_Review_Section_Comments__c FROM FC_Form__c WHERE Opportunity__c =: originalOpp.Id];
        for(FC_Form__c fcf : forms){
            fcf.Underwriting_Review_Section_Comments__c = 'original record';
        }
        update forms;

        originalOpp.StageName = 'Closed Won';
        originalOpp.Receivables_Purchased__c = true;
        originalOpp.Interest_Rate__c = 3.00;
        update originalOpp;

    }

    @isTest
    static void testGetDetailDataWarning(){
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE IsClosed = false];
        List<FC_Details__c> details = [SELECT id, Name, RecordType.DeveloperName FROM FC_Details__c WHERE FC_Form__r.Opportunity__c =: newOpp.Id];
        Test.startTest();
        for (FC_Details__c fcd : details) {
            String warning = (FC_MasterComponent_Ctrl.getDataWarnings(fcd.Id));
            System.assertEquals(true, warning.startsWith('WARNING:  The following fields will be updated - '), 'Wrong message returned');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetUnderwritingDetailDataWarning(){
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE IsClosed = false];
        FC_Details__c detail = [SELECT id, Name, RecordType.DeveloperName FROM FC_Details__c WHERE FC_Form__r.Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting' LIMIT 1];
        Test.startTest();
            String warning = (FC_MasterComponent_Ctrl.getDataWarnings(detail.Id));
            System.assertEquals(warning, 'WARNING:  The following fields will be updated - School Name, Charter Term, School Open Date, Enrollment Cap By Site, First Day of School this Academic Year, Grades Served, Lease Term, Authorizer, Academic Performance, Academic Performance Comments, Charter Good Standing, EWS Level, Concerning Google Alert, Indication of Closure, Management Changes in the Last Year', 'Wrong message returned');
        Test.stopTest();
    }

    @isTest
    static void testGetFormDataWarning(){
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE IsClosed = false];
        List<FC_Form__c> forms = [SELECT id, Name, RecordType.DeveloperName FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id];
        Test.startTest();
        for (FC_Form__c fcf : forms) {
            String warning = (FC_MasterComponent_Ctrl.getDataWarnings(fcf.Id));
            System.assertEquals(true, warning.startsWith('WARNING:  The following fields will be updated - '), 'Wrong message returned');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetFinanceFormCommentWarning(){
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE IsClosed = false];
        FC_Form__c form = [SELECT id, Name, RecordType.DeveloperName FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Finance' LIMIT 1];
        Test.startTest();
            String warning = (FC_MasterComponent_Ctrl.getCommentWarnings(form.Id));
            System.assertEquals(warning, 'WARNING:  The following fields will be updated - Oustanding Info Needed For Funding - FIN, Current Funding Comments, Financial Review Comments, State Specific Finance Comments, Current Year Surplus/Deficit, Net Assets, Indebtedness, Funding Plan, Audit Findings', 'Wrong message returned');
        Test.stopTest();
    }

    @isTest
    static void testGetDetailCommentWarning(){
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE IsClosed = false LIMIT 1];
        List<FC_Details__c> details = [SELECT id, Name, RecordType.DeveloperName FROM FC_Details__c WHERE FC_Form__r.Opportunity__c =: newOpp.Id];
        Test.startTest();
        for (FC_Details__c fcd : details) {
            String warning = (FC_MasterComponent_Ctrl.getCommentWarnings(fcd.Id));
            System.assertEquals(true, warning.startsWith('WARNING:  The following fields will be updated - '), 'Wrong message returned');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetFormCommentWarning(){
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE IsClosed = false];
        List<FC_Form__c> forms = [SELECT id, Name, RecordType.DeveloperName FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id];
        Test.startTest();
        for (FC_Form__c fcf : forms) {
            String warning = (FC_MasterComponent_Ctrl.getCommentWarnings(fcf.Id));
            System.assertEquals(true, warning.startsWith('WARNING:  The following fields will be updated - '), 'Wrong message returned');
        }
        Test.stopTest();
    }

    @isTest
    static void testGetUnderwritingDetailCommentRefresh(){
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE IsClosed = false];
        List<FC_Details__c> details = [SELECT id, Name, RecordType.DeveloperName, Academic_Performance_Comments__c FROM FC_Details__c WHERE FC_Form__r.Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
        Test.startTest();
        for (FC_Details__c fcd : details) {
            System.assertEquals(null, fcd.Academic_Performance_Comments__c, 'Wrong message returned');
            FC_MasterComponent_Ctrl.refreshComments(fcd.Id);
        }
        Test.stopTest();
    }

    @isTest
    static void testGetFinanceDetailCommentRefresh(){
        Opportunity newOpp = [SELECT Id, Name FROM Opportunity WHERE IsClosed = false];
        List<FC_Details__c> details = [SELECT id, Name, RecordType.DeveloperName, Current_Funding_Comments__c FROM FC_Details__c WHERE FC_Form__r.Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Finance'];
        Test.startTest();
        for (FC_Details__c fcd : details) {
            System.assertEquals(null, fcd.Current_Funding_Comments__c, 'Wrong message returned');
            FC_MasterComponent_Ctrl.refreshComments(fcd.Id);
        }
        details = [SELECT id, Name, RecordType.DeveloperName, Current_Funding_Comments__c FROM FC_Details__c WHERE FC_Form__r.Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Finance'];
        for (FC_Details__c fcd : details) {
            System.assertEquals('original record', fcd.Current_Funding_Comments__c, 'Wrong message returned');
        }  
        Test.stopTest();
    }

    @isTest
    static void testGetFinanceFormDataRefresh(){
        Opportunity newOpp = [SELECT Id, Name, Interest_Rate__c FROM Opportunity WHERE IsClosed = false];
        List<FC_Form__c> forms = [SELECT id, Name, RecordType.DeveloperName, Interest_Rate__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Finance'];
        newOpp.Interest_Rate__c = 5;
        update newOpp;
        Test.startTest();
            for (FC_Form__c fcf : forms) {
                System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
                FC_MasterComponent_Ctrl.refreshData(fcf.Id);
            }
            forms = [SELECT id, Name, RecordType.DeveloperName, Interest_Rate__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Finance'];
            for (FC_Form__c fcf : forms) {
                System.assertEquals(5, fcf.Interest_Rate__c, 'Wrong value returned');
            }  
        Test.stopTest();
    }    

    @isTest
    static void testGetUnderwritingFormDataRefresh(){
        Opportunity newOpp = [SELECT Id, Name, Interest_Rate__c FROM Opportunity WHERE IsClosed = false];
        List<FC_Form__c> forms = [SELECT id, Name, RecordType.DeveloperName, UCC_Search_Results__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
        //school Date_Opened__c
        for (FC_Form__c fcf : forms) {
            // System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
            fcf.UCC_Search_Results__c = 'something in here';
        }
        update forms;        

        Test.startTest();
            for (FC_Form__c fcf : forms) {
                // System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
                System.assertEquals('something in here', fcf.UCC_Search_Results__c, 'Wrong value returned');
                FC_MasterComponent_Ctrl.refreshData(fcf.Id);
            }
            forms = [SELECT id, Name, RecordType.DeveloperName, UCC_Search_Results__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
            for (FC_Form__c fcf : forms) {
                System.assertEquals('N/A', fcf.UCC_Search_Results__c, 'Wrong value returned');
            }  
        Test.stopTest();
    }    
    

    @isTest
    static void testGetUnderwritingFormCommentsRefresh(){
        Opportunity newOpp = [SELECT Id, Name, Interest_Rate__c FROM Opportunity WHERE IsClosed = false];
        List<FC_Form__c> forms = [SELECT id, Name, RecordType.DeveloperName, Underwriting_Review_Section_Comments__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
        //school Date_Opened__c
        for (FC_Form__c fcf : forms) {
            // System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
            System.debug('*****form***** ' + fcf);
            fcf.Underwriting_Review_Section_Comments__c = 'I put something here!';
        }
        update forms;        

        Test.startTest();
            for (FC_Form__c fcf : forms) {
                // System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
                System.assertEquals('I put something here!', fcf.Underwriting_Review_Section_Comments__c, 'Wrong value returned');
                FC_MasterComponent_Ctrl.refreshComments(fcf.Id);
            }

            forms = [SELECT id, Name, RecordType.DeveloperName, Underwriting_Review_Section_Comments__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
            for (FC_Form__c fcf : forms) {
                System.debug('*****form***** ' + fcf);
                System.assertEquals('original record', fcf.Underwriting_Review_Section_Comments__c, 'Wrong value returned');
            }
            Test.stopTest();
    }    
    
    @isTest
    static void testGetUnderwritingFormCommentsRefresh2(){
        Opportunity newOpp = [SELECT Id, Name, Interest_Rate__c FROM Opportunity WHERE IsClosed = false];
        List<FC_Form__c> forms = [SELECT id, Name, RecordType.DeveloperName, Underwriting_Review_Section_Comments__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
        //school Date_Opened__c
        for (FC_Form__c fcf : forms) {
            // System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
            System.debug('*****form***** ' + fcf);
            fcf.Underwriting_Review_Section_Comments__c = 'I put something here!';
        }
        
        Id FinanceFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Finance').getRecordTypeId();
        forms[0].Recordtypeid = FinanceFcRecType;
        update forms;        

        Test.startTest();
            for (FC_Form__c fcf : forms) {
                // System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
                System.assertEquals('I put something here!', fcf.Underwriting_Review_Section_Comments__c, 'Wrong value returned');
                FC_MasterComponent_Ctrl.refreshComments(fcf.Id);
            }

            forms = [SELECT id, Name, RecordType.DeveloperName, Underwriting_Review_Section_Comments__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
            for (FC_Form__c fcf : forms) {
                System.debug('*****form***** ' + fcf);
                System.assertEquals('original record', fcf.Underwriting_Review_Section_Comments__c, 'Wrong value returned');
            }
            Test.stopTest();
    }    
    
    @isTest
    static void testGetUnderwritingFormCommentsRefresh3(){
        Opportunity newOpp = [SELECT Id, Name, Interest_Rate__c FROM Opportunity WHERE IsClosed = false];
        List<FC_Form__c> forms = [SELECT id, Name, RecordType.DeveloperName, Underwriting_Review_Section_Comments__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
        //school Date_Opened__c
        for (FC_Form__c fcf : forms) {
            // System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
            System.debug('*****form***** ' + fcf);
            fcf.Underwriting_Review_Section_Comments__c = 'I put something here!';
        }
        
        Id ServicingFcRecType = Schema.SObjectType.FC_Form__c.getRecordTypeInfosByDeveloperName().get('Servicing').getRecordTypeId();
        forms[0].Recordtypeid = ServicingFcRecType;
        update forms;        

        Test.startTest();
            for (FC_Form__c fcf : forms) {
                // System.assertEquals(null, fcf.Interest_Rate__c, 'Wrong value returned');
                System.assertEquals('I put something here!', fcf.Underwriting_Review_Section_Comments__c, 'Wrong value returned');
                FC_MasterComponent_Ctrl.refreshComments(fcf.Id);
            }

            forms = [SELECT id, Name, RecordType.DeveloperName, Underwriting_Review_Section_Comments__c FROM FC_Form__c WHERE Opportunity__c =: newOpp.Id AND RecordType.DeveloperName = 'Underwriting'];
            for (FC_Form__c fcf : forms) {
                System.debug('*****form***** ' + fcf);
                System.assertEquals('original record', fcf.Underwriting_Review_Section_Comments__c, 'Wrong value returned');
            }
            Test.stopTest();
    }    
    
}
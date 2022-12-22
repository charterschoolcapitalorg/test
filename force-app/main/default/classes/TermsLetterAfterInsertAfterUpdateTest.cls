/**=====================================================================
 * Name: TermsLetterManagerTest
 * Description: Test Class for Terms Letter Manager TL Update
 * Created Date: [06/17/2015]
 * Created By: [John Caughie]
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]               [FirstName LastName]         [Short description for changes]
 =====================================================================*/
@isTest
private class TermsLetterAfterInsertAfterUpdateTest {
        
        //test single PF - dates should update
        static testMethod void test_method_OnePF() {
                
            System.debug('******************* Single ***************************'); 
            //Call helper
            Terms_Letter__c origTL = createRecords(1);

            //Requery Terms Letter
            Terms_Letter__c tl = [SELECT Id, Termination_Date__c, Initial_Close_Date__c, Count_of_Program_Fees__c, Status__c FROM Terms_Letter__c WHERE id =: origTL.id];

            //Change TL Dates           
            tl.Status__c = 'Active';
            tl.Termination_Date__c = Date.today();
            tl.Initial_Close_Date__c = Date.today() - 25;

            //Update TL & activate trigger
            Test.startTest();
            update tl;
            Test.stopTest();
            System.debug('single tl after: ' + tl);

            //Query PF after date update on Terms Letter
            Program_Fee__c pfAfter = [SELECT Id, Start_Date__c, End_Date__c FROM Program_Fee__c WHERE Terms_Letter__c =: origTL.Id];
            System.debug('single pf: ' + pfAfter);

            //Verify PF Dates changed
            System.assert(tl.Initial_Close_Date__c == pfAfter.Start_Date__c);
            System.assert(tl.Termination_Date__c == pfAfter.End_Date__c);

        }

        //test multiple PFs - dates shouldn't update
        static testMethod void test_method_MultiplePFs() {

            System.debug('******************* Multi ***************************');  
            //Call helper
            Integer numRecords = 2;
            Terms_Letter__c origTL = createRecords(numRecords);

            //Requery Terms Letter
            Terms_Letter__c tl = [SELECT Id, Termination_Date__c, Initial_Close_Date__c, Count_of_Program_Fees__c, Status__c FROM Terms_Letter__c WHERE id =: origTL.id];

            //Change TL Dates
            tl.Status__c = 'Active';
            tl.Termination_Date__c = Date.today() + 37;
            tl.Initial_Close_Date__c = Date.today() - 26;

            //Update TL & activate trigger
            Test.startTest();
            update tl;
            Test.stopTest();
            System.debug('multi tl after: ' + tl);

            //Query PFs after date update on Terms Letter
            System.debug(tl.id);
            list<Program_Fee__c> listPFsAfter = new list<Program_Fee__c>([SELECT Id, Start_Date__c, End_Date__c FROM Program_Fee__c WHERE Terms_Letter__c =: origTL.id]);

            System.debug('multi after: ' + listPFsAfter);

            for(Integer i = 0; i < numRecords; i++){

                System.assert(tl.Initial_Close_Date__c != listPFsAfter[i].Start_Date__c);
                System.assert(tl.Termination_Date__c != listPFsAfter[i].End_Date__c);
            
                }
        }

        //Helper to create Account, RPA & TL
        private static Terms_Letter__c createRecords(Integer numberPFs){

            //create Account
            Account charter = new Account(
                Name = 'Unit Test Charter Holder',
                RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id
            );
            insert charter;

            //Create RPA
            RPA__c rpa = TestHelper.createRPA(charter.Id);
            rpa.Status__c = 'Draft';
            insert rpa;
            System.debug('rpa: ' + rpa);

            //Create TL
            Terms_Letter__c tl = TestHelper.createTermsLetter(charter.Id, rpa.Id);

            //TestHelper.createTermsLetter(charter.Id, rpa.Id);
            insert tl;

            list<Program_Fee__c> listPFs = new list<Program_Fee__c>();
                for(Integer j = 0; j < numberPFs; j++){
                    listPFs.add(TestHelper.createProgramFee(tl.Id));
                }
            System.debug('helper before: ' + listPFs);
            insert listPFs;
            return tl;

        }
}
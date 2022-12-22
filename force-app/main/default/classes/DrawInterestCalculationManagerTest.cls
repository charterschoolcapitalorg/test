/**=====================================================================
 * Appirio, Inc
 * Name: DrawInterestCalculationManagerTest
 * Description: Test class for DrawInterestCalculationManager T-286178
 * Created Date: 06/15/2014
 * Created By: Manisha Gupta (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 * [07/02/2014]                [Rajeev Arya]              [T-291633 - Modify Draw Entry Interest calc for rate change]
 =====================================================================*/
@isTest
private class DrawInterestCalculationManagerTest {
	//Test Method verifies the conditional logic when OldDrawEntry is Not null
    static testMethod void verifyCreateDrawEntry(){
        List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test@testclass.com',
                               email = 'test@testclass.com',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'
                                );
        insert usrRec;
        system.runAs(usrRec){
	        test.startTest();

			State_Province__c opState = new State_Province__c();
			opState.Name = 'Test';
			insert opState;

	        Draw_Note__c drawNote = new Draw_Note__c();
	        Draw_Entry__c oldDrawEntry = new Draw_Entry__c();
	        Payment__c payment = new Payment__c();

	        drawNote.Borrow_Date__c = date.parse('1/12/2013');
	        drawNote.Note_Rate__c = 2;
	        drawNote.Operating_State__c = opState.Id;
	        insert drawNote;

	        oldDrawEntry.Principal__c = 2000.00;
	        oldDrawEntry.Activity_Date__c = date.parse('1/12/2014');
	        oldDrawEntry.Draw_Note__c = drawNote.Id;
	        oldDrawEntry.Ending_Principal__c= 1000.00;
	        oldDrawEntry.Interest_Fwd__c = 8.00;

	        insert oldDrawEntry;
	        Draw_Entry__c newDrawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, oldDrawEntry, null, Date.today());
	        system.assertEquals(newDrawEntry.Principal__c, oldDrawEntry.Ending_Principal__c);
	        system.assertEquals(newDrawEntry.Draw_Note__c, drawNote.Id);
	        test.stopTest();
        }


    }


    //Test Method verifies the conditional logic when OldDrawEntry is null

    static testMethod void verifyCreateDrawEntryConditional(){
        List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test@testclass.com',
                               email = 'test@testclass.com',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'

                                );
        insert usrRec;
        system.runAs(usrRec){
	        test.startTest();

			State_Province__c opState = new State_Province__c();
			opState.Name = 'Test';
			insert opState;

	        Draw_Note__c drawNote = new Draw_Note__c();
	        Draw_Entry__c oldDrawEntry = new Draw_Entry__c();
	        Payment__c payment = new Payment__c();

	        drawNote.Borrow_Date__c = date.parse('1/12/2013');
	        //drawNote.Note_Rate__c = 2;
	        //drawNote.Total_Amount_Borrowed__c = 5000;
	        drawNote.Operating_State__c = opState.Id;

	        insert drawNote;

	        Draw_Entry__c newDrawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, null, null, Date.today());
	        system.assertEquals(newDrawEntry, null);
	        test.stopTest();
        }

    }



    //Test Method verifies the conditional logic when Payment object is not null
    static testMethod void verifyCreateDrawEntryConditionalPayment(){
        List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test@testclass.com',
                               email = 'test@testclass.com',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'
                                );

        insert usrRec;
        system.runAs(usrRec){
	        test.startTest();

			State_Province__c opState = new State_Province__c();
			opState.Name = 'Test';
			insert opState;

	        Draw_Note__c drawNote = new Draw_Note__c();
	        Draw_Entry__c oldDrawEntry = new Draw_Entry__c();
	        Payment__c payment = new Payment__c();

	        drawNote.Borrow_Date__c = date.parse('1/12/2014');
	        drawNote.Note_Rate__c = 2;
	        //drawNote.Total_Amount_Borrowed__c = 5000;
	        drawNote.Operating_State__c = opState.Id;
	        insert drawNote;

	        payment.Payment_Amount__c =1000.00;
	        payment.Draw_Note__c = drawNote.Id;

	        Draw_Entry__c newDrawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, null, payment, Date.today());
	        system.assertEquals(newDrawEntry, null);

	        test.stopTest();
        }

    }

    static testMethod void verifyCreateDrawEntryConditionalEntryPayment(){
        List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test@testclass.com',
                               email = 'test@testclass.com',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'
                                );
        insert usrRec;
        system.runAs(usrRec){
	        test.startTest();

			State_Province__c opState = new State_Province__c();
			opState.Name = 'Test';
			insert opState;

	        Draw_Note__c drawNote = new Draw_Note__c();
	        Draw_Entry__c oldDrawEntry = new Draw_Entry__c();
	        Payment__c payment = new Payment__c();

	        drawNote.Borrow_Date__c = date.parse('1/12/2013');
	        drawNote.Note_Rate__c = 2;
	        //drawNote.Total_Amount_Borrowed__c = 5000;
	        drawNote.Operating_State__c = opState.Id;
	        insert drawNote;

	        oldDrawEntry.Principal__c = 2.00;
	        oldDrawEntry.Activity_Date__c = date.parse('1/12/2014');
	        oldDrawEntry.Draw_Note__c = drawNote.Id;
	        oldDrawEntry.Ending_Principal__c= 1000.00;
	        oldDrawEntry.Interest_Fwd__c = 8.00;

	        insert oldDrawEntry;


	        payment.Payment_Amount__c =2.00;
	        payment.Draw_Note__c = drawNote.Id;

	        Draw_Entry__c newDrawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, oldDrawEntry, payment, Date.today());
	        system.assertEquals(newDrawEntry.Principal_paid__c, 0.0);
	        test.stopTest();
        }

    }

    static testMethod void verifyCreateDrawEntryNoData(){
        List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test@testclass.com',
                               email = 'test@testclass.com',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'
                                );
        insert usrRec;
        system.runAs(usrRec){
	        test.startTest();

			State_Province__c opState = new State_Province__c();
			opState.Name = 'Test';
			insert opState;

	        Draw_Note__c drawNote = new Draw_Note__c();
	        Draw_Entry__c oldDrawEntry = new Draw_Entry__c();
	        Payment__c payment = new Payment__c();
			drawNote.Operating_State__c = opState.Id;
	        insert drawNote;

	        oldDrawEntry.Draw_Note__c = drawNote.Id;

	        insert oldDrawEntry;
	        system.debug('++++++ Old Entry activity date '+ oldDrawEntry.Activity_Date__c);
	        Draw_Entry__c newDrawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, oldDrawEntry, null, Date.today());
	        test.stopTest();
        }

    }




    static testMethod void verifyCreateDrawEntryConditionalNegative(){
        List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test@testclass.com',
                               email = 'test@testclass.com',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'
                                );
        insert usrRec;
        system.runAs(usrRec){
	        test.startTest();

			State_Province__c opState = new State_Province__c();
			opState.Name = 'Test';
			insert opState;

	        Draw_Note__c drawNote = new Draw_Note__c();
	        Draw_Entry__c oldDrawEntry = new Draw_Entry__c();
	        Payment__c payment = new Payment__c();

	        drawNote.Borrow_Date__c = date.parse('1/12/2013');
	        drawNote.Note_Rate__c = 0;
	        //drawNote.Total_Amount_Borrowed__c = 5000;
	        drawNote.Operating_State__c = opState.Id;
	        insert drawNote;

	        oldDrawEntry.Principal__c = 2.00;
	        oldDrawEntry.Activity_Date__c = date.parse('1/12/2014');
	        oldDrawEntry.Draw_Note__c = drawNote.Id;
	        oldDrawEntry.Ending_Principal__c= 1000.00;
	        oldDrawEntry.Interest_Fwd__c = 8.00;

	        insert oldDrawEntry;


	        payment.Payment_Amount__c =2.00;
	        payment.Draw_Note__c = drawNote.Id;

	        Draw_Entry__c newDrawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, oldDrawEntry, payment, Date.today());
	        system.assertEquals(newDrawEntry.Accrued_Interest__c,0);
	        test.stopTest();
        }
    }


        //Test with -negative value
        static testMethod void verifyCreateDrawEntryConditionalNegative1(){
        List<User> userList = new List<User>();
        List<Id> userIds = new List<Id>();
        Profile p = [select id from profile where Name = :'Standard User' limit 1];

        User usrRec = new User(profileId = p.id, username = 'test@testclass.com',
                               email = 'test@testclass.com',
                               emailencodingkey = 'UTF-8', localesidkey = 'en_US',
                               languagelocalekey = 'en_US', timezonesidkey = 'America/Los_Angeles',
                               alias='test', firstname='test', lastname='User'
                                );
        insert usrRec;
        system.runAs(usrRec){
	        test.startTest();

			State_Province__c opState = new State_Province__c();
			opState.Name = 'Test';
			insert opState;

	        Draw_Note__c drawNote = new Draw_Note__c();
	        Draw_Entry__c oldDrawEntry = new Draw_Entry__c();
	        Payment__c payment = new Payment__c();

	        drawNote.Borrow_Date__c = date.parse('1/12/2013');
	        drawNote.Note_Rate__c = -20;
	        //drawNote.Total_Amount_Borrowed__c = 5000;
	        drawNote.Operating_State__c = opState.Id;
	        insert drawNote;

	        oldDrawEntry.Principal__c = 2.00;
	        oldDrawEntry.Activity_Date__c = date.parse('1/12/2014');
	        oldDrawEntry.Draw_Note__c = drawNote.Id;
	        oldDrawEntry.Ending_Principal__c= 1000.00;
	        oldDrawEntry.Interest_Fwd__c = 8.00;

	        insert oldDrawEntry;


	        payment.Payment_Amount__c =2.00;
	        payment.Draw_Note__c = drawNote.Id;

	        Draw_Entry__c newDrawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, oldDrawEntry, payment, Date.today());
	        system.assertNotEquals(newDrawEntry.Accrued_Interest__c,0);
	        test.stopTest();
        }
    }
}
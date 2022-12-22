@isTest
public class SendSubmissionNeededEmailsSchedTests {
	//SendSubmissionNeededEmails HAS BEEN DEPRECATED
	
	/*
	@testSetup static void setup() {
        //Create Account
        Account acc = new Account(name='Test Email Account');
        insert acc;

        //Create Contacts
        List<Contact> cons = new List<Contact>();
        for(Integer i = 1; i <= 5; i++){
        	cons.add(new Contact(firstName = 'Bob', lastName = 'Contact ' + i, AccountId = acc.Id, email = 'test' + i + '@charterschoolcapital.com'));
        }
        insert cons;
        
        //Create Opps
        List<Opportunity> opps = new List<Opportunity>();
        for(Integer i = 1; i <= 5; i++){
        	Opportunity o = new Opportunity();
        	o.Name = 'Test Opp ' + i;
        	o.AccountId = acc.Id;
        	o.RecordTypeId = RecordTypeUtils.OpportunityFOF.Id;
        	o.StageName = 'Stage 3 - Review';
        	o.CloseDate = Date.today().addDays(7);
        	opps.add(o);
        }
        insert opps;

		//Create Users
        User thisUser = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
 
		System.runAs ( thisUser ) {
			UserRole ur = [SELECT PortalType, PortalAccountId FROM UserRole WHERE PortalType = 'Partner' LIMIT 1];
			Profile p = [SELECT Id, Name FROM Profile WHERE UserType = 'PowerPartner' LIMIT 1];
			List<User> users = new List<User>();
 
			for(Contact c : cons){
				User newUser = new User(
					profileId = p.id,
					username = c.Email,
					email = c.Email,
					emailencodingkey = 'UTF-8',
					localesidkey = 'en_US',
					languagelocalekey = 'en_US',
					timezonesidkey = 'America/Los_Angeles',
					alias = c.lastName.remove(' '),
					lastname = c.lastName,
					contactId = c.id
				);
				users.add(newUser);
				System.debug('New User ' + newUser);
			}

			insert users;  
		}

        //Create Community Contact Roles
        List<Community_Contact_Role__c> ccrs = new List<Community_Contact_Role__c>();
        for(Opportunity o : opps){
	        for(Contact c : cons){
	        	Community_Contact_Role__c ccr = new Community_Contact_Role__c();
	        	ccr.Contact__c = c.Id;
	        	ccr.Role__c = 'School';
	        	ccr.Opportunity__c = o.Id;
	        	ccrs.add(ccr);
        	}
        }
        insert ccrs;

        //Create Client Portal Items
        List<Intake_Item__c> portalItems = new List<Intake_Item__c>();
        for(Opportunity o : opps){
        	Intake_Item__c ii = new Intake_Item__c();
        	ii.Name = 'Submission of all Underwriting Documents';
        	ii.Due_Date__c = DateUtilities.getNextBusinessDay(Date.today());
        	ii.Status__c = 'Action Required';
        	ii.Assigned_To__c = 'School';
        	ii.Opportunity__c = o.Id;
        	ii.Is_Visible_To_Community__c = true;
        	portalItems.add(ii);
        }
        insert portalItems;

    }

    @isTest static void testSchedule(){
    	SendSubmissionNeededEmailsSched sched = new SendSubmissionNeededEmailsSched();

    	Test.startTest();
    		sched.execute(null);
    	Test.stopTest();
    	System.debug('After ' + SendSubmissionNeededEmails.emailLimits);
    	System.assertEquals(SendSubmissionNeededEmails.emailLimits, 1, 'An email scheduled batch should have been sent');

    }

    @isTest static void testBatch(){
    	SendSubmissionNeededEmails bch = new SendSubmissionNeededEmails();

    	Test.startTest();
    		Database.executeBatch(bch);
    	Test.stopTest();
    	System.debug('After ' + SendSubmissionNeededEmails.emailLimits);
    	System.assertEquals(SendSubmissionNeededEmails.emailLimits, 1, 'An email batch should have been sent');

    }

    @isTest static void testNothingDue(){
    	SendSubmissionNeededEmails bch = new SendSubmissionNeededEmails();

    	List<Intake_Item__c> portalItems = new List<Intake_Item__c>();
    	portalItems = [SELECT ID, Due_Date__c FROM Intake_Item__c];
    	for(Intake_Item__c ii : portalItems){
    		ii.Due_Date__c = Date.today().addDays(12);
    	}
    	update portalItems;

    	Test.startTest();
    		Database.executeBatch(bch);
    	Test.stopTest();
    	System.debug('After ' + SendSubmissionNeededEmails.emailLimits);
    	System.assertEquals(SendSubmissionNeededEmails.emailLimits, null, 'No items due');

    }

    @isTest static void testNothingActive(){
    	SendSubmissionNeededEmails bch = new SendSubmissionNeededEmails();

    	List<Intake_Item__c> portalItems = new List<Intake_Item__c>();
    	portalItems = [SELECT ID, Status__c FROM Intake_Item__c];
    	for(Intake_Item__c ii : portalItems){
    		ii.Status__c = 'Accepted';
    	}
    	update portalItems;

    	Test.startTest();
    		Database.executeBatch(bch);
    	Test.stopTest();
    	System.debug('After ' + SendSubmissionNeededEmails.emailLimits);
    	System.assertEquals(SendSubmissionNeededEmails.emailLimits, null, 'No items due');

    }

    @isTest static void testNotOnWhiteboard(){
    	SendSubmissionNeededEmails bch = new SendSubmissionNeededEmails();

    	List<Opportunity> opps = new List<Opportunity>();
    	opps = [SELECT ID, StageName FROM Opportunity];
    	for(Opportunity o : opps){
    		o.StageName = 'Stage 1 - Projected';
    	}
    	update opps;

    	Test.startTest();
    		Database.executeBatch(bch);
    	Test.stopTest();
    	System.debug('After ' + SendSubmissionNeededEmails.emailLimits);
    	System.assertEquals(SendSubmissionNeededEmails.emailLimits, null, 'No items due');

    }

    @isTest static void testAllWon(){
    	SendSubmissionNeededEmails bch = new SendSubmissionNeededEmails();

    	List<Opportunity> opps = new List<Opportunity>();
    	opps = [SELECT ID, StageName FROM Opportunity];
    	for(Opportunity o : opps){
    		o.StageName = 'Closed Won';
    	}
    	update opps;

    	Test.startTest();
    		Database.executeBatch(bch);
    	Test.stopTest();
    	System.debug('After ' + SendSubmissionNeededEmails.emailLimits);
    	System.assertEquals(SendSubmissionNeededEmails.emailLimits, null, 'No items due');

    }
	*/
}
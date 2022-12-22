@isTest public class TestFacilities {
	
	@testSetup public static void facSetup() {
		TestDiligenceUtils.createStates();
		
		State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
		
		Account a = new Account(name='test ch', recordtypeid = RecordTypes.IDCharterAccount, operating_state__c=s.Id);
        insert a;
        Account a2 = new Account(name='test school', ParentId=a.Id,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
        insert a2;    
		Account prop = new Account(name='test property',recordtypeid = RecordTypes.IDPropAccount, operating_state__c=s.Id);
        insert prop;    
		
		
		Contact c = new Contact();
		c.firstname = 'test';
		c.lastname = 'test';
		c.email = 't@t.com';
		insert c;
		
		List<Related_Contact__c> rcs = new List<Related_Contact__c>();
		rcs.add(new Related_Contact__c(account__c=a2.Id,Contact__c=c.Id,Financial_Contact__c=true, Facilities_Contact__c=true ));
		rcs.add(new Related_Contact__c(account__c=a.Id,Contact__c=c.Id,Financial_Contact__c=true, Facilities_Contact__c=true ));
		insert rcs;		
		
		Tenant__c te = new Tenant__c();
		te.tenant__c = a.Id;
		insert te;
		
		Lease__c lease = new Lease__c();
		lease.Property__c = prop.Id;
		lease.Tenant__c = te.Id;
		lease.Account__c = a.Id;
		
		insert lease;
		lease.Lease_Facilities_Contact__c = c.Id;
		lease.Lease_Financial_Contact__c = c.Id;
		update lease;
		
		ID expired = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Expired').getRecordTypeId();
	    ID pending = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Pending').getRecordTypeId();
	    ID current = Schema.SObjectType.Lease_Compliance__c.getRecordTypeInfosByName().get('Current').getRecordTypeId();
	        
        
		Lease_Compliance_Template__c t = new Lease_Compliance_Template__c();
		t.Due_Days__c = 2;
		t.Client_Alert_Days__c= 2;
		t.Expire_Days__c= 2;
		t.FAM_Alert_Days__c= 2;
		t.Period__c= 'Monthly';
		t.Type__c = 'Financials';
		insert t;
					
		Lease_Compliance__c nl = new Lease_Compliance__c();
		nl.lease__c = lease.Id;
		nl.Received_Date__c = null;
		nl.Start_Date__c = date.today().adddays(-2);
		nl.End_Date__c = date.today().adddays(-1);
		nl.Client_Alert_Days__c = 1;
		nl.Expire_Days__c = 5;
		nl.FAM_Alert_Days__c = 1;
		nl.Due_Days__c = 1;
		nl.recordtypeid = pending;
		nl.type__c = 'Financials';
		insert nl;
		
		nl = new Lease_Compliance__c();
		nl.recordtypeid = pending;
		nl.lease__c = lease.Id;
		nl.Received_Date__c = null;
		nl.Start_Date__c = date.today().adddays(-2);
		nl.End_Date__c = date.today().adddays(-1);
		nl.Client_Alert_Days__c = 1;
		nl.Expire_Days__c = 1;
		nl.FAM_Alert_Days__c = 1;
		nl.Due_Days__c = 1;
		nl.type__c = 'Financials';
		insert nl;
		
		nl = new Lease_Compliance__c();
		nl.recordtypeid = pending;
		nl.lease__c = lease.Id;
		nl.Received_Date__c = null;
		nl.Start_Date__c = date.today().adddays(-2);
		nl.End_Date__c = date.today().adddays(-1);
		nl.Client_Alert_Days__c = 1;
		nl.Expire_Days__c = 1;
		nl.FAM_Alert_Days__c = 1;
		nl.Due_Days__c = 1;
		nl.type__c = 'Property Insurance';
		insert nl;

		List<Lease_Compliance__c> lcs = new List<Lease_Compliance__c>();
		lcs = [Select Id, Name, Property_Name__c, Start_Date__c, lease__c, lease__r.Tenant__r.Tenant__c, Client_Notification_Role__c, lease__r.Property__c, Lease_Compliance_Name__c, Created_Follow_Up_Record__c, Expiration_Date__c, end_date__c, 
        		Type__c, Period__c, Client_Notifications_Sent__c, Client_Second_Alert_Sent__c, Client_Final_Alert_Sent__c, Due_Date__c,
        		Second_Alert_Date__c, Second_Client_Alert_Active__c, Final_Alert_Active__c, Client_Alert_Date__c from Lease_Compliance__c];

        for(Lease_Compliance__c lc : lcs){
        	System.debug('lc: ' + lc.Client_Alert_Date__c);
        }
	    	
	}
}
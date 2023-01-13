@isTest public class TestFinancials {
	
	@testSetup public static void finSetup() {
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
        
        List<Financial__c> fins= new List<Financial__c>();
        
        fins.add(new Financial__c(Audited__c = True,Account__c = a.Id,RecordTypeId=FinancialCtrl.quarterlyRecType(),Fiscal_Year__c = '19-20',Fiscal_Quarter__c = 'Q1', Active__c=True, Ran_Lease_Map_Flow__c = true));
        fins.add(new Financial__c(Audited__c = True,Account__c = a.Id,RecordTypeId=FinancialCtrl.annualRecType(),Fiscal_Year__c = '19-20', Active__c=True, Ran_Lease_Map_Flow__c = true));
        fins.add(new Financial__c(Audited__c = False,Account__c = a.Id,RecordTypeId=FinancialCtrl.monthlyRecType(),Fiscal_Year__c = '19-20',Month__c = 'Jan', Active__c=True, Ran_Lease_Map_Flow__c = true));
        
        fins.add(new Financial__c(Audited__c = True,Account__c = a2.Id,RecordTypeId=FinancialCtrl.quarterlyRecType(),Fiscal_Year__c = '19-20',Fiscal_Quarter__c = 'Q1', Active__c=True, Ran_Lease_Map_Flow__c = true));
        fins.add(new Financial__c(Audited__c = True,Account__c = a2.Id,RecordTypeId=FinancialCtrl.annualRecType(),Fiscal_Year__c = '19-20', Active__c=True, Ran_Lease_Map_Flow__c = true));
        fins.add(new Financial__c(Audited__c = False,Account__c = a2.Id,RecordTypeId=FinancialCtrl.monthlyRecType(),Fiscal_Year__c = '19-20',Month__c = 'Jan', Active__c=True, Ran_Lease_Map_Flow__c = true));
        insert fins;
        
        fins= new List<Financial__c>();
        fins.add(new Financial__c(Audited__c = True,Account__c = a.Id,RecordTypeId=FinancialCtrl.quarterlyRecType(),Fiscal_Year__c = '19-20',Fiscal_Quarter__c = 'Q2', Active__c=True, Ran_Lease_Map_Flow__c = true));
        fins.add(new Financial__c(Audited__c = True,Account__c = a.Id,RecordTypeId=FinancialCtrl.annualRecType(),Fiscal_Year__c = '18-19', Active__c=True, Ran_Lease_Map_Flow__c = true));
        fins.add(new Financial__c(Audited__c = False,Account__c = a.Id,RecordTypeId=FinancialCtrl.monthlyRecType(),Fiscal_Year__c = '19-20',Month__c = 'Feb', Active__c=True, Ran_Lease_Map_Flow__c = true));
        insert fins;
	}

	@isTest static void testFinancialsQuarterAnnual(){

		Test.starttest();
			Account a = [Select Id from Account where Name='test ch'];
            FinancialCtrl.getAccountName(a.Id);
        	FinancialCtrl.getAccounts2(a.Id);
            FinancialCtrl.getCurrFQ();
            FinancialCtrl.getCurrFY();
            FinancialCtrl.getData('True', a.Id, 'Quarterly/Annual', 'All', 'Q1', 'Q4', '18', '20');
        	FinancialCtrl.getFiscalYears();
            FinancialCtrl.getActualBudgetComments('1', '["Q3"]', '18-20');
            
        
		Test.stoptest();
    }
    @isTest static void testFinancialsAnnual(){

		Test.starttest();
			Account a = [Select Id from Account where Name='test ch'];
            FinancialCtrl.getAccountName(a.Id);
        	FinancialCtrl.getAccounts2(a.Id);
            FinancialCtrl.getCurrFQ();
            FinancialCtrl.getCurrFY();
            FinancialCtrl.getData('False', a.Id, 'Annual', 'Unaudited', 'Q1', 'Q4', '18', '20');
        	FinancialCtrl.getFiscalYears();
            
        
		Test.stoptest();
    }
    @isTest static void testFinancialsMonthly(){

		Test.starttest();
			Account a = [Select Id from Account where Name='test ch'];
            FinancialCtrl.getAccountName(a.Id);
        	FinancialCtrl.getAccounts2(a.Id);
            FinancialCtrl.getCurrFQ();
            FinancialCtrl.getCurrFY();
            FinancialCtrl.getData('False', a.Id, 'Monthly', 'Audited', 'Q1', 'Q4', '18', '20');
        	FinancialCtrl.getFiscalYears();
            
        
		Test.stoptest();
    }
    @isTest static void testFinancialsEndNoStart(){

		Test.starttest();
			Account a = [Select Id from Account where Name='test ch'];
            FinancialCtrl.getAccountName(a.Id);
        	FinancialCtrl.getAccounts2(a.Id);
            FinancialCtrl.getCurrFQ();
            FinancialCtrl.getCurrFY();
            FinancialCtrl.getData('False', a.Id, 'Quarterly', 'Audited', null, 'Q4', null, '20');
        	FinancialCtrl.getFiscalYears();
            
        
		Test.stoptest();
    }
    @isTest static void testFinancialsStartNoEnd(){

		Test.starttest();
			Account a = [Select Id from Account where Name='test ch'];
            FinancialCtrl.getAccountName(a.Id);
        	FinancialCtrl.getAccounts2(a.Id);
            FinancialCtrl.getCurrFQ();
            FinancialCtrl.getCurrFY();
            FinancialCtrl.getData('False', a.Id, 'Quarterly', 'Audited', 'Q1', null, '18', null);
        	FinancialCtrl.getFiscalYears();
           
		Test.stoptest();
    }
    
    @isTest static void testFinancialsMonthlyAnnual(){

		Test.starttest();
			Account a = [Select Id from Account where Name='test ch'];
            FinancialCtrl.getAccountName(a.Id);
        	FinancialCtrl.getAccounts2(a.Id);
            FinancialCtrl.getCurrFQ();
            FinancialCtrl.getCurrFY();
            FinancialCtrl.getData('False', a.Id, 'Monthly/Annual', 'Audited', 'Q1', 'Q4', '18', '20');
        	FinancialCtrl.getFiscalYears();
            
        
		Test.stoptest();
    }
    
    @isTest static void testFinancialsBudgetvActual(){

		Test.starttest();
			Account a = [Select Id from Account where Name='test ch'];
            FinancialCtrl.getAccountName(a.Id);
        	FinancialCtrl.getAccounts2(a.Id);
            FinancialCtrl.getCurrFQ();
            FinancialCtrl.getCurrFY();
            FinancialCtrl.getData('False', a.Id, 'BudgetvActual', 'Audited', 'Q1', 'Q4', '18', '20');
        	FinancialCtrl.getFiscalYears();
            
        
		Test.stoptest();
    }
    
    @isTest static void testgetLatestFinRecord(){

		Test.starttest();
			Account a = [Select Id from Account where Name='test ch'];
        	List<Financial__c> fins = [Select Id, RecordTypeId, Name, Fiscal_QUarter__c, FIscal_Year__c, Month__c, Data_Source__c from Financial__c];
            FinancialUtils.getLatestFinRecord(fins);
        
		Test.stoptest();
    }
    
}
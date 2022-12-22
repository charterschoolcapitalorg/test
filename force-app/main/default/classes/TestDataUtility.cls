/**=====================================================================
 * Appirio, Inc
 * Name: TestDataUtility
 * Description: Utility class to create test data
 * Created Date: [05/14/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/
public class TestDataUtility {
	public static Payor__c createPayor(){
		Payor__c test_Payor = new Payor__c (
	    	Name = 'test value'
		);
		return test_Payor;
	}


	public static Receivable_Type__c createReceivableType(Id payorId){
		Receivable_Type__c test_ReceivableType = new Receivable_Type__c (
		    Payor__c = payorId,
		    Name = 'test value',
		    Fiscal_Year__c = '14-15'
		);
		return test_ReceivableType;
	}

	public static Calculation__c createCalculation(Id receivableTypeId){
		Calculation__c test_Calculation = new Calculation__c (
		    Receivable_Type__c = receivableTypeId,
		    Apex_Class_Name__c = 'test value'
		);
		return test_Calculation;
	}

	public static Payout_Date__c createPayoutDate(Id calculationId){
		Payout_Date__c test_PayoutDate = new Payout_Date__c (
		    Percent_Value_of_Receivable__c = 1.00,
		    Default_Payout_Date__c = Date.newinstance(2014,5,15),
		    Calculation__c = calculationId,
		    Output_Name__c = 'test value'
		);
		return test_PayoutDate;
	}

	public static Funded_Receivable__c createFundedReceivable(decimal amount, Id accId, Id rpaId){
		return new Funded_Receivable__c(GRV_Amount__c = amount,
										FV_Amount__c = amount*2,
										Max_Deferred_Purchase_Price__c = amount,
										Upfront_Purchase_Price__c = amount,
										Charter_Holder__c = accId,
									    RPA__c = rpaId,
									    School__c = accId,
									    purchase_date__c = date.today());
	}


  public static Account createAccountForRecordType(Id recordTypeId, String name, String stateId, Boolean isInsert){
    Account a = new Account();
    a.Name = name;
    a.RecordTypeId = recordTypeId;
    if (isInsert) {
      insert a;
    }
    return a;
  }



  public static State_Province__c createOperatingState() {
  	State_Province__c testState = new State_Province__c();
  	testState.Name = 'testState';
  	insert testState;
  	return testState;
  }

  //2016.09.20 J Caughie - Additional methods
  public static RPA__c createRPA(Id charterHolder){
  	RPA__c rpa = new RPA__c(Account__c = charterHolder);
  	insert rpa;
  	return rpa;
  }
  //2016.09.20 J Caughie - Additional methods


  //=============================================================//
  //Creates User
  //============================================================//
  public static User createUser(String profileName){

    User testUser = new User();
    Profile p = [SELECT id from profile where name =: profileName ];
    //UserRole role = [SELECT ID from UserRole where Name = 'CEO'];

    testUser = new User(alias = 'testUser', email='standarduser' + Math.random()  + '@testorg.com',
                 emailencodingkey='UTF-8', lastname='Testing', languagelocalekey='en_US',
                 localesidkey='en_US', profileid = p.Id, timezonesidkey='America/Los_Angeles',
                 username='teststandarduser' + Math.random() + '@testorg.com', IsActive=true,
                 CompanyName = 'test Company', NewAcctCommission__c = 10, ExistingAcctCommission__c = 10);

    return testUser;
  }

}
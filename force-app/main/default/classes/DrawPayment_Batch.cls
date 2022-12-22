/**=====================================================================
 * Name: DrawPayment_Batch
 * Description: Used for quarterly payments to investors
 * Created Date: [01/03/2017]
 * Created By: [John Caughie]
 *
 * Date Modified                Modified By                  Description of the update
 * [xx/xx/xxxx]                 [xxxxx xxxxx]              []
 =====================================================================*/

global class DrawPayment_Batch implements Database.Batchable<sObject> {
	
	String investorName;
	Date paymentDate;
	
	global DrawPayment_Batch(Date paymentDate, String investor) {
		this.investorName = investor;
		this.paymentDate = paymentDate;
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id, Interest_Due__c, Borrow_Date__c, Last_Activity_Date__c, Note_Rate__c, Principal_Due__c '+
						'FROM Draw_Note__c WHERE Status__c = \'Active\' AND Investor__R.Name = :investorName AND Borrow_Date__c <= :paymentDate';
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<Draw_Note__c> listDrawNotes) {

		List<Draw_Entry__c> entries = new List<Draw_Entry__c >();

		for(Draw_Note__c d : listDrawNotes){
		    //if no last activity date use borrow date as base
		    Date fromDate = (d.Last_Activity_Date__c == null) ? d.Borrow_Date__c : d.Last_Activity_Date__c;
		    Decimal accruedInterest = DrawInterestCalculationManager.calculateInterest(fromDate, d.Note_Rate__c, d.Principal_Due__c, paymentDate);
		    Decimal totalInterest = accruedInterest + d.Interest_Due__c;
		    entries.add(new Draw_Entry__c(Draw_Note__c = d.Id, Principal__c = d.Principal_Due__c, Activity_Date__c  = paymentDate, Activity_Type__c ='Quarterly Interest', Draw_Rate__c = d.Note_Rate__c,
		                                 			Principal_Paid__c = 0, Ending_Principal__c  = d.Principal_Due__c, Accrued_Interest__c = accruedInterest,
		                                            Interest_Paid__c = totalInterest, Interest_Fwd__c  = 0, Payment_Amount__c = totalInterest));
		}

		if(!entries.isEmpty()){
			try{
				insert entries;
			}catch(exception ex){
				system.debug('Error while inserting draw entries ' + ex.getMessage());
			}
		}

	}
	
	global void finish(Database.BatchableContext BC) {
		
	}
	
}
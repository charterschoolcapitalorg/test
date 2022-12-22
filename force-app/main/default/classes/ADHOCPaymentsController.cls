/**=====================================================================
 * Appirio, Inc
 * Name: ADHOCPaymentsController
 * Description: I-118039 : Modify Ad Hoc Payment Logic
 * Created Date: [06/16/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified            Modified By                 Description of the update
 * [06/26/2014]            [Rajeev Arya]              [T-286165 - Modify Draw Note Borrow Value Display
 * [07/09/2014]            [Rajeev Arya]              [I-120697 - Adhoc draw payments are not using the “Paid On” date as the activity date but are using the system date instead
 
 =====================================================================*/

public class ADHOCPaymentsController {
    public account acc { get; set; }
    public Draw_Note__c draw {get;set;}
    public decimal TotalAmountBorrowed {get;set;}
    public decimal AmountPaid {get;set;}
    public decimal PrincipalDue {get;set;}
    public decimal OriginalPrincipalDue {get;set;}
    public Date DatePaid;
    public Boolean Button {get;set;} 
    
    /*********************************
	Constructor for the Controller Class
	*********************************/
    public ADHOCPaymentsController() {
        Button = false;
        TotalAmountBorrowed = 0.00;
        draw = [select name, Id, investor__c, Note_Rate__c, Borrow_Date__c, Status__c, Note_Description__c, Total_Amount_Borrowed_formula__c, 
        		Operating_State__c, principal_due__c,Last_Pay_Date__c
	        	from draw_note__c where id =: ApexPages.currentPage().getParameters().get('id')];
	    if(draw.Investor__c != null){
		    TotalAmountBorrowed = draw.Total_Amount_Borrowed_formula__c;
		    OriginalPrincipalDue = draw.Principal_Due__c;
		    PrincipalDue = draw.Principal_Due__c;
		    acc = [select name, accountnumber from account where id =: draw.investor__c];
	    }
	    else{
	    	Button = true;
	    	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'This Draw Note is not related to any Investor. Please link it to an Investor');
            ApexPages.addMessage(myMsg);
	    }
    }  

	/*********************************
	Action Function to save the ADHOC Payment Amount, and create Payment Sub and Payment records for it
	*********************************/
	public PageReference SaveADHOCPayment(){
		DatePaid = draw.Last_Pay_Date__c;
		if(AmountPaid != null && AmountPaid != 0.00){
			Payment_Sub__c paySub = new Payment_Sub__c();
            if(DatePaid != null){
           		Date paidDate = Date.parse(DatePaid.format());
            	paySub.Date_Paid__c = paidDate;
            }
           	paySub.Amount__c = AmountPaid;
            paySub.Paid_To__c = 'Investor';
            paysub.Payment_Against__c = draw.Id;
            paysub.Payment_Type__c = 'Ad Hoc';
            system.debug('payment sub record is' + paySub);
            insert paysub;
            system.debug('greywar 4');
            if(paysub.Id != null){
            	Payment__c pay = new Payment__c();
            	pay.Draw_Note__c = paysub.Payment_Against__c;
            	pay.Payment_Amount__c = paysub.Amount__c;
            	pay.Payment_Sub__c = paysub.Id;
            	pay.Payment_Type__c = 'Ad Hoc';
            	pay.Date_Paid__c = paySub.Date_Paid__c;
            	insert pay;
            	ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'The Payment and the Payment Sub record has been created for the ADHOC Payment');
        		ApexPages.addMessage(myMsg);
        		Button = true;
            }
		}
		return null;
	}
}
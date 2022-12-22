/**=====================================================================
 * Appirio, Inc
 * Name: DrawInterestCalculationManager
 * Description: Manager Class for Draw Interest Calculation
 				T-275864 : Create Investor - Interest calcs
 * Created Date: [05/20/2014]
 * Created By: [Manisha Gupta] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * [06/26/2014]                [Rajeev Arya]              [T-286165 - Modify Draw Note Borrow Value Display]
 * [07/02/2014]                [Rajeev Arya]              [T-291633 - Modify Draw Entry Interest calc for rate change]
 * [11/13/2015]                [John Caughie]             [Rounding issue with interest rate calculations]
 * [09/29/2016]                [John Caughie]             [Added payment source type to the new draw entry] 
 =====================================================================*/
public class DrawInterestCalculationManager {

	// method to create new draw entry record
	// there are three use cases from which this method will call:
	// 1. At start of each month
	// 2. Note rate on Draw Note in changed
	// 3. Payment is made against draw note

	public static Draw_Entry__c createDrawEntry(Draw_Note__c drawNote, Draw_Entry__c oldDrawEntry, Payment__c payment, Date ActivityDate){
  		Draw_Entry__c newDrawEntry = new Draw_Entry__c();
		newDrawEntry.Draw_Note__c = drawNote.Id;

		//2016.09.29 J Caughie - Add source payment type to Draw Entry if available
		//System.debug('JC Pay ' + payment);
		newDrawEntry.Source_Payment_Type__c = payment <> null ? payment.Payment_Type__c : null;

		// if old draw entry is null then previous activity date is the borrow date on Draw Note
		Date previousActivityDate = oldDrawEntry <> null ? oldDrawEntry.Activity_Date__c : drawNote.Borrow_Date__c;

		// if old draw entry is null then principal is total amount borrowed on draw note else ending principal on old draw entry
		newDrawEntry.Principal__c  = oldDrawEntry <> null ? oldDrawEntry.Ending_Principal__c : drawNote.Total_Amount_Borrowed_formula__c;
		if(ActivityDate == null){
  	    	ActivityDate = Date.today();
  		}
		newDrawEntry.Activity_Date__c = ActivityDate;
		system.debug('3 arguments are '+ previousActivityDate + drawNote.Note_Rate__c + newDrawEntry.Principal__c + newDrawEntry.Activity_Date__c);
		newDrawEntry.Accrued_Interest__c = calculateInterest(previousActivityDate, drawNote.Note_Rate__c, newDrawEntry.Principal__c, newDrawEntry.Activity_Date__c );
		system.debug('=========INTEREST===========' + newDrawEntry.Accrued_Interest__c);
		if(newDrawEntry.Accrued_Interest__c == null){
			return null;
		}
		decimal totalInterestForThisMonth = oldDrawEntry <> null ?
											oldDrawEntry.Interest_Fwd__c + newDrawEntry.Accrued_Interest__c :
											newDrawEntry.Accrued_Interest__c;
		newDrawEntry.Draw_Rate__c = drawNote.Note_Rate__c;
		decimal paymentOtherThanInt = 0;
		if(payment == null){
			newDrawEntry.Ending_Principal__c = newDrawEntry.Principal__c ;
			newDrawEntry.Interest_Fwd__c = totalInterestForThisMonth;
			newDrawEntry.Interest_Paid__c = 0.0;
			newDrawEntry.Principal_Paid__c = 0.0;
		}else{
			newDrawEntry.Payment_Amount__c = payment.Payment_Amount__c;
				if(drawNote.Payment_Type__c == 'Principal Only'){
						newDrawEntry.Principal_Paid__c = payment.Payment_Amount__c;
						newDrawEntry.Interest_Paid__c = 0;
						newDrawEntry.Interest_Fwd__c = 0;
						newDrawEntry.Ending_Principal__c = newDrawEntry.Principal__c  - newDrawEntry.Principal_Paid__c;
					}else{
						if(payment.Payment_Amount__c >= totalInterestForThisMonth){
									newDrawEntry.Interest_Paid__c = totalInterestForThisMonth;
									newDrawEntry.Interest_Fwd__c = 0.0;
									paymentOtherThanInt = payment.Payment_Amount__c - totalInterestForThisMonth;
									if(paymentOtherThanInt > newDrawEntry.Principal__c){
										newDrawEntry.Principal_Paid__c = newDrawEntry.Principal__c;
										newDrawEntry.Ending_Principal__c = 0;
										newDrawEntry.Over_Payment_Amount__c = paymentOtherThanInt - newDrawEntry.Principal__c;
									}else{
										newDrawEntry.Principal_Paid__c = paymentOtherThanInt;
										newDrawEntry.Ending_Principal__c = newDrawEntry.Principal__c  - newDrawEntry.Principal_Paid__c;
									}
				
								}else{
									newDrawEntry.Interest_Paid__c = payment.Payment_Amount__c;
									newDrawEntry.Interest_Fwd__c = totalInterestForThisMonth - payment.Payment_Amount__c;
									newDrawEntry.Ending_Principal__c = newDrawEntry.Principal__c ;
									newDrawEntry.Principal_Paid__c = 0.0;
								}
							}

		}
		return newDrawEntry;
  	}

  	public static double calculateInterest(Date previousActivityDate, decimal interestRate, decimal principal, Date Actdate){
  		if(previousActivityDate <> null && interestRate <> null && principal <> null){
  			if(Actdate == null){
  				Actdate = Date.today();
  			}
  			Integer numberOfDays = previousActivityDate > Actdate ? 0 : previousActivityDate.daysBetween(Actdate) ;
			return ((principal * interestRate * numberOfDays) / (360 * 100)).setScale(2) ;								//2015.11.13 J Caughie - Set Scale to two decimals
  		}
  		return null;

  	}
}
/**=====================================================================
 * Appirio, Inc
 * Manager Class Name: DrawNoteTriggerManager
 * Description: T-275864 : Manager Class for Trigger DrawNoteTrigger
 * Created Date: [05/15/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * 05/20/2014 					Manisha Gupta			   Write logic for note rate change on Draw Note T-275864
 * [07/02/2014]                 [Rajeev Arya]              [T-291633 - Modify Draw Entry Interest calc for rate change]
 * 11/02/2015					John Caughie				Estimate residual when draw is activated
 * 01/17/2017					John Caughie				Exclude 'Credit Line' from draw rate changes
 =====================================================================*/
public class DrawNoteTriggerManager {

	public static void calculateInterest(list<Draw_Note__c> newDrawNotes, map<Id, Draw_Note__c> mapOldDrawNotes){

		list<Draw_Note__c> listDrawNotesToCalculateInterest = new list<Draw_Note__c>();

		for(Draw_Note__c drawNote : newDrawNotes){
			if(drawNote.Status__c == 'Active' && drawNote.Note_Rate__c <> mapOldDrawNotes.get(drawNote.Id).Note_Rate__c
					&& mapOldDrawNotes.get(drawNote.Id).Note_Rate__c <> null && drawNote.RecordTypeName__c <> 'Credit_Line'){
				listDrawNotesToCalculateInterest.add(mapOldDrawNotes.get(drawNote.Id));
			}
		}

		map<Id, Date> mapDrawNoteIdDrawRateStartDate = new map<Id, Date>();
		for(Draw_Rate__c drRate : [select name, id, start_date__c, draw_note__c from draw_rate__c
								 where end_date__c = null
								 and draw_note__c in:listDrawNotesToCalculateInterest
								 order by id desc]){
			if(!mapDrawNoteIdDrawRateStartDate.containsKey(drRate.draw_note__c)){
				mapDrawNoteIdDrawRateStartDate.put(drRate.draw_note__c,drRate.Start_Date__c);
			}
		}

		map<Id,Draw_Entry__c> mapDrawNoteIdDrawEntry = new map<Id, Draw_Entry__c>();
		for(Draw_Entry__c drawEntry : [Select d.SystemModstamp, d.Principal__c, d.Principal_Paid__c, d.Payment_Amount__c, d.Name,
											d.Interest_Paid__c, d.Interest_Fwd__c, d.Id, d.Ending_Principal__c, d.Draw_Rate__c, d.Draw_Note__c,
											d.Activity_Type__c, d.Activity_Date__c, d.Accrued_Interest__c
										From Draw_Entry__c d where Draw_Note__c in : listDrawNotesToCalculateInterest order by Activity_Date__c desc, Id desc]){
			if(!mapDrawNoteIdDrawEntry.containsKey(drawEntry.Draw_Note__c)){
				mapDrawNoteIdDrawEntry.put(drawEntry.Draw_Note__c, drawEntry);
			}
		}
		List<Draw_Entry__c> listDrawEntryToInsert = new list<Draw_Entry__c>();
		Draw_Entry__c drawEntry;
		for(Draw_Note__c drawNote : listDrawNotesToCalculateInterest){
			if(drawNote.Note_Rate__c <> null){

				if(!mapDrawNoteIdDrawRateStartDate.containsKey(drawNote.Id)){
					drawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, mapDrawNoteIdDrawEntry.get(drawNote.Id), null, null);
				}
				else{
					drawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote, mapDrawNoteIdDrawEntry.get(drawNote.Id), null, mapDrawNoteIdDrawRateStartDate.get(drawNote.Id));
				}

				if(drawEntry <> null){
					drawEntry.Activity_Type__c = 'Draw Rate Change';
					listDrawEntryToInsert.add(drawEntry);
				}
			}
		}

		if(!listDrawEntryToInsert.isEmpty()){
			try{
				insert listDrawEntryToInsert;
			}catch(exception ex){
				system.debug('Error while inserting draw entries ' + ex.getMessage());
			}
		}
	}

	public static void calculateResidual(list<Draw_Note__c> newDrawNotes, map<Id, Draw_Note__c> mapOldDrawNotes){
		List<Draw_Note__c> updatedDraws = new List<Draw_Note__c>();

		for(Draw_Note__c d : newDrawNotes){
			if(d.Status__c == 'Active' && mapOldDrawNotes.get(d.Id).Status__c == 'Draft'){
				updatedDraws.add(d);
			}
		}

		calculateResidualEstimate(updatedDraws);

	}

	//New method to calculate estimated residual on a draw based on estimated payment dates at activation
	public static void calculateResidualEstimate(list<Draw_Note__c> newDrawNotes){

		//List of draws to be updated
		List<Draw_Note__c> updatedDraws = new List<Draw_Note__c>();

		//List of total payment by expected payment date for each draw
		List<AggregateResult > payments = new List<AggregateResult >([
		                        SELECT Draw_Note__c note , Funded_Receivable__r.Expected_Pay_Date__c paydate, Sum(FV_Amount_TX__c) amount
		                        FROM Draw_Note_TX__c
		                        WHERE Draw_Note__c IN :newDrawNotes
		                        GROUP BY Draw_Note__c, Funded_Receivable__r.Expected_Pay_Date__c 
		                        ORDER BY Draw_Note__c, Funded_Receivable__r.Expected_Pay_Date__c Asc ]);

		//Calculate residual for each draw
		for(Draw_Note__c dn : newDrawNotes){

		    //previous "redemption" information needed for each calculation - for first payment values come from the Draw
		    Date lastPaymentDate = dn.Borrow_Date__c;
		    Decimal principalBalance = dn.Total_Amount_Borrowed__c;
		    Decimal interestBalance = 0.0;
		    Decimal totalInterestPaid = 0.0;

		    for(AggregateResult ar : payments){
		        if(dn.Id == ar.get('note')){
		            
		            //Current redemption details
		            //System.debug('Aggregate Results: ' + ar);
		            Decimal redemptionAmount = (Decimal)ar.get('amount');
		            Date redemptionDate = (Date)ar.get('paydate');
		            
		            //System.debug('Last Payment Date: ' + lastPaymentDate);
		            //System.debug('Principal Balance: ' + principalBalance);
		            //System.debug('Interest Balance: ' + interestBalance);

		            //Calculation split between interst and principal
		            Decimal interestDue = ((lastPaymentDate.daysBetween(redemptionDate)) * principalBalance * dn.Note_Rate__c / 100 / 360 + interestBalance).setScale(2);
		            Decimal interestPaid = (interestDue > redemptionAmount) ? redemptionAmount : interestDue;
		            Decimal principalPaid = (interestDue > redemptionAmount) ? 0.00 : (redemptionAmount - interestDue);

		            //Values needed in next iteration
		            interestBalance = Math.max(0.00, interestDue - redemptionAmount);
		            totalInterestPaid += interestPaid;
		            principalBalance = Math.max(0.00, principalBalance - principalPaid);
		            lastPaymentDate = redemptionDate;
		            
		            //System.debug('Interest Paid: ' + interestPaid);
		            //System.debug('Interest Balance: ' + interestBalance);
		            //System.debug('Total Interest Paid: ' + totalInterestPaid);
		            //System.debug('Principal Balance: ' + principalBalance);
		            //System.debug('Last Payment Date: ' + lastPaymentDate);
		        }
		    }

		    System.debug(dn.Name + ' - ' + (dn.Total_FV_Amount__c - dn.Total_Amount_Borrowed__c - totalInterestPaid));

		    //Add to draw list
		    Draw_Note__c updatedDrawNote = new Draw_Note__c(id = dn.Id, Excess_Cash_Collateral__c = (dn.Total_FV_Amount__c - dn.Total_Amount_Borrowed__c - totalInterestPaid));
		    updatedDraws.add(updatedDrawNote);
		    
		}

		if(!updatedDraws.isEmpty()){
			try{
				update updatedDraws;
			}catch(exception ex){
				system.debug('Error while inserting draw entries ' + ex.getMessage());
			}
		}
		//update updatedDraws;		
	}

}
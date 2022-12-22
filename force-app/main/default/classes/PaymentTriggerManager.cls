/**=====================================================================
 * Appirio, Inc
 * Name: Manager Class for Payment trigger
 * Description: Manager Class for Payment trigger
 				T-275864 : Create Investor - Interest calcs
 * Created Date: [05/20/2014]
 * Created By: [Manisha Gupta] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * [06/26/2014]                [Rajeev Arya]              [T-286165 - Modify Draw Note Borrow Value Display
 * [06/27/2014]                [Rajeev Arya]              [I-119205 - Create Total Accrued Interest on Draw Note
 * [07/02/2014]                [Rajeev Arya]              [T-291633 - Modify Draw Entry Interest calc for rate change]

 =====================================================================*/
public class PaymentTriggerManager {

	// Method to calculate draw interest for each payment
	//2015.08.07 J Caughie - Added parameter for redemption id and removed trigger
	public static void calculateDrawInterest(list<Payment__c> newPayments, Id redId){
		System.debug('PaymentTriggerManager');
		set<Id> drawNoteIds = new set<Id>();
		for(Payment__c payment : newPayments){
			if(payment.Draw_Note__c <> null){
				drawNoteIds.add(payment.Draw_Note__c);
			}
		}

		// get map of draw notes against which payment is made
		map<Id, Draw_Note__c> mapDrawNote = new map<Id, Draw_Note__c>([Select d.Total_Amount_Borrowed_formula__c, d.Total_Accrued_Interest_Current__c, d.Status__c, d.Prior_Activity_Date__c,
						 d.Principal_Paid__c, d.OwnerId, d.Operating_State__c, d.Note_Rate__c, d.Note_Description__c, d.Name, d.LegacyParentID__c,
						d.LegacyID__c, d.Last_Pay_Date__c, d.LastActivityDate, d.Investor__c, d.Payment_Type__c,
						 d.Interest_Paid__c, d.Id, d.Edit_Draw_Receivables__c, d.DrawHeaderID__c, d.Borrow_Date__c, d.Investor__r.Name, d.Principal_Due__c
						From Draw_Note__c d where Id in :drawNoteIds] ); // removed - Principal_Due__c > 0 and Id in :drawNoteIds] );  

		// get map of draw note and latest draw entry for each payment
		map<Id,Draw_Entry__c> mapDrawNoteIdDrawEntry = new map<Id, Draw_Entry__c>();
		for(Draw_Entry__c drawEntry : [Select d.SystemModstamp, d.Principal__c, d.Principal_Paid__c, d.Payment_Amount__c, d.Name,
											d.Interest_Paid__c, d.Interest_Fwd__c, d.Id, d.Ending_Principal__c, d.Draw_Rate__c, d.Draw_Note__c,
											d.Activity_Type__c, d.Activity_Date__c, d.Accrued_Interest__c
										From Draw_Entry__c d where Draw_Note__c in : mapDrawNote.keySet() order by Activity_Date__c desc, Id desc]){
			if(!mapDrawNoteIdDrawEntry.containsKey(drawEntry.Draw_Note__c)){
				mapDrawNoteIdDrawEntry.put(drawEntry.Draw_Note__c, drawEntry);
			}
		}

		// calculate interest and insert new draw entry records
		List<Draw_Entry__c> listDrawEntryToInsert = new list<Draw_Entry__c>();
		List<Payment_Sub__c> listPaySubForOverPayment = new list<Payment_Sub__c>();
		Draw_Entry__c drawEntry;
		for(Payment__c payment : newPayments){
			System.debug('payment: ' + payment);
			System.debug('Draw: ' + payment.Draw_Note__c);
			System.debug('Due: ' + mapDrawNote.get(payment.Draw_Note__c).Principal_Due__c);
			if(payment.Draw_Note__c <> null && mapDrawNote.get(payment.Draw_Note__c).Principal_Due__c > 0){		//removed & replaced - && mapDrawNote.get(payment.Draw_Note__c) <> null added 
				drawEntry = DrawInterestCalculationManager.createDrawEntry(mapDrawNote.get(payment.Draw_Note__c),
																							mapDrawNoteIdDrawEntry.get(payment.Draw_Note__c),
																						payment, payment.Date_Paid__c);
				if(drawEntry <> null){
					drawEntry.Activity_Type__c = 'Payment';
					listDrawEntryToInsert.add(drawEntry);
					if(drawEntry.Over_Payment_Amount__c <> null && drawEntry.Over_Payment_Amount__c > 0){
						System.debug('Inv: ' + mapDrawNote.get(drawEntry.Draw_Note__c).Investor__r.Name);
						if(mapDrawNote.get(drawEntry.Draw_Note__c).Investor__r.Name == 'Two Sigma'){								//2015.08.07 J Caughie - Added logic as Two Sigma is different from non-Two Sigma
							listPaySubForOverPayment.add(new Payment_Sub__c(//Payment_Against__c = drawEntry.Draw_Note__c,			//2015.08.07 J Caughie - Removed from Payment Sub
																			Amount__c = drawEntry.Over_Payment_Amount__c,
																			Date_Paid__c = payment.Date_Paid__c,
																			Paid_To__c = 'CSC',
																			Payment_Type__c = 'Over Payment',
																			Redemption__c = redId));								//2015.08.07 J Caughie - Added redemption id
							listPaySubForOverPayment.add(new Payment_Sub__c(Payment_Against__c = drawEntry.Draw_Note__c,
																			Amount__c = (drawEntry.Over_Payment_Amount__c)*(-1),
																			Date_Paid__c = payment.Date_Paid__c,
																			Paid_To__c = 'Investor',
																			Payment_Type__c = 'Over Payment',
																			Redemption__c = redId));								//2015.08.07 J Caughie - Added redemption id
						} else {
							listPaySubForOverPayment.add(new Payment_Sub__c(//Payment_Against__c = drawEntry.Draw_Note__c,			//2015.08.07 J Caughie - Removed from Payment Sub
																			Amount__c = drawEntry.Over_Payment_Amount__c,
																			Date_Paid__c = payment.Date_Paid__c,
																			Paid_To__c = 'CSC',
																			Payment_Type__c = 'Over Payment'));
							listPaySubForOverPayment.add(new Payment_Sub__c(Payment_Against__c = drawEntry.Draw_Note__c,
																			Amount__c = (drawEntry.Over_Payment_Amount__c)*(-1),
																			Date_Paid__c = payment.Date_Paid__c,
																			Paid_To__c = 'Investor',
																			Payment_Type__c = 'Over Payment'));
						}
					}
				}
			} else if(payment.Draw_Note__c <> null && mapDrawNote.get(payment.Draw_Note__c).Principal_Due__c == 0){
				//draw is paid off and negative subs need entering
				if(mapDrawNote.get(payment.Draw_Note__c).Investor__r.Name == 'Two Sigma'){								//2015.08.07 J Caughie - Added logic as Two Sigma is different from non-Two Sigma
							listPaySubForOverPayment.add(new Payment_Sub__c(//Payment_Against__c = drawEntry.Draw_Note__c,			//2015.08.07 J Caughie - Removed from Payment Sub
																			Amount__c = payment.Payment_Amount__c,
																			Date_Paid__c = payment.Date_Paid__c,
																			Paid_To__c = 'CSC',
																			Payment_Type__c = 'Over Payment',
																			Redemption__c = redId));								//2015.08.07 J Caughie - Added redemption id
							listPaySubForOverPayment.add(new Payment_Sub__c(Payment_Against__c = payment.Draw_Note__c,
																			Amount__c = (payment.Payment_Amount__c)*(-1),
																			Date_Paid__c = payment.Date_Paid__c,
																			Paid_To__c = 'Investor',
																			Payment_Type__c = 'Over Payment',
																			Redemption__c = redId));								//2015.08.07 J Caughie - Added redemption id
				}
			}
		}

		if(!listDrawEntryToInsert.isEmpty()){
			try{
				insert listDrawEntryToInsert;
				if(!listPaySubForOverPayment.isEmpty()){
					insert listPaySubForOverPayment;
					List<Payment__c> listPaymentForOverPayment = new list<Payment__c>();
					for(Payment_Sub__c paySub : listPaySubForOverPayment){
						if(paySub.Paid_To__c == 'Investor'){
							listPaymentForOverPayment.add(new Payment__c(Draw_Note__c = paySub.Payment_Against__c,
																		 Payment_Amount__c = paySub.Amount__c,
																		 Payment_Sub__c = paySub.Id,
																		 Payment_Type__c = 'Over Payment',
																		 Date_Paid__c = paySub.Date_Paid__c));
						}
					}

					if(!listPaymentForOverPayment.isEmpty()){
						insert listPaymentForOverPayment;
					}
				}
			}catch(exception ex){
				system.debug('Exception while inserting records : ' + ex.getMessage());
			}
		} else if(!listPaySubForOverPayment.isEmpty()){
			try{
				system.debug('paymentsubs: ' + listPaySubForOverPayment);
				insert listPaySubForOverPayment;
				if(!listPaySubForOverPayment.isEmpty()){
					List<Payment__c> listPaymentForOverPayment = new list<Payment__c>();
					for(Payment_Sub__c paySub : listPaySubForOverPayment){
						if(paySub.Paid_To__c == 'Investor'){
							listPaymentForOverPayment.add(new Payment__c(Draw_Note__c = paySub.Payment_Against__c,
																		 Payment_Amount__c = paySub.Amount__c,
																		 Payment_Sub__c = paySub.Id,
																		 Payment_Type__c = 'Over Payment',
																		 Date_Paid__c = paySub.Date_Paid__c));
						}
					}
					if(!listPaymentForOverPayment.isEmpty()){
						system.debug('payments: ' + listPaymentForOverPayment);
						insert listPaymentForOverPayment;
					}
				}
			} catch(exception ex) {
				system.debug('Exception while inserting records : ' + ex.getMessage());
			}
		}
	}

	public static void calculateDrawInterestTrigger(list<Payment__c> newPayments){

		System.debug('Triggered Payment');
		List<Payment__c> triggeredPayments = new List<Payment__c>();
		for(Payment__c payment : newPayments){
			if(payment.Draw_Note__c <> null && (payment.Payment_Type__c == 'Ad Hoc' || payment.Payment_Type__c == 'Re-Finance')){
				triggeredPayments.add(payment);
			}
		}

		calculateDrawInterest(triggeredPayments, null);

	}
}
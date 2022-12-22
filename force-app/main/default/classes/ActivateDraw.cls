/**=====================================================================
 * Appirio, Inc
 * Trigger Name: ActivateDraw
 * Description: T-279016 : Active Draw (Web Service Class for the Activate Draw Button)
 * Created Date: [05/21/2014]
 * Created By: [Rajeev Arya] (Appirio)
 * Date Modified                Modified By                  Description of the update
 * [05/29/2014]                [Rajeev Arya]                [T-275388 - Create Lien transfer action]
 * [06/03/2014]                [Rajeev Arya]                [T-284606 - Set Borrow Date at Activation]
 * [06/23/2014]                [Rajeev Arya]                [I-118064 - Replace the DrawNote LKP field on Funded Receivable]
 * [06/25/2014]                [Rajeev Arya]                [T-286165 - Modify Draw Note Borrow Value Display]
 * [06/25/2014]                [Rajeev Arya]                [T-286744 - Set PCSRC transfer date]
 * [06/26/2014]                [Rajeev Arya]                [T-286165 - Modify Draw Note Borrow Value Display
 * [06/27/2014]                [Rajeev Arya]                [I-119205 - Create Total Accrued Interest on Draw Note
 * [07/02/2014]                [Rajeev Arya]                [T-291633 - Modify Draw Entry Interest calc for rate change]
 * [11/07/2015]                [John Caughie]               [Added current active draw to FR & Today's date to DnTx when refinanced]
 * [07/09/2015]                [John Caughie]               [Prevented borrow date from being updated automatically]
 * [03/08/2016]                [John Caughie]               [Added a field to Draw Note TX to store outstanding receivable FV at time of refinance]
 * [05/13/2019]                [John Caughie]               [Changed PCSRC logic to use a checkbox] 
  =====================================================================*/
global with sharing class ActivateDraw {
       
    webService static Boolean ActivateDrawNoteTX(ID drawId) {
        set<ID> setRecIDs = new set<ID>();
        set<ID> setDrawNoteIDs = new set<ID>();
        list<ID> listDrawNoteIDs = new list<ID>();
        list<Draw_Note_TX__c> lstOldDrawTX = new list<Draw_Note_TX__c>();
        list<Payment_Sub__c> paymentSubList = new list<Payment_Sub__c>();
        list<Payment__c> paymentList = new list<Payment__c>();
        map<ID,Draw_Note_TX__c> FunRecIdToDrTX = new map<ID,Draw_Note_TX__c>();
        list<Funded_Receivable__c> updateFunRecList = new list<Funded_Receivable__c>();

        List<RecordType> recordTypeList = [Select Id,Name,DeveloperName
                                           From RecordType
                                           Where sObjectType = 'Draw_Note__c'
                                           and DeveloperName = 'After_Activation'];
		list<Draw_Note__c> draw = [select name, investor__c, investor__r.name, investor__r.Ownership_Transfer_Borrowing__c, Borrow_Date__c from Draw_Note__c where id=: drawId];
		draw[0].Status__c = 'Active';
        //draw[0].Borrow_Date__c = Date.parse(Date.today().format());                                           //2015.07.09 J Caughie - Prevent auto-update of draw borrow date
        system.debug('record type is '+recordTypeList[0]);
		if(!recordTypeList.isEmpty()){
			draw[0].RecordTypeId = recordTypeList[0].Id;
		}

        list<Draw_Note_TX__c> lstDrawTX = new list<Draw_Note_TX__c>();
        for(Draw_Note_TX__c DrawTX : [select id, Funded_Receivable__c from Draw_Note_TX__c where Draw_Note__c =: drawId]){
        	setRecIDs.add(DrawTX.Funded_Receivable__c);
        	FunRecIdToDrTX.put(DrawTX.Funded_Receivable__c, DrawTX);
        	DrawTX.Status__c = 'Active';
        	lstDrawTX.add(DrawTX);
        }

        update draw[0];

        for(Funded_Receivable__c FunRec : [select id, name, Lien_Holder__c from Funded_Receivable__c where id in : setRecIDs]){
        	//IdToFunRec.put(FunRec.Id,FunRec);
        	Draw_Note_TX__c newDrTX = FunRecIdToDrTX.get(FunRec.Id);
        	//FunRec.Draw_Note_TX__c = newDrTX.Id;
			//if(draw[0].investor__r.name.contains('PCSRC'))             2019.05.13 J Caughie - replaced with checkbox on account
			if(draw[0].investor__r.Ownership_Transfer_Borrowing__c)
            {
				FunRec.PCSRC_Purchase_Date__c = draw[0].Borrow_Date__c;
			}
			FunRec.Lien_Holder__c = draw[0].investor__c;
            //System.debug(draw[0].Id);
            FunRec.Current_Draw_Note__c = draw[0].Id;                                                 //2014.11.07 J Caughie - Added current draw to the Funded Receivable
        	updateFunRecList.add(FunRec);
        }

        if(!updateFunRecList.IsEmpty()){
        	update updateFunRecList;
        }

        map<Id, list<Draw_Note_TX__c>> mapDrawNoteTx = new map<Id, list<Draw_Note_TX__c>>();

        if(!lstDrawTX.IsEmpty()){
        	update lstDrawTX;
        	for(Draw_Note_TX__c drxOld : [select Amount_Borrowed__c,id,name, Draw_Note__c, Funded_Receivable__r.FV_Amount_Due__c from Draw_Note_TX__c
        								where Funded_Receivable__c in : setRecIDs
        								and Draw_Note__c != : drawId and status__c = 'Active']){
        		drxOld.status__c = 'Refinanced';
                //drxOld.Refinanced_Date__c = System.today();                                             //2014.11.07 J Caughie - Added date stamp to Refinanced DrTx
                drxOld.Refinanced_Date__c = draw[0].Borrow_Date__c;
                drxOld.Refinanced_FV__c = drxOld.Funded_Receivable__r.FV_Amount_Due__c;                 //2016.03.08 J Caughie - Added receivable FV due at point of refinance
        		if(!mapDrawNoteTx.containsKey(drxOld.Draw_Note__c)){
        			mapDrawNoteTx.put(drxOld.Draw_Note__c, new list<Draw_Note_TX__c>());
        		}
        		mapDrawNoteTx.get(drxOld.Draw_Note__c).add(drxOld);
        		lstOldDrawTX.add(drxOld);
        		setDrawNoteIDs.add(drxOld.Draw_Note__c);
        	}
        	update lstOldDrawTX;

        	//calculateInterestOnOldDraws(setDrawNoteIDs);                                                 //2015.08.07 J Caughie - Remove Old Draw Interest Calc. - unnecessary calculation 
        	system.debug('set is ' + setDrawNoteIDs);
        	system.debug('list is ' + listDrawNoteIDs);
        	listDrawNoteIDs.addAll(setDrawNoteIDs);
        	 system.debug('now list is ' + listDrawNoteIDs);
        	  system.debug('list of old drtx is ' + lstOldDrawTX);
        	  Payment_Sub__c paySub;
        	map<Id, Draw_Note__c> drawNotesMap = new map<Id, Draw_Note__c>([Select d.Total_Amount_Borrowed_formula__c, d.Total_Accrued_Interest_Current__c, d.Status__c, d.Prior_Activity_Date__c,
    									d.Principal_Paid__c, d.OwnerId, d.Operating_State__c, d.Note_Rate__c, d.Note_Description__c, d.Name,
    									d.LegacyParentID__c, d.LegacyID__c, d.Last_Pay_Date__c, d.LastActivityDate, d.Investor__c,
										d.Interest_Paid__c, d.Id, d.Edit_Draw_Receivables__c, d.DrawHeaderID__c, d.Borrow_Date__c,
										(Select SystemModstamp, Principal__c, Principal_Paid__c, Payment_Amount__c, Name,
											Interest_Paid__c, Interest_Fwd__c, Id, Ending_Principal__c, Draw_Rate__c, Draw_Note__c,
											Activity_Type__c, Activity_Date__c, Accrued_Interest__c
										From Draw_Entries__r order by activity_Date__c desc limit 1)
									From Draw_Note__c d
									where Principal_Due__c > 0 AND Status__c = 'Active' and Id in :listDrawNoteIDs]);
        	Draw_Note__c drawNote;
        	List<Draw_Entry__c> listDrawEntriesToInsertForPayment = new list<Draw_Entry__c>();
        	Draw_Entry__c newDrawEntry;
        	Draw_Entry__c oldDrawEntry;

        	for(Id oldDrawId : mapDrawNoteTx.keySet()){
        		Decimal paySubAmount = 0;
        		for(Draw_Note_TX__c drtx : mapDrawNoteTx.get(oldDrawId)){
        			system.debug('greywar 3 in loop');
                    if(drtx.Amount_Borrowed__c <> null){
                    	system.debug('amount borrowed  is ' + drtx.Amount_Borrowed__c);
                    	paySubAmount = paySubAmount + drtx.Amount_Borrowed__c;
                    	 system.debug('paysub amount   is ' + paySubAmount);
                    }

        		}

        		paySub = new Payment_Sub__c();
                Date paidDate = Date.parse(Date.today().format());
                paySub.Amount__c = (drawNotesMap.containsKey(oldDrawId) && drawNotesMap.get(oldDrawId).Draw_Entries__r.size() > 0 && drawNotesMap.get(oldDrawId).Draw_Entries__r[0].Interest_Fwd__c <> null) ?
                						paySubAmount + drawNotesMap.get(oldDrawId).Draw_Entries__r[0].Interest_Fwd__c :
                						paySubAmount;
                paySub.Date_Paid__c = paidDate;
                paySub.Paid_To__c = 'Investor';
                paysub.Payment_Against__c = oldDrawId;
                paysub.Payment_Type__c = 'Re-Finance';
                system.debug('payment sub record is' + paySub);
                paymentSubList.add(paySub);
                system.debug('greywar 4');
        	}

        	if (!paymentSubList.isEmpty()){
                system.debug('greywar 5');
                insert paymentSubList;
                system.debug('payment subs saved');

                for(Payment_Sub__c pSub : paymentSubList){
                    Payment__c pay = new Payment__c();
                    pay.Draw_Note__c = pSub.Payment_Against__c;
                    pay.Payment_Amount__c = pSub.Amount__c;
                    pay.Payment_Sub__c = pSub.Id;
                    pay.Payment_Type__c = 'Re-Finance';
                    paymentList.add(pay);
                }

                if(!paymentList.IsEmpty()){
                    system.debug('greywar 6');
                    insert paymentList;
                }

                if(!listDrawEntriesToInsertForPayment.isEmpty()){
                	insert listDrawEntriesToInsertForPayment;
                }

            }
        	return true;
        }
        else{
    		return false;
    	}
    }

    private static void calculateInterestOnOldDraws(set<Id> drawNoteIds){

		List<Draw_Entry__c> listDrawEntriesToInsert = new list<Draw_Entry__c>();
		Draw_Entry__c newDrawEntry;
    	for(Draw_Note__c drawNote : [Select d.Total_Amount_Borrowed_formula__c, d.Total_Accrued_Interest_Current__c, d.Status__c, d.Prior_Activity_Date__c,
    									d.Principal_Paid__c, d.OwnerId, d.Operating_State__c, d.Note_Rate__c, d.Note_Description__c, d.Name,
    									d.LegacyParentID__c, d.LegacyID__c, d.Last_Pay_Date__c, d.LastActivityDate, d.Investor__c,
										d.Interest_Paid__c, d.Id, d.Edit_Draw_Receivables__c, d.DrawHeaderID__c, d.Borrow_Date__c,
										(Select SystemModstamp, Principal__c, Principal_Paid__c, Payment_Amount__c, Name,
											Interest_Paid__c, Interest_Fwd__c, Id, Ending_Principal__c, Draw_Rate__c, Draw_Note__c,
											Activity_Type__c, Activity_Date__c, Accrued_Interest__c
										From Draw_Entries__r order by activity_Date__c desc, Id desc limit 1)
									From Draw_Note__c d
									where Principal_Due__c > 0 AND Status__c = 'Active' and Id in :drawNoteIds]){

			newDrawEntry = DrawInterestCalculationManager.createDrawEntry(drawNote,
																	(drawNote.Draw_Entries__r.size() > 0 ? drawNote.Draw_Entries__r[0] : null) ,
																	null, Date.today());
			if(newDrawEntry <> null){
				listDrawEntriesToInsert.add(newDrawEntry);
			}
		}

		try{
			insert listDrawEntriesToInsert;
		}catch(exception ex){
			system.debug('Exception while inserting draw entries : ' + ex.getMessage());
		}
    }

    /*
        private static BypassRulesandTriggers__c getSystemSetting(){
            return BypassRulesandTriggers__c.getInstance();
        }

        private static void byPassPaymentTrigger(){
            BypassRulesandTriggers__c customSetting = BypassRulesandTriggers__c.getInstance();
            if(customSetting.Trigger_Objects__c == null){
                customSetting.Trigger_Objects__c = 'Payment__c';
            }else if(!customSetting.Trigger_Objects__c.toLowerCase().contains('payment__c')){
                customSetting.Trigger_Objects__c += ';Payment__c';
            }

            customSetting.Triggers_Disabled__c = true;
            upsert customSetting;
        }

        private static void restoreSystemSetting(BypassRulesandTriggers__c systemSetting){
            BypassRulesandTriggers__c customSetting = BypassRulesandTriggers__c.getInstance();
            customSetting.Trigger_Objects__c = systemSetting.Trigger_Objects__c;
            customSetting.Triggers_Disabled__c = systemSetting.Triggers_Disabled__c;
            update customSetting;
        }
    */

	// method to cancel the draw note with Id=drawId
    webservice static void cancelDraw(Id drawId){
		// get list of draw note tx
		List<Draw_Note_TX__c> listDrawNoteTx = [Select Id
											From Draw_Note_TX__c
											where Draw_Note__c = :drawId];

		for(Draw_Note_TX__c drawNoteTx : listDrawNoteTx){
			// set status of draw note tx to cancelled
			drawNoteTx.Status__c = 'Cancelled';
		}

		// set status of draw note to cancelled
		update new Draw_Note__c(Id=drawId, Status__c = 'Cancelled');
		if(!listDrawNoteTx.isEmpty()){
			update listDrawNoteTx;
		}
    }


    webService static Boolean AddDrawNoteTX(ID drawId) {
        set<ID> setRecIDs = new set<ID>();
        set<ID> setDrawNoteIDs = new set<ID>();
        list<ID> listDrawNoteIDs = new list<ID>();
        list<Draw_Note_TX__c> lstOldDrawTX = new list<Draw_Note_TX__c>();
        list<Payment_Sub__c> paymentSubList = new list<Payment_Sub__c>();
        list<Payment__c> paymentList = new list<Payment__c>();
        map<ID,Draw_Note_TX__c> FunRecIdToDrTX = new map<ID,Draw_Note_TX__c>();
        list<Funded_Receivable__c> updateFunRecList = new list<Funded_Receivable__c>();

        list<Draw_Note__c> draw = [select name, investor__c, investor__r.name, investor__r.Ownership_Transfer_Borrowing__c, Borrow_Date__c from Draw_Note__c where id=: drawId];

        list<Draw_Note_TX__c> lstDrawTX = new list<Draw_Note_TX__c>();
        for(Draw_Note_TX__c DrawTX : [select id, Funded_Receivable__c from Draw_Note_TX__c where Draw_Note__c =: drawId and Status__c = 'Draft']){          //2018.01.26 J Caughie - Added draft filter
            setRecIDs.add(DrawTX.Funded_Receivable__c);
            FunRecIdToDrTX.put(DrawTX.Funded_Receivable__c, DrawTX);
            DrawTX.Status__c = 'Active';
            lstDrawTX.add(DrawTX);
        }

        for(Funded_Receivable__c FunRec : [select id, name, Lien_Holder__c from Funded_Receivable__c where id in : setRecIDs]){
            //IdToFunRec.put(FunRec.Id,FunRec);
            Draw_Note_TX__c newDrTX = FunRecIdToDrTX.get(FunRec.Id);
            //FunRec.Draw_Note_TX__c = newDrTX.Id;
            //if(draw[0].investor__r.name.contains('PCSRC'))             2019.05.13 J Caughie - replaced with checkbox on account
            if(draw[0].investor__r.Ownership_Transfer_Borrowing__c)
            {
                FunRec.PCSRC_Purchase_Date__c = draw[0].Borrow_Date__c;
            }
            FunRec.Lien_Holder__c = draw[0].investor__c;
            //System.debug(draw[0].Id);
            FunRec.Current_Draw_Note__c = draw[0].Id;                                                 //2014.11.07 J Caughie - Added current draw to the Funded Receivable
            updateFunRecList.add(FunRec);
        }

        if(!updateFunRecList.IsEmpty()){
            update updateFunRecList;
        }

        map<Id, list<Draw_Note_TX__c>> mapDrawNoteTx = new map<Id, list<Draw_Note_TX__c>>();

        if(!lstDrawTX.IsEmpty()){
            update lstDrawTX;
            for(Draw_Note_TX__c drxOld : [select Amount_Borrowed__c,id,name, Draw_Note__c, Funded_Receivable__r.FV_Amount_Due__c from Draw_Note_TX__c
                                        where Funded_Receivable__c in : setRecIDs
                                        and Draw_Note__c != : drawId and status__c = 'Active']){
                drxOld.status__c = 'Refinanced';
                drxOld.Refinanced_Date__c = System.today();                                             //2014.11.07 J Caughie - Added date stamp to Refinanced DrTx
                drxOld.Refinanced_FV__c = drxOld.Funded_Receivable__r.FV_Amount_Due__c;                 //2016.03.08 J Caughie - Added receivable FV due at point of refinance
                if(!mapDrawNoteTx.containsKey(drxOld.Draw_Note__c)){
                    mapDrawNoteTx.put(drxOld.Draw_Note__c, new list<Draw_Note_TX__c>());
                }
                mapDrawNoteTx.get(drxOld.Draw_Note__c).add(drxOld);
                lstOldDrawTX.add(drxOld);
                setDrawNoteIDs.add(drxOld.Draw_Note__c);
            }
            update lstOldDrawTX;

            system.debug('set is ' + setDrawNoteIDs);
            system.debug('list is ' + listDrawNoteIDs);
            listDrawNoteIDs.addAll(setDrawNoteIDs);
            system.debug('now list is ' + listDrawNoteIDs);
            system.debug('list of old drtx is ' + lstOldDrawTX);
            Payment_Sub__c paySub;
            map<Id, Draw_Note__c> drawNotesMap = new map<Id, Draw_Note__c>([Select d.Total_Amount_Borrowed_formula__c, d.Total_Accrued_Interest_Current__c, d.Status__c, d.Prior_Activity_Date__c,
                                        d.Principal_Paid__c, d.OwnerId, d.Operating_State__c, d.Note_Rate__c, d.Note_Description__c, d.Name,
                                        d.LegacyParentID__c, d.LegacyID__c, d.Last_Pay_Date__c, d.LastActivityDate, d.Investor__c,
                                        d.Interest_Paid__c, d.Id, d.Edit_Draw_Receivables__c, d.DrawHeaderID__c, d.Borrow_Date__c,
                                        (Select SystemModstamp, Principal__c, Principal_Paid__c, Payment_Amount__c, Name,
                                            Interest_Paid__c, Interest_Fwd__c, Id, Ending_Principal__c, Draw_Rate__c, Draw_Note__c,
                                            Activity_Type__c, Activity_Date__c, Accrued_Interest__c
                                        From Draw_Entries__r order by activity_Date__c desc limit 1)
                                    From Draw_Note__c d
                                    where Principal_Due__c > 0 AND Status__c = 'Active' and Id in :listDrawNoteIDs]);
            Draw_Note__c drawNote;
            Draw_Entry__c newDrawEntry;
            Draw_Entry__c oldDrawEntry;

            for(Id oldDrawId : mapDrawNoteTx.keySet()){
                Decimal paySubAmount = 0;
                for(Draw_Note_TX__c drtx : mapDrawNoteTx.get(oldDrawId)){
                    system.debug('greywar 3 in loop');
                    if(drtx.Amount_Borrowed__c <> null){
                        system.debug('amount borrowed  is ' + drtx.Amount_Borrowed__c);
                        paySubAmount = paySubAmount + drtx.Amount_Borrowed__c;
                         system.debug('paysub amount   is ' + paySubAmount);
                    }

                }

                paySub = new Payment_Sub__c();
                Date paidDate = Date.parse(Date.today().format());
                paySub.Amount__c = (drawNotesMap.containsKey(oldDrawId) && drawNotesMap.get(oldDrawId).Draw_Entries__r.size() > 0 && drawNotesMap.get(oldDrawId).Draw_Entries__r[0].Interest_Fwd__c <> null) ?
                                        paySubAmount + drawNotesMap.get(oldDrawId).Draw_Entries__r[0].Interest_Fwd__c :
                                        paySubAmount;
                paySub.Date_Paid__c = paidDate;
                paySub.Paid_To__c = 'Investor';
                paysub.Payment_Against__c = oldDrawId;
                paysub.Payment_Type__c = 'Re-Finance';
                system.debug('payment sub record is' + paySub);
                paymentSubList.add(paySub);
                system.debug('greywar 4');
            }

            if (!paymentSubList.isEmpty()){
                system.debug('greywar 5');
                insert paymentSubList;
                system.debug('payment subs saved');

                for(Payment_Sub__c pSub : paymentSubList){
                    Payment__c pay = new Payment__c();
                    pay.Draw_Note__c = pSub.Payment_Against__c;
                    pay.Payment_Amount__c = pSub.Amount__c;
                    pay.Payment_Sub__c = pSub.Id;
                    pay.Payment_Type__c = 'Re-Finance';
                    paymentList.add(pay);
                }

                if(!paymentList.IsEmpty()){
                    system.debug('greywar 6');
                    insert paymentList;
                }

            }
            return true;
        }
        else{
            return false;
        }
    }

}
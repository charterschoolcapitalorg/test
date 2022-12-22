/**=====================================================================
 * Appirio, Inc
 * Name: DrawRateManager
 * Description: T-275242 : Trigger to fill the note rate field on the Draw Note record with the lastest Draw Rate entry
 * Created Date: [05/02/2014]
 * Created By: [Rajeev Arya] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * 08/10/2017                   John Caughie                 Changed the draw rate sequnecing from Id to start_date__c descending
 =====================================================================*/
public class DrawRateManager {

	public static void DrawRateAfterInsert(List<Draw_Rate__c> lstDR){
		set<ID> drawNoteIDs = new set<ID>();
		//map<ID,list<Draw_Rate__c>> mapDrawNoteIDToRates = new map<ID,list<Draw_Rate__c>>();
		list<Draw_Rate__c> lstDrawRate = new list<Draw_Rate__c>();
		list<Draw_Note__c> lstDrawNote = new list<Draw_Note__c>();
		
		for(Draw_Rate__c drwRate : lstDR){
			drawNoteIDs.add(drwRate.Draw_Note__c);
		}
		
		for(Draw_Note__c drn : [select id, name, (select name, id, start_date__c, Interest_Rate__c from draw_rates__r where end_date__c = null order by start_date__c desc limit 2) 
								from draw_note__c where id in:drawNoteIDs]){
			//mapDrawNoteIDToRates.put(drn.id,drn.draw_rates__r);
			if(drn.draw_rates__r.size()==2){
                	drn.draw_rates__r[1].Bypass_Validation__c = true;
                	drn.draw_rates__r[1].End_Date__c = drn.draw_rates__r[0].Start_Date__c;
                	lstDrawRate.add(drn.draw_rates__r[1]);
                	
                	system.debug('DrawRateList[1]: '+ drn.draw_rates__r[1]);
                	system.debug('DrawRateList[0]: '+ drn.draw_rates__r[0]);
                	//DrawRateList[1].Bypass_Validation__c = false;
                	//update DrawRateList[1];
            }
			drn.Note_Rate__c = drn.draw_rates__r[0].Interest_Rate__c;
            lstDrawNote.add(drn);
		}
		update lstDrawRate;
		update lstDrawNote;
		/*for(Draw_Rate__c drwRate : lstDR){
            //drwRate.End_Date__c = null;
            list<Draw_Rate__c> DrawRateList = [select id, CreatedDate from Draw_Rate__c where Draw_Note__c = : drwRate.Draw_Note__c
            and End_Date__c = null order by Id desc limit 2];

                if(DrawRateList.size()==2){
                	DrawRateList[1].Bypass_Validation__c = true;

                	DrawRateList[1].End_Date__c = drwRate.Start_Date__c;
                	update DrawRateList[1];
                	system.debug('DrawRateList[1]: '+ DrawRateList[1]);
                	system.debug('DrawRateList[0]: '+ DrawRateList[0]);
                	//DrawRateList[1].Bypass_Validation__c = false;
                	//update DrawRateList[1];
                }
        	Draw_Note__c drn = [select id from draw_note__c where id = : drwRate.Draw_Note__c];
        	drn.Note_Rate__c = drwRate.Interest_Rate__c;
        	update drn;
        }
		*/
	}

}
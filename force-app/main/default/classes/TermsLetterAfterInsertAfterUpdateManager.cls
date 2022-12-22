/**=====================================================================
 * Trigger Name: ProgramFeeTrigger
 * Description: Trigger to update Program Fee dates after active Terms Letter date change
 * Created Date: [06/17/2015]
 * Created By: John Caughie
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
public class TermsLetterAfterInsertAfterUpdateManager {
    
    public static void updateChildProgramFeeDates(map<Id, Terms_Letter__c> newMap, map<Id, Terms_Letter__c> oldMap){
           
        List<Terms_Letter__c> tls = new List<Terms_Letter__c>();
        tls = newMap.values();

        List<Terms_Letter__c> activeTLs = new List<Terms_Letter__c>();
        //Filter active maps only
        for(Terms_Letter__c t : tls){
            if(t.Status__c == 'Active'){
                activeTLs.add(t);
            }
        }
        system.debug('active tls ' + activeTLs);

        //work on active TLS
        if(activeTLs.size() != 0){

            //Set of TL Ids that are in the trigger
            set<ID> updatedTLIDs = new set<ID>();
            updatedTLIDs = newMap.keySet();
            System.debug('here1 '+ updatedTLIDs);

            //List of needed PF records
            list<Program_Fee__c> relatedPFs = new list<Program_Fee__c>();
            relatedPFs = [SELECT Program_Fee__c, Start_Date__c, End_Date__c, Terms_Letter__c
                                FROM Program_Fee__c 
                                WHERE Terms_Letter__c in :updatedTLIDs
                                AND Terms_Letter__r.Count_Of_Program_Fees__c = 1];

            //Map of TL Id to PF Record
            Map<Id, Program_Fee__c> mapTermsLetterIdtoProgFee = new Map<Id, Program_Fee__c>();

            for(Program_Fee__c pf : relatedPFs) {
                mapTermsLetterIdtoProgFee.put(pf.Terms_Letter__c, pf);
            }
            System.debug('here2 '+ mapTermsLetterIdtoProgFee);
            System.debug('here2a '+ newMap);

            //List of PF records to update
            list<Program_Fee__c> listPFsToUpdate = new list<Program_Fee__c>();


            for(Id termsID : newMap.keySet()){
                if(newMap.get(termsID).Status__c.equalsIgnoreCase('Active') && newMap.get(termsID).Count_Of_Program_Fees__c == 1 && 
                    (newMap.get(termsID).Termination_Date__c != mapTermsLetterIdtoProgFee.get(termsID).End_Date__c 
                        || newMap.get(termsID).Initial_Close_Date__c != mapTermsLetterIdtoProgFee.get(termsID).Start_Date__c)){

                                    Program_Fee__c pf = new Program_Fee__c();
                                    pf.Id = mapTermsLetterIdtoProgFee.get(termsID).Id;
                                    pf.Start_Date__c = newMap.get(termsID).Initial_Close_Date__c;
                                    pf.End_Date__c = newMap.get(termsID).Termination_Date__c;
                                    listPFsToUpdate.add(pf);

                }
            }
            System.debug('here3 '+ listPFsToUpdate);
            update listPFsToUpdate;

        }
    }
}
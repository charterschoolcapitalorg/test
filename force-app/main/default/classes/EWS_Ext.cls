/**=====================================================================
 * Name: EWS_Ext Class
 * Description: Extension for activating EWS record
 * Created Date: [03/22/2016]
 * Created By: John Caughie
 *
 * Date Modified            Modified By                 Description of the update
 * 2017.02.17               John Caughie                Added Activated/Deactivated date stamps
  =====================================================================*/

public with sharing class EWS_Ext {
	
	public EWS__c ewsRecord {get; set;}
    private Map<String, Id> ewsRecordTypes = new Map<String, Id>(RecordTypeUtils.getsObjectRecordMap('EWS__c'));

	
    public EWS_Ext(){

    }

    //constructor: current record
	public EWS_Ext(ApexPages.StandardController controller) {
		
        sObject obj= (sObject)controller.getRecord();
        String objType =  String.valueOf(obj.getSObjectType());
        if(objType == 'EWS__c'){
            ewsRecord = (EWS__c) obj;
        }
	}

	
    public PageReference updateRecordStatus() {

		List<EWS__c> listRecordsToUpdate = new List<EWS__c>();

		//make current record active & add to list
		if(!ewsRecord.Active__c){
			ewsRecord.Active__c = true;
            ewsRecord.RecordTypeId = ewsRecordTypes.get(ewsRecord.RecordType.DeveloperName + '_Activated');
            ewsRecord.Date_Activated__c = Date.today();
			listRecordsToUpdate.add(ewsRecord);
		} else {
            return new Pagereference('/' + ewsRecord.id);
        }

		//deactivate existing records & add to list
        String SOQL = 'SELECT id, Is_Active__c FROM EWS__c WHERE id != \'' + ewsRecord.id + '\'';
        SOQL += ' AND Account__c = \'';
        SOQL += (ewsRecord.Account__c + '\'');
        SOQL += ' AND RecordType.DeveloperName like \'';
        SOQL += (ewsRecord.RecordType.DeveloperName + '%\'');
        SOQL += ('AND Active__c = TRUE');

        System.debug('SOQL: ' + SOQL);

        for(EWS__c e : Database.query(SOQL)){
            e.Active__c = false;
            e.Date_Deactivated__c = Date.today();
            listRecordsToUpdate.add(e);
        }
        
        //update system if records in list
        if(listRecordsToUpdate.size() > 0){
            update listRecordsToUpdate;
        }
        return new Pagereference('/'+ewsRecord.id);
	}

    @InvocableMethod(label='Activate current EWS record' description='Updates the current EWS record to active and deactivates any others.')
    public static void activateRecord(List<Id> recordId){
        
        System.debug('the record: ' + recordId[0]);
        EWS_Ext et = new EWS_Ext();
        if(et.ewsRecord == null){
            et.ewsRecord = [SELECT Id, Is_Active__c, Active__c, RecordType.DeveloperName, Account__c FROM EWS__c WHERE Id =:recordId[0] ];
        }
        et.updateRecordStatus();
    }

}
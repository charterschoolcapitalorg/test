/**=====================================================================
 * Appirio, Inc
 * Name: ReceivableTypeDeepCloneController
 * Description: T-278593 : Receivable Type "Full Clone" tool
 * Created Date: [05/14/2014]
 * Created By: [Manisha Gupta] (Appirio)
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 *  Mar 03, 2017				John Caughie				 Added Receivable_Representative_Date__c increment
 =====================================================================*/
public class ReceivableTypeDeepCloneController {

	private Receivable_Type__c receivableTypeToClone;
	public Integer incrementPayoutDateYears{get;set;}
	public Receivable_Type__c clonedReceivableType{get;set;}
	public boolean parentAsDeduction{get;set;}
	private Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

	public ReceivableTypeDeepCloneController(ApexPages.StandardController sc){
		receivableTypeToClone = (Receivable_Type__c)getSObjectList('Receivable_Type__c', 'Id', sc.getId())[0];
		clonedReceivableType = receivableTypeToClone.clone(false, true);
		incrementPayoutDateYears = 0;
		parentAsDeduction = false;
	}

	public Pagereference executeDeepClone(){
		try{
			insert clonedReceivableType;
			List<sObject> lstSourceChildCalculations = getSObjectList('Calculation__c', 'Receivable_Type__c', receivableTypeToClone.Id);
			list<Calculation__c> listClonedChildCalculation = (list<Calculation__c>)lstSourceChildCalculations.deepClone();
			for(Calculation__c childCalculation : listClonedChildCalculation){
				childCalculation.Receivable_Type__c = clonedReceivableType.Id;
			}

			insert listClonedChildCalculation;


			map<Id,Id> mapSourceClonedCalId = new map<Id,Id>();
			for(Integer i = 0; i < listClonedChildCalculation.size(); i++){
				mapSourceClonedCalId.put(lstSourceChildCalculations[i].Id, listClonedChildCalculation[i].Id);
			}
			//map<Id, List<Payout_Date__c>> mapSourceCalcIdPayoutDateList = new map<Id, List<Payout_Date__c>>();
			list<Payout_Date__c> listClonedPayoutDate = new list<Payout_Date__c>();
			Payout_Date__c clonedPayoutDate;
			for(Payout_Date__c payout : getListChildPayoutDate(mapSourceClonedCalId.keySet())){
				clonedPayoutDate = payout.clone();
				clonedPayoutDate.Calculation__c = mapSourceClonedCalId.get(payout.Calculation__c);
				if(parentAsDeduction){
					clonedPayoutDate.Deduct_from_Payout_Date__c = payout.Id;
				}else{
					clonedPayoutDate.Deduct_from_Payout_Date__c = null;
				}
				if(incrementPayoutDateYears > 0){
					clonedPayoutDate.Default_Payout_Date__c = payout.Default_Payout_Date__c.addYears(incrementPayoutDateYears);
					clonedPayoutDate.Default_Distribution_Date__c = payout.Default_Distribution_Date__c.addYears(incrementPayoutDateYears);
					clonedPayoutDate.Receivable_Representative_Date__c = (clonedPayoutDate.Receivable_Representative_Date__c != null ? payout.Receivable_Representative_Date__c.addYears(incrementPayoutDateYears) : clonedPayoutDate.Receivable_Representative_Date__c);
				}else{
					clonedPayoutDate.Default_Payout_Date__c = payout.Default_Payout_Date__c;
					clonedPayoutDate.Default_Distribution_Date__c = payout.Default_Distribution_Date__c;
					clonedPayoutDate.Receivable_Representative_Date__c = payout.Receivable_Representative_Date__c;
				}
				listClonedPayoutDate.add(clonedPayoutDate);
			}

			insert listClonedPayoutDate;

			return new pagereference('/'+clonedReceivableType.Id);
		}catch(exception ex){
			apexPages.addMessage(new ApexPages.Message(Apexpages.Severity.Error,ex.getMessage()));
		}
		return null;

	}

	private list<Payout_Date__c> getListChildPayoutDate(set<Id> listSourceCalcIds){
		String query = 'SELECT ' + String.Join(getAccessibleFields('Payout_Date__c'),',') +
						' FROM Payout_Date__c' +
						' WHERE Calculation__c' + ' in :listSourceCalcIds';
	    List<Payout_Date__c> lstPayoutDate = Database.query(query);
	    return lstPayoutDate;
	}


	private List<sObject> getSObjectList(String objectApiName, String referenceField, String referenceFieldValue){
		String query = 'SELECT ' + String.Join(getAccessibleFields(objectApiName),',') +
						' FROM ' + objectApiName +
						' WHERE ' + referenceField + ' = \'' + referenceFieldValue + '\'';
	    List<sObject> lstSObject = Database.query(query);
	    return lstSObject;
	}

	private List<String> getAccessibleFields(String objectApiName){
    	List<String> lstFields = new List<String>();
	    Map<String, Schema.SObjectField> field_map = globalDescribe.get(objectApiName).getDescribe().getSObjectType().getDescribe().fields.getMap();
	    for(Schema.SObjectField sObject_Field : field_map.values()){
	    	Schema.DescribeFieldResult field = sObject_Field.getDescribe();
	      	if(field.isAccessible()){
	        	lstFields.add(field.getName());
	      	}
    	}
    	return lstFields;
  	}

}
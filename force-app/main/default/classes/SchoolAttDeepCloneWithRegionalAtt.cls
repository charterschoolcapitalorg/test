/**=====================================================================
 * Name: SchoolAttDeepCloneWithRegionalAtt
 * Description: School Attendance Type "Full Clone" tool (project 2014.11.17)
 * Created Date: [02/10/2015]
 * Created By: [John Caughie]
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 =====================================================================*/

public class SchoolAttDeepCloneWithRegionalAtt {

    private School_Attendance__c schoolAttToClone;
	public School_Attendance__c clonedSchoolAtt {get;set;}

	private Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    // initialize the controller
    public SchoolAttDeepCloneWithRegionalAtt(ApexPages.StandardController sc) {
    	schoolAttToClone = (School_Attendance__c)getSObjectList('School_Attendance__c', 'Id', sc.getId())[0];
    	clonedSchoolAtt = schoolAttToClone.clone(false, true, false, false);
    	clonedSchoolAtt.Active__c = false;
    }

    // method called from the VF's action attribute to clone the School Attendance record
    public PageReference cloneWithRegionalAtt() {
		try{
			insert clonedSchoolAtt;

			List<sObject> lstSourceRegionalAttendanceRecords = getSObjectList('Regional_Attendance__c', 'School_Attendance__c', schoolAttToClone.Id);
			list<Regional_Attendance__c> listClonedRegionalAttendanceRecords = (list<Regional_Attendance__c>)lstSourceRegionalAttendanceRecords.deepClone();
			for(Regional_Attendance__c childRegionals : listClonedRegionalAttendanceRecords){
				childRegionals.School_Attendance__c = clonedSchoolAtt.Id;
			}

			insert listClonedRegionalAttendanceRecords;

			return new pagereference('/'+ clonedSchoolAtt.Id);
		}catch(exception ex){
			apexPages.addMessage(new ApexPages.Message(Apexpages.Severity.Error,ex.getMessage()));
		}
		return null;

    }

    // helper method to query the child object for records related to the id passed in
	private List<sObject> getSObjectList(String objectApiName, String referenceField, String referenceFieldValue){
		String query = 'SELECT ' + String.Join(getAccessibleFields(objectApiName),',') +
						' FROM ' + objectApiName +
						' WHERE ' + referenceField + ' = \'' + referenceFieldValue + '\'';
	    List<sObject> lstSObject = Database.query(query);
	    return lstSObject;
	}

	// method to get a list of available fields on the parameter object
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
/**=====================================================================
 * Class Name: SchoolAttendanceManager
 * Description: Manager class for Trigger on School_Attendance__c
 * Created Date: [2015/01/25]
 * Created By: John Caughie
 * Date Modified                Modified By                  Description of the update
 * 2016.02.22					John Caughie				Filtered out active attendance records for closed schools
 =====================================================================*/

public class SchoolAttendanceTriggerManager {

	public static void updateCharters(List<School_Attendance__c> listAttendance){
		
		//Filter for schools associated with Att records that were made active, ie if it's not active it doesn't matter
		Set<Id> setSchools = new Set<Id>();
		for(School_Attendance__c sa : listAttendance){
			if(sa.Active__c == true){
				setSchools.add(sa.School__c);
			}
		}

		System.debug('set size ' + setSchools.size());
		if(setSchools.size() > 0){
			Set<Id> setCharterIds = new Set<Id>();
			for(Account a : [SELECT Charter_Holder__c FROM Account WHERE id IN :setSchools]){
				setCharterIds.add(a.Charter_Holder__c);
			}
			System.debug(setCharterIds);

			updateCharterAttendanceTotal(setCharterIds);
		}
	}

	private static void updateCharterAttendanceTotal(Set<Id> charterIds){

		//List of all active attendances for schools with Charter in list
		List<School_Attendance__c> listSA = new List<School_Attendance__c>();
		listSA = [SELECT School__r.Charter_Holder__c, Total_Attendance__c FROM School_Attendance__c WHERE School__r.Charter_Holder__c IN :charterIds AND Active__c = TRUE AND School__r.Account_Status__c != 'Closed'];
		System.debug(listSA.size());
		System.debug(listSA);

		//Calculate attendance for each Charter
		List<Account> charterAttendance = new List<Account>();
		for(Id charterId : charterIds){
		    Decimal attendance = 0;
		    for(School_Attendance__c sa : listSA){
		        if(charterId == sa.School__r.Charter_Holder__c){
		            attendance += sa.Total_Attendance__c;
		        }
		    }
		    charterAttendance.add(new Account(id = charterId, Total_Active_Attendance__c = attendance));
		}
		System.debug(charterAttendance);

		//Update Charters
		Database.SaveResult[] srList = Database.update(charterAttendance, false);
		System.debug(srList);
	}    

}
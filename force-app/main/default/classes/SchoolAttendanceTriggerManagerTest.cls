/**=====================================================================
 * Name: SchoolAttendanceTriggerManagerTest
 * Description: Test funcitonality of SchoolAttendanceTriggerManager.cls
 * Created Date: 2015/01/26
 * Created By: John Caughie
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
@isTest
public class SchoolAttendanceTriggerManagerTest {

	static testmethod void testSingleCharter(){
		
		Map<Account, List<Account>> charterToSchools = new Map<Account, List<Account>>();
		
		//One charter five schools
		charterToSchools = CreateCharterSchoolTestData(1, 5);

		//Five attendance records per school
		Test.startTest();
		for(Account a : charterToSchools.keySet()){
			CreateSchoolAttendance(charterToSchools.get(a), 5, 100);
		}
		Test.stopTest();

		List<Account> updatedCharters = new List<Account>();
		updatedCharters = [SELECT Name, Total_Active_Attendance__c FROM Account WHERE ID IN :charterToSchools.keySet()];
		System.debug('finished' + updatedCharters);
		System.assertEquals(500, updatedCharters[0].Total_Active_Attendance__c, 'Five active schools at 100 each');

	}

	private static testmethod void testSingleCharterDeleteActive(){
		
		Map<Account, List<Account>> charterToSchools = new Map<Account, List<Account>>();
		
		//One charter five schools
		charterToSchools = CreateCharterSchoolTestData(1, 5);

		//Five attendance records per school
		Test.startTest();
		for(Account a : charterToSchools.keySet()){
			CreateSchoolAttendance(charterToSchools.get(a), 5, 100);
		}

		List<School_Attendance__c> inactiveSchAtt = new List<School_Attendance__c>();
		inactiveSchAtt = [SELECT Id, Active__c FROM School_Attendance__c WHERE Active__c = true LIMIT 1];
		delete inactiveSchAtt;
		Test.stopTest();		

		List<Account> updatedCharters = new List<Account>();
		updatedCharters = [SELECT Name, Total_Active_Attendance__c FROM Account WHERE ID IN :charterToSchools.keySet()];
		System.debug('finished' + updatedCharters);
		System.assertEquals(400, updatedCharters[0].Total_Active_Attendance__c, 'Four active schools at 100 each');

		List<School_Attendance__c> listSchAtt = new List<School_Attendance__c>();
		listSchAtt = [SELECT Id, Active__c FROM School_Attendance__c];
		System.assertEquals(24, listSchAtt.size(), 'Five schools at five each less one deleted');

	}

	private static testmethod void testFiveCharters(){
		
		Map<Account, List<Account>> charterToSchools = new Map<Account, List<Account>>();
		
		//Five charters ten schools
		charterToSchools = CreateCharterSchoolTestData(5, 10);

		//Ten attendance records per school
		Test.startTest();
		for(Account a : charterToSchools.keySet()){
			CreateSchoolAttendance(charterToSchools.get(a), 10, 100);
		}
		Test.stopTest();

		List<Account> updatedCharters = new List<Account>();
		updatedCharters = [SELECT Name, Total_Active_Attendance__c FROM Account WHERE ID IN :charterToSchools.keySet()];
		System.debug('finished' + updatedCharters);
		System.assertEquals(1000, updatedCharters[0].Total_Active_Attendance__c, 'Ten active schools at 100 each');
		System.assertEquals(1000, updatedCharters[1].Total_Active_Attendance__c, 'Ten active schools at 100 each');
		System.assertEquals(1000, updatedCharters[2].Total_Active_Attendance__c, 'Ten active schools at 100 each');
		System.assertEquals(1000, updatedCharters[3].Total_Active_Attendance__c, 'Ten active schools at 100 each');
		System.assertEquals(1000, updatedCharters[4].Total_Active_Attendance__c, 'Ten active schools at 100 each');

	}

	private Static List<School_Attendance__c> CreateSchoolAttendance(List<Account> schools, Integer records, Integer baseAtt){

		List<School_Attendance__c> attRecords = new List<School_Attendance__c>();

		for(Account a : schools){
			for(Integer i = 0; i < records; i++){
				School_Attendance__c sa = new School_Attendance__c();
				if(i == 0){
					sa.Active__c  = true;
				}
				sa.School__c = a.Id;
				sa.Total_Attendance_manual__c = baseAtt + i;
				sa.Report_Date__c = Date.today();
				sa.Is_Bulk_Upload__c = true;
				attRecords.add(sa);
			}
		}

		insert attRecords;
		System.debug(attRecords);
		return null;

	}

	private Static Map<Account, List<Account>> CreateCharterSchoolTestData(Integer charters, Integer charterSchools){
		
		Map<Account, List<Account>> charterToSchools = new Map<Account, List<Account>>();
		List<Account> listCharters = new List<Account>();
		List<Account> listSchools = new List<Account>();

		//Create Charters
		for(Integer i = 0; i < charters; i++){
			Account a = new Account();
			a.name = 'Test Charter - ' + (i + 1);
			listCharters.add(a);
		}
		insert listCharters;

		//Create Schools for each Charter
		for(Integer i = 0; i < charters; i++){
			List<Account> schools = new List<Account>();
			for(Integer j = 0; j < charterSchools; j++){
				Account s = new Account();
				s.name = 'Test School - ' + (j + 1);
				s.Charter_Holder__c = listCharters[i].id;
				s.Account_Status__c = 'Active';
				listSchools.add(s);
				schools.add(s);
			}
			charterToSchools.put(listCharters[i], schools);
		}
		insert listSchools;

		return charterToSchools;
	}
}
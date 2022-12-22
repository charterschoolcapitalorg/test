/**=====================================================================
 * Name: TestHelperBulk
 * Description: Test helper class
 * Created Date: [03/22/2017]
 * Created By: [John Caughie]
 *
 * Date Modified            Modified By                 Description of the update
 * [dd/mm/yyyy]            [name]              			[details]

 =====================================================================*/

public class TestHelperBulk {

	private static map<String,RecordType> rtMap = new map<String,RecordType>(); 


	public static Map<String, List<Account>> createCharterSchoolStructure(Integer numCharters, Integer numSchools){
		
		Map<String, List<Account>> charterToSchoolsMap = new Map<String, List<Account>>();
		Id charterTypeId, schoolTypeId;
		rtMap = TestHelper.createRecordTypeMap();
		List<Account> charters = new List<Account>();
		List<Account> schools = new List<Account>();

		charterTypeId = rtMap.get('Charter_Holder').Id;
		schoolTypeId = rtMap.get('School').Id;

		for(Integer i = 0; i < numCharters; i++){
			charters.add(new Account(RecordTypeId = charterTypeId, Name = 'Charter Holder ' + i));
		} 
		insert charters;

		for(Integer i = 0; i < numCharters; i++){
			for(Integer j = 0; j < numSchools; j++){
				schools.add(new Account(RecordTypeId = schoolTypeId, Name = 'School ' + j, Charter_Holder__c = charters[i].Id));
			}
		}
		insert schools;

		for(Account a : schools){
			charterToSchoolsMap.put('Schools', schools);
		}

		for(Account a : charters){
			charterToSchoolsMap.put('Charters', charters);
		}
		//System.debug(charterToSchoolsMap);
		return charterToSchoolsMap;
	}

	public static Map<String, RPA__c> createCharterRPAs(List<Account> charters){

		Map<String, RPA__c> charterIdtoRpaMap = new Map<String, RPA__c>();
		List<RPA__c> rpas = new List<RPA__c>();
		for(Account a : charters){
			rpas.add(new RPA__c(Account__c = a.Id));
		}

		insert rpas;

		for(RPA__c rpa : rpas){
			charterIdtoRpaMap.put(rpa.Account__c, rpa);
		}
		return charterIdtoRpaMap;

	}

}
@IsTest
public class TestObjectFactory {

    public static final String ACCOUNT_RT_DEVNAME_SCHOOL = 'School';
    public static final String ACCOUNT_RT_DEVNAME_CHARTER = 'Charter_Holder';
    public static final Map<String, Map<Id, RecordType>> REC_TYPE_MAP;

    private static Id accRtIdSchool;
    private static Id accRtIdCharter;

    static {
        REC_TYPE_MAP = new Map<String, Map<Id, RecordType>>();
        for (RecordType rt : [SELECT Id, Name, DeveloperName, SObjectType FROM RecordType]) {
            if (!REC_TYPE_MAP.containsKey(rt.SObjectType)) REC_TYPE_MAP.put(rt.SObjectType, new Map<Id, RecordType>());
            REC_TYPE_MAP.get(rt.SObjectType).put(rt.Id, rt);
        }
    }

    private static Integer counter = 0;
	
	public static String getUniqueName(String prefix) {
		return prefix + counter++;
	}

	public static String getRepeatName(String prefix) {
		return prefix + (counter-1);
	}

	public static User getSysAdmin() {
		return getUserForProfile('System Administrator');
	}

	public static User getUserForProfile(String profileName) {
		Profile prof = [SELECT Id FROM Profile WHERE Name = :profileName LIMIT 1];
		return getUserForProfileId(prof.Id);
	} 

	public static User getUserForProfileId(Id profileId) {
		String name = getUniqueName('User');
		String email = name + '@csc.example.com';
		User u = new User(
			Username = email,
			LastName = name,
			CommunityNickname = getUniqueName('nick'),
			Alias = 'testuser',
			Email = email,
			ProfileId = profileId,
			TimeZoneSidKey = 'America/New_York',
			EmailEncodingKey='UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US'
		);
		return u;
	}

    public static State_Province__c getState() {
		return new State_Province__c(
			Name = 'MI'
		);
	}

    public static Account getSchool() {
		return new Account(
			Name = getUniqueName('Acct'),
            RecordTypeId = getAccRtIdSchool()
		);
	}

    public static Account getCharter() {
		return new Account(
			Name = getUniqueName('Acct'),
            RecordTypeId = getAccRtIdCharter()
		);
	}

    public static School_Attendance__c getStudentCount(Account school) {
		return new School_Attendance__c(
			School__c = school.Id
		);
	}

    public static Pricing_Rate__c getPricingRate(Account school) {
		return new Pricing_Rate__c(
			School__c = school.Id
		);
	}

    public static Market_Rate__c getMarketRate() {
		return new Market_Rate__c(
			One_Month_Index_Rate__c = 9,
            Three_Month_Index_Rate__c = 9.5,
            Six_Month_Index_Rate__c = 9.2,
            Current_Monthly_Rate__c = true,
			Reporting_Date__c = Date.newInstance(2022, 9, 25)
		);
	}

    public static Id getAccRtIdSchool() {
        if (accRtIdSchool==null) {
            for (RecordType rt : REC_TYPE_MAP.get('Account').values()) {
                if (rt.DeveloperName==ACCOUNT_RT_DEVNAME_SCHOOL) accRtIdSchool = rt.Id;
            }
        }
        return accRtIdSchool;
    }

    public static Id getAccRtIdCharter() {
        if (accRtIdCharter==null) {
            for (RecordType rt : REC_TYPE_MAP.get('Account').values()) {
                if (rt.DeveloperName==ACCOUNT_RT_DEVNAME_CHARTER) accRtIdCharter = rt.Id;
            }
        }
        return accRtIdCharter;
    }
}
@IsTest
public class PricingRateTriggerHandlerTest {

    static Account testSchool;
    static List<Account> testSchools;
    static Pricing_Rate__c testPR;
    static List<Pricing_Rate__c> testPRs;

	static Account charterHolder, school1;
    static Pricing_Rate__c testPortfRescored;
    static Pricing_Rate__c testPortfNotRescored;
    static Pricing_Rate__c testPortfolioPRLocked;
    static Pricing_Rate__c testSchoolPR;

    static void setup() {
        charterHolder = new Account(Name = 'Charter Holder', RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id);
		insert charterHolder;

		school1 = new Account(Name = 'School',Charter_Holder__c = charterHolder.Id, ParentId = charterHolder.Id, RecordTypeId = RecordTypeUtils.AccountSchool.Id, Pricing_Rate_Inclusion_Override__c = true);
		insert school1;

        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        insert mr;

        testSchoolPR = new Pricing_Rate__c(
            Account__c = school1.id, 
            Market_Rate__c = mr.Id, 
            Stage__c = 'Active', 
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('Portfolio').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Rescored__c = true,
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert testSchoolPR;

        testPortfRescored = new Pricing_Rate__c( 
            Account__c = charterHolder.id,
            Market_Rate__c = mr.Id,
            Stage__c = 'Draft',
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('Portfolio').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Rescored__c = true,
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert testPortfRescored;

        testPortfNotRescored = new Pricing_Rate__c( 
            Account__c = charterHolder.id,
            Market_Rate__c = mr.Id,
            Stage__c = 'Draft',
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('Portfolio').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert testPortfNotRescored;

        testPortfolioPRLocked = new Pricing_Rate__c( 
            Account__c = charterHolder.id,
            Market_Rate__c = mr.Id,
            Stage__c = 'Active',
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('Portfolio').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert testPortfolioPRLocked;

    }

    @IsTest
	static void portfolioRescoredActivation() { 
        setup();
        testPortfRescored.Stage__c = 'Active';
        update testPortfRescored;
    }

    @IsTest
	static void portfolioNotRescoredActivation() { 
        setup();
        testPortfNotRescored.Stage__c = 'Active';
        update testPortfNotRescored;
    }

    @IsTest
	static void changeLockedRecord() { 
        setup();
        testPortfolioPRLocked.Student_Count_1_FY_Prior__c = 22;
        update testPortfolioPRLocked;
    }

}
@IsTest
public with sharing class MarketRateTriggerHandlerTest {

    static Account charterHolderPortfolio, schoolPortfolioOne, schoolPortfolioTwo, charterHolderSchool, schoolSingle;
    static Pricing_Rate__c prPortfolio, prPortfolioOne, prPortfolioTwo, prSchool;
    static Market_Rate__c draft;

    static void setup() {

        Market_Rate__c mr = TestObjectFactory.getMarketRate();
        insert mr;

        // create a portfolio
        charterHolderPortfolio = new Account(
            Name = 'Charter Holder Portfolio', 
            RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id);
		insert charterHolderPortfolio;

        schoolPortfolioOne = new Account(
            Name = 'School One', 
            Charter_Holder__c = charterHolderPortfolio.Id, 
            ParentId = charterHolderPortfolio.Id, 
            RecordTypeId = RecordTypeUtils.AccountSchool.Id, 
            Pricing_Rate_Inclusion_Override__c = true);
		insert schoolPortfolioOne;

        schoolPortfolioTwo = new Account(
            Name = 'School One', 
            Nick_Name__c = 'SO',
            Charter_Holder__c = charterHolderPortfolio.Id, 
            ParentId = charterHolderPortfolio.Id, 
            RecordTypeId = RecordTypeUtils.AccountSchool.Id, 
            Pricing_Rate_Inclusion_Override__c = true);
		insert schoolPortfolioTwo;

        prPortfolio = new Pricing_Rate__c(
            Account__c = charterHolderPortfolio.id, 
            Market_Rate__c = mr.Id, 
            Stage__c = 'Active', 
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('Portfolio').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Rescored__c = true,
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert prPortfolio;

        prPortfolioOne = new Pricing_Rate__c(
            Account__c = schoolPortfolioOne.id, 
            Market_Rate__c = mr.Id, 
            Stage__c = 'Active', 
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('School').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Rescored__c = true,
            Portfolio_Rate_Record__c = prPortfolio.id,
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert prPortfolioOne;

        prPortfolioTwo = new Pricing_Rate__c(
            Account__c = schoolPortfolioTwo.id, 
            Market_Rate__c = mr.Id, 
            Stage__c = 'Active', 
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('School').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Rescored__c = true,
            Portfolio_Rate_Record__c = prPortfolio.id,
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert prPortfolioTwo;

        // create a school
        charterHolderSchool = new Account(
            Name = 'Charter Holder School', 
            RecordTypeId = RecordTypeUtils.AccountCharterHolder.Id);
		insert charterHolderSchool;

		schoolSingle = new Account(
            Name = 'School',
            Charter_Holder__c = charterHolderSchool.Id, 
            ParentId = charterHolderSchool.Id, 
            RecordTypeId = RecordTypeUtils.AccountSchool.Id, 
            Pricing_Rate_Inclusion_Override__c = true);
		insert schoolSingle;

        prSchool = new Pricing_Rate__c(
            Account__c = schoolSingle.id, 
            Market_Rate__c = mr.Id, 
            Stage__c = 'Active', 
            RecordTypeId = Schema.SObjectType.Pricing_Rate__c.getRecordTypeInfosByDeveloperName().get('School').getRecordTypeId(),
            Reporting_Month__c = 'Sep',
            Rescored__c = true,
            Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert prSchool;

        // create new market rate in draft
        draft = new Market_Rate__c(
            Stage__c = 'Draft',
			One_Month_Index_Rate__c = 9,
            Three_Month_Index_Rate__c = 9.5,
            Six_Month_Index_Rate__c = 9.2,
            Current_Monthly_Rate__c = true,
			Reporting_Date__c = Date.newInstance(2022, 9, 25));
        insert draft;
    }

    @IsTest
    static void activateMarketRate() {
        setup();
        Assert.areEqual(1, [SELECT COUNT() FROM Pricing_Rate__c WHERE Account__c = :schoolSingle.id], 'This account should have one Pricing Rate');
        Market_Rate__c active = [SELECT Id, Name, Stage__c FROM Market_Rate__c WHERE id = :draft.id];
        active.Stage__c = 'Active';
        update active;
        Assert.areEqual(2, [SELECT COUNT() FROM Pricing_Rate__c WHERE Account__c = :schoolSingle.id], 'This account should have two Pricing Rates');
        Assert.areEqual(1, [SELECT COUNT() FROM Pricing_Rate__c WHERE Account__c = :schoolSingle.id AND Stage__c = 'Active'], 'This account should have one Active Pricing Rate');
    }
}
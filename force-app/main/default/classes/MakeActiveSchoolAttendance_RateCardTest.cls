//
// (c) 2014 Appirio, Inc.
//
// A Test class for MakeActiveSchoolAttendance_RateCardCont class
//
//  May 12, 2014   Anjali K(JDC)       Original
//
@isTest
private class MakeActiveSchoolAttendance_RateCardTest {

	static testMethod void testMakeActiveSchoolAttendance() {
		Account testAcc = new Account(NAme='testAcc');
		insert testAcc;
		List<School_Attendance__c> schoolAttendanceList = new List<School_Attendance__c>();

		schoolAttendanceList.add(TestHelper.createSchoolAttendance(testAcc));
		schoolAttendanceList.add(TestHelper.createSchoolAttendance(testAcc));

		PageReference pPageReference = Page.MakeActiveSchoolAttendance_VF;
		Test.setCurrentPage(pPageReference);

		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(schoolAttendanceList[0]);
		MakeActiveSchoolAttendance_RateCardCont cont = new MakeActiveSchoolAttendance_RateCardCont(sc);
		cont.makeCurrentSchoolAttendanceActive();

		schoolAttendanceList = [Select id, Active__c from School_Attendance__c where id in :schoolAttendanceList];
		System.assertEquals(schoolAttendanceList[0].Active__c, true);
		System.assertEquals(schoolAttendanceList[1].Active__c, false);
	}

	static testMethod void testMakeActiveRateCard() {
		Account testAcc = new Account(Name='testAcc');
		insert testAcc;
		State_Province__c stateProvince = TestHelper.createStateProvince('USA', true);
		List<Rate_Card__c> rateCards = new List<Rate_Card__c>();
		rateCards.add(TestHelper.createRateCard(stateProvince.Id, null, false, false));
		rateCards.add(TestHelper.createRateCard(null, testAcc.id, false, false));
		rateCards.add(TestHelper.createRateCard(stateProvince.Id, null, true, false));
		rateCards.add(TestHelper.createRateCard(null, testAcc.id, true, false));

		insert rateCards;

		PageReference pPageReference = Page.MakeActiveRateCard_VF;
		Test.setCurrentPage(pPageReference);

		ApexPages.Standardcontroller sc = new ApexPages.Standardcontroller(rateCards[0]);
		MakeActiveSchoolAttendance_RateCardCont cont = new MakeActiveSchoolAttendance_RateCardCont(sc);
		cont.makeCurrentRateCardActive();

		sc = new ApexPages.Standardcontroller(rateCards[1]);
	  	cont = new MakeActiveSchoolAttendance_RateCardCont(sc);
		cont.makeCurrentRateCardActive();

		rateCards = [Select id, Active__c from Rate_Card__c where id in :rateCards];
		System.assertEquals(rateCards[0].Active__c, true);
		System.assertEquals(rateCards[1].Active__c, true);
		System.assertEquals(rateCards[2].Active__c, false);
		System.assertEquals(rateCards[3].Active__c, false);
	}
}
@isTest
private class DateUtilitiesTest {
	
	@isTest static void test_Calculation() {
		Date endDate = Date.newInstance(2018, 7, 5);
		Date startDate = Date.newInstance(2018, 7, 3);
		Test.startTest();
			System.assertEquals(startDate, DateUtilities.calculateStartDate(endDate, 1), 'Dates not matching!');
		Test.stopTest();
	}
	
	@isTest static void test_Bulk() {
		Date endDate = Date.newInstance(2018, 7, 5);
		Date startDate = Date.newInstance(2018, 7, 3);
		Test.startTest();
			for(Integer i = 0; i < 200; i++){
				System.assertEquals(startDate, DateUtilities.calculateStartDate(endDate, 1), 'Dates not matching!');
			}
		Test.stopTest();
	}

	@isTest static void test_LongMonth() {
		String month = DateUtilities.getLongMonth(5);
		System.assertEquals('May', month, 'Incorrect month returned');
	}

	@isTest static void test_ShortMonth(){
		String month = DateUtilities.getShortMonth(4);
		System.assertEquals('Apr', month, 'Incorrect month returned');
	}

	@isTest static void test_BusinessDays() {
		Date endDate = Date.newInstance(2018, 7, 5);
		Date startDate = Date.newInstance(2018, 7, 3);
		Test.startTest();
			System.assertEquals(1, DateUtilities.calculateBusinessDays(startDate, endDate), 'Calculation not correct!');
		Test.stopTest();
	}

	@isTest static void test_NextBusinessDayHoliday() {
		Date startDate = Date.newInstance(2018, 12, 24);
		Test.startTest();
			System.assertEquals(Date.newInstance(2018, 12, 26), DateUtilities.getNextBusinessDay(startDate), 'Calculation not correct!');
		Test.stopTest();
	}

	@isTest static void test_NextBusinessDayWeekend() {
		Date startDate = Date.newInstance(2019, 03, 15);
		Test.startTest();
			System.assertEquals(Date.newInstance(2019, 03, 18), DateUtilities.getNextBusinessDay(startDate), 'Calculation not correct!');
		Test.stopTest();
	}

	@isTest static void test_AddBusinessDays() {
		Date startDate = Date.newInstance(2018, 12, 24);
		Test.startTest();
			System.assertEquals(Date.newInstance(2018, 12, 27), DateUtilities.addBusinessDays(startDate, 2), 'Calculation not correct!');
		Test.stopTest();
	}

	@isTest static void test_IsBusinessDay() {
		Date startDate = Date.newInstance(2019, 09, 02);
		Test.startTest();
			System.assertEquals(False, DateUtilities.isBusinessDay(startDate), 'Calculation not correct!');
		Test.stopTest();
	}

	@isTest static void test_IsNotBusinessDay() {
		Date startDate = Date.newInstance(2019, 09, 03);
		Test.startTest();
			System.assertEquals(True, DateUtilities.isBusinessDay(startDate), 'Calculation not correct!');
		Test.stopTest();
	}	

}
@istest
public class scheduledPropertyTaxTest {

    @isTest
    static void testScheduler() {
    Test.startTest();
    scheduledPropertyTax sch = new scheduledPropertyTax();
    sch.execute(null);
    Test.stopTest();

   }
}
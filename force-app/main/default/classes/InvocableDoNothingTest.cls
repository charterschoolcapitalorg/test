@isTest
private class InvocableDoNothingTest {
    @isTest
    private static void testDoNothing() {
        InvocableDoNothing.doNothing();
        // unfortunately there is nothing to assert since this method does nothing
    }
}
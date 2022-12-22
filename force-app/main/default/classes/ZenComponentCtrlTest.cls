@IsTest
private class ZenComponentCtrlTest {
    @TestSetup
    static void makeData(){
        Zen_Moment__c zenSettings = new Zen_Moment__c();
        zenSettings.Heading__c = 'Test heading';
        zenSettings.Image_URL__c = 'https://google.com';
        zenSettings.Image_Text__c = 'Test text';
        zenSettings.Color__c = 'rebeccapurple';
        insert zenSettings;
    }

    @isTest
    private static void testGetter(){
        Test.startTest();
        List<String> zenSettings = ZenComponentCtrl.getCustomSettings();
        System.assertEquals('Test heading', zenSettings[0], 'Check heading returned');
        System.assertEquals('https://google.com', zenSettings[1], 'Check url returned');
        System.assertEquals('Test text', zenSettings[2], 'Check text returned');
        System.assertEquals('rebeccapurple', zenSettings[3], 'Check color returned');
        Test.stopTest();
    }
}
public without sharing class ZenComponentCtrl {
    @AuraEnabled(cacheable=true)
    public static List<String> getCustomSettings(){
        List<String> customSettings = new List<String>();
        Zen_Moment__c zenSettings = Zen_Moment__c.getInstance();
        customSettings.add(zenSettings.Heading__c);
        customSettings.add(zenSettings.Image_URL__c);
        customSettings.add(zenSettings.Image_Text__c);
        customSettings.add(zenSettings.Color__c);
        return customSettings;
    }
}
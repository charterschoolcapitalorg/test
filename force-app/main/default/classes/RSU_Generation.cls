public with sharing class RSU_Generation { 
    private final static String urlFieldName = 'Conga_Conductor_Last_Month_RSU__c';
    private String partnerServerUrl;
    private ApexPages.StandardSetController controller;
    private List<Id> accountIds = new List<Id>();
    
    // public String RSU_Url {get; private set;}
    
    public RSU_Generation(ApexPages.StandardSetController controller) {
        this.controller = controller;
        for (sObject sObj : controller.getSelected()){
            accountIds.add(sObj.Id);
        }
        partnerServerUrl = 'https://'+ApexPages.currentPage().getHeaders().get('Host')+'/services/Soap/u/49.0/'+UserInfo.getOrganizationId();
    }
    
    public PageReference prepareRSUUrl() {
        PageReference conductorUrl = new PageReference('https://conductor.congamerge.com?');
        conductorUrl.getParameters().put('MOID', String.join(new List<Id>(accountIds),','));
        conductorUrl.getParameters().put('SessionId',  UserInfo.getSessionID());
        conductorUrl.getParameters().put('ServerUrl',  partnerServerUrl);
        conductorUrl.getParameters().put('UrlFieldName',  urlFieldName);
        System.debug('URL: ' + conductorUrl);
        return conductorUrl;
    }

}
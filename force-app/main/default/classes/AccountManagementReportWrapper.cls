public with sharing class AccountManagementReportWrapper {
    // @AuraEnabled
    // public Account acc{get;set;}
    @AuraEnabled
    public String accUrl{get;set;}
    @AuraEnabled
    public String accName{get;set;}
    @AuraEnabled
    public String repUrl{get;set;}
    @AuraEnabled
    public String accState{get;set;}
    @AuraEnabled
    public String accOwner{get;set;}
    @AuraEnabled
    public String nextWhiteboardOpp{get;set;}
    @AuraEnabled
    public Decimal faceValueDue{get;set;}
    @AuraEnabled
    public String boughtUntil{get;set;}
    @AuraEnabled
    public String lastEffectiveRate{get;set;}
    @AuraEnabled
    public String linkName{get;set;}
    @AuraEnabled
    public Integer recCount{get;set;}
    @AuraEnabled
    public String latestStrategy{get;set;}
    @AuraEnabled
    public String latestUpdate{get;set;}
}
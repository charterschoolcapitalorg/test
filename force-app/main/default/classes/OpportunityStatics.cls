public with sharing class OpportunityStatics {
    
    private static boolean clientPortalAutomation = true;
    
    public static boolean didClientPortalAutomation(){
        if(clientPortalAutomation){
             clientPortalAutomation=false;
             return true;
        }else{
                return clientPortalAutomation;
        }
    }
    
    
    
}
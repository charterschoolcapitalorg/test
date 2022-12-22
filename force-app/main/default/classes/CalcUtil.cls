/**
* @author : theakhilis
* @description : Utility class for application framework.
*/
public class CalcUtil{
    
    /**
    * This method returns Map where key is Id & value is list of sObjects.
    * 
    * @param: list of sobjects to assign to each record.
    * @param: api name of field present on sobject whose SFID will be used as Id for key
    *
    * @return map of id against list of sobjects.
    */
    public static Map<Id,List<SObject>> getIdRelatedMap(List<SObject> sObjectList, String keyApiName){
        Map<Id,List<SObject>> retVal = new Map<Id,List<SObject>>();
        List<SObject> valueList;
        
        for(SObject sObj : sObjectList){
            valueList = retVal.get((Id)sObj.get(keyApiName));
            
            if(valueList != null){
                valueList.add(sObj);
            }else{
                valueList = new List<SObject>();
                valueList.add(sObj);
            }
            
            retVal.put((Id)sObj.get(keyApiName),valueList);
        }
        
        return retVal;
    }//end getIdRelatedMap.
    
    /**
    * This method returns set of IDs to be used in SOQL to bulkify.
    * 
    * @param: list of sobjects for which set should be defined.
    * @param: which field value should be used as value for set.
    */
    public static set<Id> getIdSet(List<SObject> sObjectList,String fieldApiName){
        Set<Id> retVal = new Set<Id>();
        
        for(sObject sObj : sObjectList){
            retVal.add((Id)sObj.get(fieldApiName));
        }
        
        return retVal;
    }//end getIdSet.
    
    /*
    * This method returns custom settings.
    */
    public static Financial_Calc_Settings__c getCustomSettings(){
        Financial_Calc_Settings__c custSetting = Financial_Calc_Settings__c.getInstance();
        
        if(custSetting == null){
            custSetting = Financial_Calc_Settings__c.getOrgDefaults();
        }
        
        return custSetting;
    }
}
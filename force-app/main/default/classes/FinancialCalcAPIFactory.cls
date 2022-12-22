global class FinancialCalcAPIFactory{
    
    /**
    * This method returns instance of class dynamically.
    * Class which needs to be instantiated must implement FinancialCalculatorAPI interface.
    * 
    * Method checks if classType is null at first place. It can be null in 2 cases.
    *
    * 1. Class does not exist with given classname.
    * 2. Class present in some different managed package is called.
    *
    * if classType found null at first place, we retry to create classtype using namespacePrefix,
    * even then it is null then method throws exception for invalid class name.
    *
    */
    global static FinancialCalculatorAPI getApi(String className){
        FinancialCalculatorAPI calcApi;   
        String namespacePrefix;
        
        //get custom settings.
        Financial_Calc_Settings__c cSettings  = CalcUtil.getCustomSettings();
        
        if(!String.isBlank(cSettings.NameSpacePrefix__c)){
            namespacePrefix = cSettings.NameSpacePrefix__c;
        }
        
        try{
            
            //Create class Type.
            Type classType = Type.forname(className);
            
            //Check first if classType is null.
            if(classType == null){
                classType = Type.forname(namespacePrefix,className);
                
                //Check if classType is null after using namespacePrefix.
                if(classType == null){
                    //throw new GeneralException(System.Label.Class_Not_Found);
                    ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING,'Could not find "'+className+'" Calculation Class. Please contact your Salesforce Administrator.');
                    ApexPages.addMessage(msg);
                    return null;
                }
            }            
            
            //Create New Instance for class type.
            calcApi = (FinancialCalculatorAPI)classType.newInstance();
            return calcApi;
            
        }catch(TypeException typecastException){
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING,'Could not find "'+className+'" Calculation Class. Please contact your Salesforce Administrator.');
            ApexPages.addMessage(msg);
            return null;
            //throw new GeneralException(System.Label.Class_Type_Exception);
        }catch(Exception e){
            throw e;
        }
    }
}
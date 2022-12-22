/**
* @author : theakhilis.
*
* @description : Class holds current processing record, can be used by computational classes depending on class logic.
* 
*/
public class FinancialCalcModel{
    public static String               currentDebugLog{get;set;}
    public static School_Attendance__c currentProcessingSchAttendance{get;set;}
    public static Opp_School__c        currentProcessingOppSchool{get;set;}
    public static Payor__c   		   currentProcessingPayor{get;set;}
    public static Receivable_Type__c   currentProcessingReceivableType{get;set;}
    public static Calculation__c       currentProcessingCalculation{get;set;}
    public static Rate_Card__c         currentProcessingStateRateCard{get;set;}
    public static Rate_Card__c         currentProcessingCOERateCard{get;set;}
    public static Rate_Card__c         currentProcessingDistRateCard{get;set;}
    public static Rate_Card__c         currentProcessingAltDistRateCard{get;set;}                      //2014.08.19 J Caughie - used to get Unduplicated Count District
    public static Boolean              currentProcessHasAltDistRateCard{get;set;}                      //2014.08.19 J Caughie - used to get Unduplicated Count District
    public static Boolean              currentProcessHasStateRateCard{get;set;}
    public static Boolean              currentProcessHasCOERateCard{get;set;}
    public static Boolean              currentProcessHasDistRateCard{get;set;}
    public static Decimal              currentFLsumFTE{get;set;}

    public static Boolean                                 currentProcessHasRegionalAttRec{get;set;}                   //2014.11.17  J Caughie - added for Regional calculations
    public static Map<Id, List<Regional_Attendance__c>>   currentProcessingRegAttMap{get;set;}                        //2014.11.17  J Caughie - added for Regional calculations
    public static Map<Id, List<Rate_Card__c>>             currentProcessingRegRateCardMap{get;set;}                   //2014.11.17  J Caughie - added for Regional calculations
    public static Set<ID>                                 currentProcessingRegAttDistricts{get;set;}                  //2014.11.17  J Caughie - added for Regional calculations

    public static Void addLog(String logMsg){
        system.debug(logMsg);
        currentDebugLog = currentDebugLog + '\r\n' + logMsg;
    }
}
/**
* @author : theakhilis.
* @description : Test class for FinancialCalcAPIFactory.
*                This class only defines negative tests. 
*                Positive tests are covered in TestFinancialCalcController.
*/
@isTest
public class TestFinancialCalcAPIFactory{

    public static testMethod void testNoClassExist(){
        
        Test.startTest();
        
        try{
            //No class exist
            FinancialCalculatorAPI api = FinancialCalcAPIFactory.getApi('NonExistingClass');
            
        }catch(Exception e){
            //assert no class found exception is handled.
            System.assertEquals(System.Label.Class_Not_Found,e.getMessage());
        }
        Test.stopTest();
    }
    
    public static testMethod void testClassCastException(){
        Test.startTest();
        
        try{
            //class does not implement FinancialCalculatorAPI Interface.
            FinancialCalculatorAPI api = FinancialCalcAPIFactory.getApi('TestHelper');
             
        }catch(Exception e){
            //assert no class found exception is handled.
            System.assertEquals(System.Label.Class_Type_Exception,e.getMessage());
        }
        Test.stopTest();         
    }
}
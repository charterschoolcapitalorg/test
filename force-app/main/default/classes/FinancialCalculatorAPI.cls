/**
* @author : theakhilis.
* @description : Interface should be implemented by receivable computating apex classes.
*/
global Interface FinancialCalculatorAPI{
    
    /**
    * This method returns receivable amount for a particular school , payor & associated receivable type.
    *
    * @param: no params.
    *
    * @return : school receivable amount for further calculation in decimal.
    *
    */
    Decimal computeReceivable();
}
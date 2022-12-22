/**=====================================================================
 * Name: OpportunityCloseExt
 * Description: Close opportunity button with reasons
 * Created Date: [10/20/2017]
 * Created By: John Caughie
 *
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/
public class OpportunityCloseExt {

    private final Opportunity opp;

    public OpportunityCloseExt(ApexPages.StandardController stdcontroller) {
        this.opp = (Opportunity)stdcontroller.getRecord();
        opp.StageName = 'Closed Lost';
        opp.IsAllowStageUpdation__c = true;
    }
       
    public pageReference save(){
        try {
            update opp;
            PageReference oppPage = new ApexPages.StandardController(opp).view();
            oppPage.setRedirect(true);
            return oppPage;
        } catch(DmlException ex){
            ApexPages.addMessages(ex);
            return null;
        }
    }

}
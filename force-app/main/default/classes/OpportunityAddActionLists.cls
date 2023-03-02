/**=====================================================================
 * Name: OpportunityAddActionLists Class
 * Description: Controller Class for OpportunityAddActionLists Page
 * Created Date: [12/18/2014]
 * Created By: [John Caughie]
 *
 * Date Modified            Modified By                 Description of the update
 * [??/??/????]            [???? ???????]              [?????????????????????????????????]
  =====================================================================*/

public with sharing class OpportunityAddActionLists {
	
	private Opportunity opp { get; set;}
	private Id oppID { get; set;}

	//constructor
	public OpportunityAddActionLists(ApexPages.StandardController controller) {
		opp = (Opportunity) controller.getRecord();
		oppID = opp.Id;
		System.debug('Opp: ' + oppID);
	}

  public PageReference addActionLists(){

    Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
    // String opportunityQuery = new selectall('Opportunity').soql +
    //       ' Where ID = :oppID';

    // Opportunity oppRecord = Database.query(opportunityQuery);
    Opportunity oppRecord = [SELECT id, name, recordtypeid,
    AccountId
    FROM Opportunity WHERE ID = :oppID];
    oppMap.put(oppID, oppRecord);

    OpportunityHelper.addOppsManually(oppMap);

    //PageReference returns user to the original opportunity page.
    PageReference pageRef = new PageReference('/' + oppID);
    pageRef.setRedirect(true);
    return pageRef;    
  }
}
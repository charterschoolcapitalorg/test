trigger FCDetailAfterUpdate on FC_Details__c (after update) {

 Set<Id> formIds = new Set<Id>();
 Set<Id> summaryFormIds = new Set<Id>();
 for(FC_Details__c f : trigger.new) {
 	if (f.fc_form__c!=null) formIds.add(f.fc_form__c);	
 }
 
 Map<Id, FC_Form__c> forms = new Map<Id, FC_Form__c>([Select Id, Status__c,Summary_FC_Form__c,  
 	(Select Id, Status__c, TYpe__c from FC_Approvals__r)
 	 from FC_FOrm__c where id IN: formIds]);
 	 
 for (FC_FOrm__c fo : forms.values()) {
 	if (fo.Summary_FC_Form__c!=null) summaryFormIds.add(fo.Summary_FC_Form__c);
 }
 
 if (summaryFormIds.size()>0) {
 	Map<Id, FC_Form__c> summaryforms = new Map<Id, FC_Form__c>([Select Id, Status__c,Summary_FC_Form__c, Opportunity__r.IsWon, 
 	(Select Id, Status__c, TYpe__c from FC_Approvals__r)
 	 from FC_FOrm__c where id IN: summaryFormIds]);
 	 
	 for(FC_Details__c fa : trigger.new) {
	 		//FC Detail data cannot be edited if FC Summary Form is rejected
	 		FC_Form__c form = forms.get(fa.fc_form__c);
	 		if (form!=null) {
	 			FC_Form__c summform = summaryforms.get(form.Summary_FC_Form__c);
		 		
		 		System.debug('****got fc form: ' + form);
		 		System.debug('****got summary form: ' + summform);
		 		
		 		//2019.03.05 J Caughie - added filter for won opps and conditional error message
		 		if (summform!=null && (summform.status__c=='Rejected' || summform.Opportunity__r.IsWon) && !FeatureManagement.checkPermission('Bypass_Validation')) {
		 			SObject sobj = (SObject)fa;
					sobj.adderror('FC Forms are locked to everyone when an Opportunity is Closed (Won or Lost) and cannot be altered.');
		 			//throw new FCFOrmUTils.FCEXception('You cannot edit this record.  FC Summary Form is in status of Rejected');
		 		}
	 		}
	 }  
 }
 
 
}
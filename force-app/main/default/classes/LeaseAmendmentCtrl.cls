public with sharing class LeaseAmendmentCtrl {

    @auraEnabled  
    public static Lease__c getLease(String leaseId) {  
          
        List<Schema.FieldSetMember> fsm = SObjectType.Lease__c.FieldSets.Lease_Amendment.getFields();
        System.debug('leaseId: ' + leaseId);
        String query = 'SELECT ';
        for(Schema.FieldSetMember f : fsm){
            query += f.getFieldPath() + ', ';
        }
        query += 'Id, Name FROM Lease__c WHERE id = \'';
        query += leaseId;
        query += '\'';
        System.debug('query: ' + query.right(50));
        // Lease__c ls = [SELECT Id, Name, Lease_Owner__c, Lease_Status__c, Lease_Type__c, Remaining_Lease_Term_Years__c, 
        //     Escalator__c, Escalation_Date__c, Base_Year__c, Base_Year_Rent__c, Lease_Commencement_Date__c, 
        //     Lease_Expiration_Date__c, Initial_Insurance_Expiration_Date__c, Lease_Version__c, Lease_Version_Number__c,
        //     Rent_Concessions__c, Maintenance_Requirements__c, Comments__c, Option_to_Extend__c, Option_Extension_Detail__c,
        //     Purchase_Option__c, Purchase_Option_Detail__c, Rent_Payment_Amount_Current__c, Periods__c, Rent_Payment_Due__c 
        //     FROM Lease__c 
        //     WHERE Id =: leaseId];  
        return Database.query(query);
        // return ls;

    }

    @AuraEnabled
    public static void updateRecords(String leaseJSON, String leaseAmendmentJSON, String leaseId){
        System.debug('lease: ' + leaseJSON);
        System.debug('lease amendment: ' + leaseAmendmentJSON);
        System.debug('lease Id: ' + leaseId);

        //parse lease amendment record
        Lease_Amendment__c la = new Lease_Amendment__c();
		la = (Lease_Amendment__c)System.JSON.deserialize(leaseAmendmentJSON, Lease_Amendment__c.Class);
		la.Lease__c = leaseId;
        System.debug('la ' + la);

        //parse updated lease record
        Lease__c updatedLease = new Lease__c();
		updatedLease = (Lease__c)System.JSON.deserialize(leaseJSON, Lease__c.Class);
		System.debug('lease ' + updatedLease);

        //get original lease
        Lease__c originalLease = getLease(leaseId);

        //calculate lease changes
        String updates = '';
        List<Schema.FieldSetMember> fsm = SObjectType.Lease__c.FieldSets.Lease_Amendment.getFields();
        for(Schema.FieldSetMember f : fsm){
            String field = f.getFieldPath();
            Schema.DisplayType type = f.getType();
            System.debug('f: ' + f);
            System.debug('field: ' + field);
            System.debug('original value: ' + originalLease.get(field));
            System.debug('update value: ' + updatedLease.get(field));
            if(type == Schema.DisplayType.PICKLIST){
                System.debug('picklist');
                if((String)originalLease.get(field) != (String)updatedLease.get(field) && !String.isEmpty((String)originalLease.get(field)) && !String.isEmpty((String)updatedLease.get(field))){
                    updates += (field + ':' + '\n' + originalLease.get(field) + ' -> '+ updatedLease.get(field) + '\n\n');
                }
            } else {
                System.debug('not picklist');
                if(originalLease.get(field) != updatedLease.get(field)){
                    updates += (field + ':' + '\n' + originalLease.get(field) + ' -> '+ updatedLease.get(field) + '\n\n');
                }
            }

        }

        //update lease amendment record
        la.Amended_Lease_Values__c = updates;

        try {
            insert la;
            update updatedLease;
        } catch (Exception e) {
            throw new AuraHandledException('Error: '
                + e.getMessage());
        }

    }
}
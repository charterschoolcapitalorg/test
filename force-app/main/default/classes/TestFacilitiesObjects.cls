@isTest 
 private class TestFacilitiesObjects {
     static testMethod void createFacObjects() {
         TestDIligenceUtils.createCOnfig();
         
         State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
             
         Account a = new Account(name='test ch', recordtypeid = RecordTypes.IDCharterAccount, operating_state__c=s.Id);
         insert a;
         Account prop =new Account(name='test prop', recordtypeid = RecordTypes.IDPropAccount, operating_state__c=s.Id);
         insert prop;
         
         Opportunity opp = CSCTestUtil.createOpportunity(a.Id, 'Unit Test Opp', 'Stage 1 - Projected');
         insert opp;
         
         
         CreateFacilitiesObjectsCtrl.getOpportunity(opp.Id);
         CreateFacilitiesObjectsCtrl.searchProperties('test');
         //String o = (Opportunity)System.JSON.serialize(SObject(opp));
         //Account prop = CreateFacilitiesObjectsCtrl.createNewProperty(o);
         
         Set<Id> propIds = new Set<Id>();
         propIds.add(prop.Id);
         CreateFacilitiesObjectsCtrl.savePropertyToOpp(opp.Id, prop.Id);
         CreateFacilitiesObjectsCtrl.getLeaseComplianceTemplate('Financials');
         CreateFacilitiesObjectsCtrl.getProperty(prop.Id);
         CreateFacilitiesObjectsCtrl.getBuildings(prop.Id);
         CreateFacilitiesObjectsCtrl.getSuites(prop.Id);
         CreateFacilitiesObjectsCtrl.getLeases(prop.Id);
         CreateFacilitiesObjectsCtrl.getTenants(prop.Id);
         CreateFacilitiesObjectsCtrl.getLeaseSuites(prop.Id);
         CreateFacilitiesObjectsCtrl.getParcels(prop.Id);
         CreateFacilitiesObjectsCtrl.getPropertyTaxes(prop.Id);
         CreateFacilitiesObjectsCtrl.getLeaseCompliances(prop.Id);
         CreateFacilitiesObjectsCtrl.getLeaseSchools(prop.Id);
         CreateFacilitiesObjectsCtrl.getRelatedContacts(prop.Id);
         CreateFacilitiesObjectsCtrl.getAquisitionsChecklist();
         CreateFacilitiesObjectsCtrl.getAssetMgmtChecklist();
         CreateFacilitiesObjectsCtrl.getProperties(propIds);
         CreateFacilitiesObjectsCtrl.getTenants(propIds);
         CreateFacilitiesObjectsCtrl.getLeaseComplianceRecordType();
         CreateFacilitiesObjectsCtrl.getLeaseRecordType();
         
         opp.StageName = 'Closed Lost';
         update opp;
     }
 }
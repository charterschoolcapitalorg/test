/**=====================================================================
 * Charter School Capital
 * Name: AcceptClientPortalItemCtrl
 * Test Class: AcceptClientPortalItemCtrlTest
 * Description: 
 * Created Date: []
 * Created By: [] 
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 *  Aug 24, 2022				Slava Krel				     Update for Account or Opp Legal Assistant assignment
 =====================================================================*/
public without sharing class AcceptClientPortalItemCtrl {

    private static final Set<String> DATA_SOURCE_VALUES = getPicklistValues(Financial__c.Data_Source__c);
    
    @AuraEnabled
    public static String getUIThemeDescription() {
        String theme = UserInfo.getUiThemeDisplayed();
        return theme;
    }
    
    @AuraEnabled
    public static String getUITheme() {
        String theme = UserInfo.getUiTheme();
        return theme;
    }
    
    @AuraEnabled
    public static void saveNoActionItems(String iId){
        System.debug('saveNoActionItems: ' + iId);
        Intake_Item__c i = [Select Id,status__c, Status_Changed_from_UI__c from Intake_Item__c where Id=:iId];
        i.status__c = 'Accepted';
        i.Status_Changed_from_UI__c = true;
        update i;
        System.debug('updated intake item: ' + i);
    }
    
    @AuraEnabled
    public static void saveActionItem(String iId, String aId, String status, String fileIds, String copyClientComment, 
                                      String CSCComment, String effDate, String expDate, String naDate, String cpDate, String createFinance){
        
        System.debug('saveActionItem: ' + aId);
        System.debug('expDate: ' + expDate);
        System.debug('effDate: ' + effDate);
        System.debug('naDate: ' + naDate);
        System.debug('cpDate: ' + cpDate);
        System.debug('fileIds: ' + fileIds);
        System.debug('copyClientComment: ' + copyClientComment);
        System.debug('CSCComment: ' + CSCComment);
        System.debug('createFinance: ' + createFinance);

        Id cpODRecordTypeId = Schema.SObjectType.Intake_Item__c.getRecordTypeInfosByName().get('Ongoing Diligence').getRecordTypeId();
        Id chRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Charter Holder').getRecordTypeId();
        Id schRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();
                                          
        Intake_Item__c i = [SELECT Id, 
                                    Status_Changed_from_UI__c,
                                    Client_Comments__c,
                                    Submitted_Date__c, 
                                    Approved_By__c, 
                                    Approved_Date__c, 
                                    Opportunity__r.Legal_Assistant__c
                                    FROM Intake_Item__c 
                                    WHERE Id=:iId];
        i.status__c = 'Accepted';
        i.Status_Changed_from_UI__c = true;
        update i;
        System.debug('updated intake item: ' + i);
        
        i = [SELECT Id, 
                    Action_Item_Mapping__c, 
                    Financial_Record_Type__c, 
                    Is_Financial__c, 
                    Status_Changed_from_UI__c,
                    Client_Comments__c, 
                    Submitted_Date__c,
                    Approved_By__c, 
                    Approved_Date__c, 
                    Opportunity__r.Legal_Assistant__c,
                    RecordTypeId 
                    FROM Intake_Item__c where Id=:iId];
                
        CSC_Action_Item__c ai = [SELECT Id, 
                                        Action_Item_Mapping__c, 
                                        Account__c, 
                                        Library_Type__c, 
                                        Opportunity_Id__c,
                                        Comments__c, 
                                        CSC_Team_Comment__c, 
                                        Received_Date__c, 
                                        CSC_Action_List__c, 
                                        Account_Id__c, 
                                        Review_Date__c, 
                                        Status__c, 
                                        Assigned_To__c,
                                        Date_Effective__c,
                                        Name, 
                                        Account_Name__c, 
                                        RecordTypeId, 
                                        CP_Item_Due_Date__c,
                                        CSC_Action_List__r.Account__r.RecordTypeId,
                                        CSC_Action_List__r.Account__r.Legal_Assistant__c,
                                        CSC_Action_List__r.Account__r.Charter_Holder__c,
                                        CSC_Action_List__r.Account__r.Charter_Holder__r.Legal_Assistant__c
                                        FROM CSC_Action_Item__c 
                                        WHERE Id=:aId];
        
        //set comments
        String comment = '';
        String clientcomment = '';
            
        if (CSCComment != null && CSCComment != '' ) {
            comment=stripString(CSCCOmment)+' \n ';
            System.debug('comment from UI: ' + comment);
        }
                                          
        if (copyClientComment=='true' && i.Client_Comments__c!=null ){   
            clientcomment='Per Client ' + i.Submitted_Date__c.month() + '/' + i.Submitted_Date__c.day() + '/'+ i.Submitted_Date__c.year() + ' - ' 
                + (i.Client_Comments__c==null ? '' : stripSTring(i.Client_Comments__c)) + '\n';
        }
        System.debug('client comment: ' + clientcomment);
        
        comment = comment+ clientcomment;
                                          
        if (comment!='') { 
            comment = comment.abbreviate(5000);  
            ai.Comments__c = comment + (ai.Comments__c!=null ? ai.Comments__c : '');
        }
        
        //set other fields
        ai.Received_Date__c = i.Submitted_Date__c;
        ai.Status__c = status;
        ai.Assigned_To__c = i.Approved_By__c;
        ai.CSC_Team_Comment__c = CSCComment;
        if (effDate!='') ai.Date_Effective__c = Date.valueOf(effDate);
        if (expDate!='') ai.Expiration_Date__c = Date.valueOf(expDate);
        if (naDate!='') ai.Next_Action_Date__c = Date.valueOf(naDate);
        if (cpDate!='') ai.CP_Item_Due_Date__c = Date.valueOf(cpDate);
                                          
        if (status=='Completed') {
            if (ai.Opportunity_Id__c!=null){ 
                //PCL item - update Date Completed
                ai.Date_Completed__c = i.Approved_Date__c;
            } else {
                //ACL item - udpate Review Date
                ai.Review_Date__c = i.Approved_Date__c;
            }
                
        }   

        if (status=='Legal Assistant Review') {
            //check if CP item = OD
            if (ai.Opportunity_Id__c==null){ 
                if(i.RecordTypeId == cpODRecordTypeId) {
                    // if the account is school
                    if(ai.CSC_Action_List__r.Account__r.RecordTypeId == schRecordTypeId) {
                        //look for charter holder Legal Assisstant
                        if (ai.CSC_Action_List__r.Account__r.Charter_Holder__c != null) {
                            ai.Assigned_To__c = ai.CSC_Action_List__r.Account__r.Charter_Holder__r.Legal_Assistant__c;
                        }
                        
                    } else {
                        ai.Assigned_To__c = ai.CSC_Action_List__r.Account__r.Legal_Assistant__c;
                    }
                } else {
                    ai.Assigned_To__c = i.Opportunity__r.Legal_Assistant__c;
                }
            }
        }
                                              
        update ai;
                                          
        Financial__c f = saveFinancial(createFinance, i, ai);

        saveFiles(fileIds, ai, f);
    }

    private static void saveFilesRelatedToActionItem(List<ContentVersion> cvs, CSC_Action_Item__c ai) {
        if (ai.RecordTypeId==Schema.SObjectType.CSC_Action_Item__c.getRecordTypeInfosByName().get('General').getRecordTypeId()) {
            List<ContentWorkspace> libraries = [select id, Name from ContentWorkspace];
            Map<String,ContentWorkspace> libraryMap = new Map<String,ContentWorkspace>();
            for ( ContentWorkspace l : libraries) {
                libraryMap.put(l.Name, l);
            }

            List<ContentWorkspaceDoc> docLinks = new List<ContentWorkspaceDoc>();
            for (ContentVersion cv : cvs) {
                cv.Account__c = ai.Account_Id__c;
                cv.CSC_Action_List__c = ai.CSC_Action_List__c; 
                cv.CSC_Action_Item__c = ai.Id;
                system.debug('updating content version: ' + cv);

                if (libraryMap.get(ai.Library_Type__c)!=null) {
                    ContentWorkspaceDoc docLink = new ContentWorkspaceDoc();
                    docLink.ContentDocumentId = cv.ContentDocumentId;
                    docLink.ContentWorkspaceId = libraryMap.get(ai.Library_Type__c).Id;
                    docLinks.add(docLink);
                }
            }

            update cvs;
            Database.insert(docLinks, false);
        }
    }

    private static void saveFilesRelatedToLeaseCompliance(List<ContentVersion> cvs, Lease_Compliance__c lc) {
        for (ContentVersion cv : cvs) {
            cv.Account__c = lc.Lease__r.Account__c;
        }
        update cvs;
    }

    private static void saveFiles(String fileIds, SObject relatedTo, Financial__c f) {
        List<STring> files;
        if (fileIds!=null&&fileIds!='') {
            files = fileIds.split(',');
            List<ContentWorkspaceDoc> libraryDocs = new List<ContentWorkspaceDoc>();
            List<ContentDocumentLink> cdls = new List<ContentDocumentLink>();

            //NOTE: For each file, we need to do the DML operations individually so that if 1 update fails (i.e. the file was already linked to the ACtion Item), 
            //  then the others wont fail

            //update COntentVersion field Account__c, CSC_Action_List__c, CSC_Action_Item__c
            //for ACL items
            List<ContentVersion> cvs = [Select Id, ContentDocumentId from ContentVersion where ContentDocumentId IN:files];

            List<ContentDocumentLink> cdlForInsert = new List<ContentDocumentLink>();
            for (String s : files) {
                //create ContentDocumentLink  record for the Action Item and for the FInancial object created
                cdlForInsert.add(new ContentDocumentLink(
                    LinkedEntityId = relatedTo.id,
                    ContentDocumentId = Id.valueOf(s),
                    shareType = 'V',
                    Visibility='AllUsers'
                ));

                if (f != null && f.id!=null) {
                    cdlForInsert.add(new ContentDocumentLink(
                        LinkedEntityId = f.id,
                        ContentDocumentId = Id.valueOf(s),
                        shareType = 'V',
                        Visibility='AllUsers'
                    ));
                }
            }

            if (relatedTo.getSObjectType() == CSC_Action_Item__c.SObjectType) {
                saveFilesRelatedToActionItem(cvs, (CSC_Action_Item__c)relatedTo);
            } else if (relatedTo.getSObjectType() == Lease_Compliance__c.SObjectType) {
                saveFilesRelatedToLeaseCompliance(cvs, (Lease_Compliance__c)relatedTo);
            }

            Database.insert(cdlForInsert, false);
        }
    }

    @AuraEnabled
    public static void saveLeaseCompliance(String iId, String lcId, String fileIds, String copyClientComment, String CSCComment){

        System.debug('saveLeaseCompliance: ' + lcId);
        System.debug('copyClientComment: ' + copyClientComment);
        System.debug('CSCComment: ' + CSCComment);

        Intake_Item__c i = new Intake_Item__c(
            Id = iId,
            Status__c = 'Accepted',
            Status_Changed_from_UI__c = true
        );
        update i;
        System.debug('updated intake item: ' + i);

        i = [
            Select
                Id,
                Action_Item_Mapping__c,
                Is_Financial__c,
                Financial_Record_Type__c,
                Status_Changed_from_UI__c,
                Client_Comments__c,
                Submitted_Date__c,
                Approved_By__c,
                Approved_Date__c,
                Opportunity__r.Legal_Assistant__c 
            from Intake_Item__c where Id=:iId];

        Lease_Compliance__c lc = [
            Select
                Id,
                Lease__c,
                Lease__r.Account__r.Name,
                Action_Item_Mapping__c,
                Comments__c,
                Received_Date__c,
                Name,
                RecordTypeId
            from Lease_Compliance__c where Id=:lcId
        ];

        //set comments
        String comment = '';
        String clientcomment = '';

        if (CSCComment != null && CSCComment != '' ) {
            comment=stripString(CSCCOmment)+' \n ';
            System.debug('comment from UI: ' + comment);
        }

        if (copyClientComment=='true' && i.Client_Comments__c!=null ){   
            clientcomment='Per Client ' + i.Submitted_Date__c.month() + '/' + i.Submitted_Date__c.day() + '/'+ i.Submitted_Date__c.year() + ' - ' 
                + (i.Client_Comments__c==null ? '' : stripSTring(i.Client_Comments__c)) + '\n';
        }
        System.debug('client comment: ' + clientcomment);

        comment = comment+ clientcomment;

        if (comment!='') { 
            comment = comment.abbreviate(5000);  
            lc.Comments__c = comment + (lc.Comments__c!=null ? lc.Comments__c : '');
        }

        //set other fields
        lc.Received_Date__c = i.Submitted_Date__c;
        // Id statusId = [SELECT Id FROM RecordType WHERE Name =: status].Id;
        // lc.RecordTypeId = statusId;

        update lc;

        // Financial__c f = saveFinancial(createFinance, i, lc);

        System.debug('updated lc: ' + lc);

        saveFiles(fileIds, lc, null);
    }

    private static Set<String> getPicklistValues(SObjectField field) {
        Set<String> values = new Set<String>();
        for (Schema.PicklistEntry entry : field.getDescribe().getPicklistValues()) {
            if (entry.isActive()) {
                values.add(entry.getValue());
            }
        }
        return values;
    }

    private static void saveFinancialRelatedToActionItem(Financial__c f, CSC_Action_Item__c ai) {
        f.Action_Item__c = ai.Id;
        f.Account__c = ai.Account_Id__c;
        if (DATA_SOURCE_VALUES.contains(ai.Action_Item_Mapping__c)) {
            f.Data_Source__c = ai.Action_Item_Mapping__c;
        }
    }

    private static void saveFinancialRelatedToLeaseCompliance(Financial__c f, Lease_Compliance__c lc) {
        f.Lease__c = lc.Lease__c;
        f.Account__c = lc.Lease__r.Account__c;
        if (DATA_SOURCE_VALUES.contains(lc.Action_Item_Mapping__c)) {
            f.Data_Source__c = lc.Action_Item_Mapping__c;
        }
    }

    private static Financial__c saveFinancial(String createFinance, Intake_Item__c i, SObject relatedTo) {
        if (createFinance == 'true' && i.Is_Financial__c) {
            Financial__c f = new Financial__c();
            System.debug('i.Action_Item_Mapping__c: ' + i.Action_Item_Mapping__c);
            f.RecordTypeId = FinancialCtrl.getRecordTypeId(i.Financial_Record_Type__c);

            if (relatedTo.getSObjectType() == CSC_Action_Item__c.SObjectType) {
                saveFinancialRelatedToActionItem(f, (CSC_Action_Item__c)relatedTo);
            } else if (relatedTo.getSObjectType() == Lease_Compliance__c.SObjectType) {
                saveFinancialRelatedToLeaseCompliance(f, (Lease_Compliance__c)relatedTo);
            }

            if (f.recordTypeId!=null) {
                insert f;
                return f;
            }
        }
        return null;
    }

    public static String stripSTring(String s) {
            s = s.replaceAll('<[^>]+>',' ');
            s = s.replaceAll('&#39;', '\'');
            s = s.replaceAll('&amp;', '&');
            s = s.replaceAll('&lt;', '<');
            s = s.replaceAll('&gt;', '>');
            s = s.replaceAll('&quot;', '"');
            return s;
    }
    
    @AuraEnabled
    public static Intake_Item__c getIntakeItem(String iId){
        return [
            SELECT
                Id,
                Status__c,
                Opportunity__c,
                Update_PCL__c,
                Update_Lease_Compliance__c,
                Update_AL__c,
                Update_Property_Tax__c,
                Copy_Files_to_AL_PCL__c, 
                Is_Financial__c,
                Action_Item_Mapping__c,
                Account_Name__c,
                Account_Name__r.ParentId,
                CSC_Action_Item__r.CSC_Action_List__r.Account__r.recordtypeid,
                CSC_Action_Item__r.CSC_Action_List__r.Account__c
            FROM Intake_Item__c
            WHERE Id=:iId
        ];
    }

    @AuraEnabled
    public static List<Lease_Compliance__c> getLeaseComplianceItem(String iiId){
        Intake_Item__c ii = getIntakeItem(iiId);
        List<Lease_Compliance__c> leaseItems = new List<Lease_Compliance__c>();

        system.debug('*** ii.Account_Name__c = ' + ii.Account_Name__c);
        system.debug('*** ii.Account_Name__r.ParentId = ' + ii.Account_Name__r.ParentId);

        Id chRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Charter Holder').getRecordTypeId();
        Id schRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('School').getRecordTypeId();

        //If CP is connected to Action Item related to an Action List tied to a Charter Holder, 
        //grab a List of Schools under that Charter Holder where the School has an Active Lease School
        if (ii.Update_Lease_Compliance__c) {
            List<Lease_School__c> leaseSchools = new List<Lease_School__c>();

            if(ii.CSC_Action_Item__r.CSC_Action_List__r.Account__r.recordtypeid == chRecordTypeId) {
                List<Account> schoolsOnTheCharter = [
                                                    SELECT Id, Name 
                                                    FROM Account 
                                                    WHERE ParentId = :ii.CSC_Action_Item__r.CSC_Action_List__r.Account__c
                                                ];
                system.debug('*** schoolsOnTheCharter = ' + schoolsOnTheCharter);
                for(Account schoolOnTheCharter : schoolsOnTheCharter){
                    leaseSchools = [
                                    SELECT Id, Lease__c
                                    FROM Lease_School__c
                                    WHERE Account_School__c = :schoolOnTheCharter.id
                                    AND Lease__r.Lease_Status__c = 'Active'
                                ];
                }
                system.debug('*** leaseSchools = ' + leaseSchools);
            } else {
                leaseSchools = [
                                SELECT Id, Lease__c
                                FROM Lease_School__c
                                WHERE (Account_School__c = :ii.Account_Name__c
                                OR Account_School__c = :ii.Account_Name__r.ParentId)
                                AND Lease__r.Lease_Status__c = 'Active'
                            ];
            }

            system.debug('*** leaseSchools = ' + leaseSchools);

            Set<Id> leaseIds = new Set<Id>();
            for(Lease_School__c ls : leaseSchools){
                leaseIds.add(ls.Lease__c);
            }

            leaseItems.addAll([
                SELECT
                    Id,
                    Name,
                    Action_Item_Mapping__c,
                    Lease_Compliance_Name__c,
                    Property_Name__c,
                    Tenant_Name__c,
                    Lease__c,
                    Lease__r.Account__c,
                    Lease__r.Name,
                    Lease__r.Tenant__r.Tenant__c,
                    RecordTypeId,
                    RecordType.DeveloperName,
                    Compliance_Coverage_Window__c
                FROM Lease_Compliance__c
                WHERE (
                    Lease__c IN :leaseIds
                    OR (Lease__r.Tenant__r.Tenant__r.RecordTypeId = :RecordTypes.IdCharterAccount AND (Lease__r.Tenant__r.Tenant__c = :ii.Account_Name__r.ParentId OR Lease__r.Tenant__r.Tenant__c = :ii.Account_Name__c))
                    OR (Lease__r.Account__r.RecordTypeId = :RecordTypes.IdCharterAccount AND (Lease__r.Account__c = :ii.Account_Name__c OR Lease__r.Account__c = :ii.Account_Name__r.ParentId))
                )
                AND Received_Date__c = null
                AND Action_Item_Mapping__c = :ii.Action_Item_Mapping__c
                AND Lease__r.Lease_Status__c = 'Active'
            ]);
        }

        system.debug('*** leaseItems = ' + leaseItems);

        return leaseItems;
    }

    //add property tax
    @AuraEnabled
    public static List<Property_Tax__c> getPropertyTaxItem(String iiId){
        //need to return Property tax
        String currentYear = String.valueOf(System.Today().year());
        Intake_Item__c ii = getIntakeItem(iiId);
        List<Property_Tax__c> propTaxItems = new List<Property_Tax__c>();

        if (ii.Update_Property_Tax__c) {
            Lease_School__c leaseSchool = [
                                            SELECT Id, Lease__c
                                            FROM Lease_School__c
                                            WHERE Account_School__c = :ii.Account_Name__c 
                                            AND Lease_Status__c = 'Active'
                                            AND Off_Date__c = null
                                            LIMIT 1
                                        ];
            system.debug('@@@ leaseSchool = ' + leaseSchool);

            if(leaseSchool != null) {
                lease__c lease = [SELECT Id, Name, Property__c FROM Lease__c WHERE Id =: leaseSchool.Lease__c];
                    
                propTaxItems = [SELECT Id, 
                                    Name, 
                                    Tax_Year_Number__c, 
                                    Status__c, 
                                    Outstanding_Balance__c, 
                                    X1st_Tax_Due_Date__c, 
                                    Property_Exemption_Status__c, 
                                    X1st_Paid_Amount__c,
                                    Parcel__c,
                                    Parcel__r.Name,
                                    X1st_Amount_Due__c, 
                                    Property_Tax_Status__c 
                                    FROM Property_Tax__c 
                                    WHERE Property__c =: lease.Property__c 
                                    AND Property_Tax_Status__c = 'Active' 
                                    AND Outstanding_Balance__c != 0
                                    //AND Tax_Year_Match__c = true 
                                    //AND (Status__c = 'Due' OR Status__c = 'Past Due' OR Status__c = 'Partial Payment')
                                    ];
            }
        }
        return propTaxItems;
    }

    @AuraEnabled
    public static void savePropertyTax(String iId, String ptId, String fileIds, String copyClientComment, String CSCComment, Decimal paidAmount, Date paidDate){

        System.debug('PROPERTY TAX');
        System.debug('savePropertyTax: ' + ptId);
        System.debug('copyClientComment: ' + copyClientComment);
        System.debug('CSCComment: ' + CSCComment);
        System.debug('iId: ' + iId);
        System.debug('fileIds: ' + fileIds);
        System.debug('paidAmount: ' + paidAmount);
        System.debug('paidDate: ' + paidDate);

        List<Property_Tax__c> propTaxToUpdate = new List<Property_Tax__c>();
        Intake_Item__c ii = getIntakeItem(iId);

        Lease_School__c leaseSchool = [ SELECT Id, Lease__c
                                        FROM Lease_School__c
                                        WHERE Account_School__c = :ii.Account_Name__c LIMIT 1];

        Lease__c lease = [SELECT Id, Name, Property__c 
                            FROM Lease__c 
                            WHERE Id =: leaseSchool.Lease__c];
        
        Property_Tax__c propTaxItem = [SELECT 
                                        Id, 
                                        Name, 
                                        Tax_Year_Number__c, 
                                        Status__c, 
                                        Outstanding_Balance__c, 
                                        X1st_Tax_Due_Date__c, 
                                        Property_Exemption_Status__c, 
                                        X1st_Paid_Amount__c,
                                        Parcel__c,
                                        Parcel__r.Name,
                                        X1st_Amount_Due__c,
                                        X1st_Amount_Paid_Date__c,
                                        Notes__c
                                        FROM Property_Tax__c 
                                        // WHERE Property__c =: lease.Property__c 
                                        WHERE Id =:ptId];

        propTaxItem.X1st_Paid_Amount__c = paidAmount;
        propTaxItem.X1st_Amount_Paid_Date__c = paidDate;
        //move to finalized
        if(propTaxItem.X1st_Amount_Due__c <= paidAmount) {
            propTaxItem.Property_Tax_Status__c = 'Finalized';
        }

        propTaxToUpdate.add(propTaxItem);

        Intake_Item__c i = [SELECT
                                Id,
                                Action_Item_Mapping__c,
                                Is_Financial__c,
                                Financial_Record_Type__c,
                                Status_Changed_from_UI__c,
                                Client_Comments__c,
                                Submitted_Date__c,
                                Approved_By__c,
                                Approved_Date__c,
                                Opportunity__r.Legal_Assistant__c 
                            FROM Intake_Item__c 
                            WHERE Id=:iId];

        //set comments
        String comment = '';
        String clientcomment = '';

        if (CSCComment != null && CSCComment != '' ) {
            comment=stripString(CSCCOmment)+' \n ';
            System.debug('comment from UI: ' + comment);
        }

        if (copyClientComment=='true' && i.Client_Comments__c!=null ){   
            clientcomment='Per Client ' + i.Submitted_Date__c.month() + '/' + i.Submitted_Date__c.day() + '/'+ i.Submitted_Date__c.year() + ' - ' 
                + (i.Client_Comments__c==null ? '' : stripSTring(i.Client_Comments__c)) + '\n';
        }
        System.debug('client comment: ' + clientcomment);

        //push comments to property tax
        comment = comment + clientcomment;

        if (comment!='') { 
            comment = comment.abbreviate(5000);  
            propTaxItem.Notes__c = comment + (propTaxItem.Notes__c!=null ? propTaxItem.Notes__c : '');
        }

        if(!propTaxToUpdate.isEmpty()) {
            update propTaxToUpdate;
            for(Property_Tax__c propTaxFile : propTaxToUpdate) {
                saveFiles(fileIds, propTaxFile, null);
            }
        }
    }
    //add property tax

    @AuraEnabled
    public static List<CSC_Action_Item__c> getMappedItems(String iId){
        Intake_Item__c ii = [Select Id, Opportunity__c, Update_PCL__c, Update_AL__c, Copy_Files_to_AL_PCL__c, 
            Action_Item_Mapping__c,Account_Name__c from Intake_Item__c where Id=:iId];
        
        System.debug('ii: ' + ii);
        List<CSC_Action_Item__c> results = new List<CSC_Action_Item__c>();
        
        if (ii.Action_Item_Mapping__c!=null) {
            if (ii.Update_AL__c) {
                
                Set<Id> schoolIds = new Set<Id>();
                for (Account a : [Select Id from Account where ParentId=:ii.Account_Name__c]) {
                    schoolids.add(a.Id);    
                }
                
                System.debug('schoolids: ' + schoolids);
                System.debug('charter account: ' + ii.Account_Name__c);
                
                List<CSC_Action_Item__c> alCharterResults = [Select Id, Action_Item_Mapping__c, Opportunity_Name__c, Name, Account_Name__c, RecordTypeId, CSC_Action_List__r.Account__r.RecordTypeId from CSC_Action_Item__c where 
                    CSC_Action_List__r.Account__c=:ii.Account_Name__c and Opportunity_Name__c=null and Action_Item_Mapping__c=:ii.Action_Item_Mapping__c];
                results.addall(alCharterResults);
                System.debug('****alCharterResults: ' + alCharterResults);
                
                List<CSC_Action_Item__c> alSchoolResults = [Select Id, Action_Item_Mapping__c, Opportunity_Name__c, Name, Account_Name__c, RecordTypeId, CSC_Action_List__r.Account__r.RecordTypeId from CSC_Action_Item__c where 
                    CSC_Action_List__r.Account__c IN :schoolids and Opportunity_Name__c=null and Action_Item_Mapping__c=:ii.Action_Item_Mapping__c];
                results.addall(alSchoolResults);        
                System.debug('****alSchoolResults: ' + alSchoolResults);
            }
            
            if (ii.Update_PCL__c) {
                List<CSC_Action_Item__c> pclResults = [Select Id, Action_Item_Mapping__c, Opportunity_Name__c, Name, Account_Name__c, RecordTypeId, CSC_Action_List__r.Account__r.RecordTypeId from CSC_Action_Item__c where 
                    CSC_Action_List__r.Opportunity__c =:ii.Opportunity__c and Action_Item_Mapping__c=:ii.Action_Item_Mapping__c];
                results.addall(pclResults);
                System.debug('****pclResults: ' + pclResults);
            }
        }
        
        System.debug('****returning: ' + results);
        return results;
    }   
    
    public static Intake_Item__c queryIntakeItem(String iId) {
        return  [
            SELECT
                Id,
                Opportunity__c,
                Update_PCL__c,
                Update_AL__c,
                Update_Property_Tax__c,
                Copy_Files_to_AL_PCL__c, 
                Action_Item_Mapping__c,
                Account_Name__c,
                Account_Name__r.RecordTypeId,
                Account_Name__r.ParentId
            FROM Intake_Item__c
            WHERE Id=:iId
        ];
    }
    
    @AuraEnabled
    public static List<CSC_Action_Item__c> getCharterACLItems(String iId){
        Intake_Item__c ii = queryIntakeItem(iId);
        
        System.debug('ii: ' + ii);
        List<CSC_Action_Item__c> results = new List<CSC_Action_Item__c>();
        
        if (ii.Action_Item_Mapping__c!=null) {
            if (ii.Update_AL__c) {
                Id acctId = ii.Account_Name__c;

                if (ii.Opportunity__c == null && ii.Account_Name__r.RecordTypeId == RecordTypes.IDSchoolAccount) {
                    acctId = ii.Account_Name__r.ParentId;
                }
                
                System.debug('charter account: ' + ii.Account_Name__c);
                
                List<CSC_Action_Item__c> alCharterResults = [Select Id, Action_Item_Mapping__c, Opportunity_Name__c, Name, Account_Name__c, RecordTypeId, CSC_Action_List__r.Account__r.RecordTypeId from CSC_Action_Item__c where 
                    CSC_Action_List__r.Account__c= :acctId and Opportunity_Name__c=null and Action_Item_Mapping__c=:ii.Action_Item_Mapping__c];
                results.addall(alCharterResults);
                System.debug('****alCharterResults: ' + alCharterResults);
            }
            
        }
        
        System.debug('****returning: ' + results);
        return results;
    }   
    @AuraEnabled
    public static List<CSC_Action_Item__c> getSchoolACLItems(String iId){
        Intake_Item__c ii = queryIntakeItem(iId);
        
        Id oppId = ii.Opportunity__c;
        
        System.debug('ii: ' + ii);
        List<CSC_Action_Item__c> results = new List<CSC_Action_Item__c>();
        
        if (ii.Action_Item_Mapping__c!=null) {
            if (ii.Update_AL__c) {
                
                Set<Id> schoolIds = new Set<Id>();

                if (oppId == null) {
                    if (ii.Account_Name__r.RecordTypeId == RecordTypes.IDSchoolAccount) {
                        schoolIds.add(ii.Account_Name__c);
                    }
                    schoolIds.addAll(new Map<Id,Account>([
                        Select Id
                        from Account
                        where ParentId = :ii.Account_Name__c
                        and RecordTypeId = :RecordTypes.IDSChoolAccount
                    ]).keySet());
                }

                for (Opp_School__c o : [Select Id, School__c from Opp_School__c where Opportunity__c=:oppId]) {
                    if (o.School__c!=null) schoolids.add(o.School__c);  
                }
                /*for (Account a : [Select Id from Account where ParentId=:ii.Account_Name__c]) {
                    schoolids.add(a.Id);    
                }*/
                
                System.debug('schoolids: ' + schoolids);
                System.debug('charter account: ' + ii.Account_Name__c);
                
                List<CSC_Action_Item__c> alSchoolResults = [SELECT Id, 
                                                                Action_Item_Mapping__c, 
                                                                Opportunity_Name__c, 
                                                                Name, 
                                                                Account_Name__c, 
                                                                RecordTypeId, 
                                                                CSC_Action_List__r.Account__r.RecordTypeId 
                                                                FROM CSC_Action_Item__c 
                                                                WHERE CSC_Action_List__r.Account__c IN :schoolids 
                                                                AND Opportunity_Name__c=null 
                                                                AND Action_Item_Mapping__c=:ii.Action_Item_Mapping__c];
                results.addall(alSchoolResults);        
                System.debug('****alSchoolResults: ' + alSchoolResults);
            }
            
        }
        
        System.debug('****returning: ' + results);
        return results;
    }   
    @AuraEnabled
    public static List<CSC_Action_Item__c> getPCLItems(String iId){
        Intake_Item__c ii = queryIntakeItem(iId);
        
        System.debug('ii: ' + ii);
        List<CSC_Action_Item__c> results = new List<CSC_Action_Item__c>();
        
        if (ii.Action_Item_Mapping__c!=null) {
            if (ii.Update_PCL__c && ii.Opportunity__c != null) {
                List<CSC_Action_Item__c> pclResults = [Select Id, Action_Item_Mapping__c, Opportunity_Name__c, Name, Account_Name__c, RecordTypeId, CSC_Action_List__r.Account__r.RecordTypeId from CSC_Action_Item__c where 
                    CSC_Action_List__r.Opportunity__c =:ii.Opportunity__c and Action_Item_Mapping__c=:ii.Action_Item_Mapping__c];
                results.addall(pclResults);
                System.debug('****pclResults: ' + pclResults);
            }
        }
        
        System.debug('****returning: ' + results);
        return results;
    }   
    @AuraEnabled
    public static Id getCharterALAcctType(){
        return RecordTypes.IDCharterAccount;
    }
    @AuraEnabled
    public static Id getSchoolALAcctType(){
        return RecordTypes.IDSChoolAccount;     
    }
    @AuraEnabled
    public static Id getPCLType(){
        return Schema.SObjectType.CSC_Action_Item__c.getRecordTypeInfosByName().get('Sales Process').getRecordTypeId();
    }
    
    @AuraEnabled
    public static List<ContentDocument> getFiles(string theid) {
        return MyItemRowCtlr.getFIles(theid);
    }

    @AuraEnabled
    public static List<CSC_Action_Item__c> getActionItem(string aiId) {
        List<CSC_Action_Item__c> aiList = [SELECT id, 
                                                Name, 
                                                recordtypeid, 
                                                CSC_Action_List__r.Account__r.Charter_Holder__r.Legal_Assistant__c,
                                                CSC_Action_List__r.Account__r.Legal_Assistant__c
                                                FROM CSC_Action_Item__c 
                                                WHERE id = :aiId];
        return aiList;
    }
    
}
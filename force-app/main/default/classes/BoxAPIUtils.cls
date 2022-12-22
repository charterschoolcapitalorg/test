public class BoxAPIUtils {
    /*** each txn calling the API's needs to bein this class ***/
    /** at the end of the method need to update the refresh and access tokens, because we have to do all callouts priior to
       updating any fields in SF ***/
    /**they shoudl all be future callouts also ***/

    /* Folders API Calls */
    public static void createAcctFolders(Id acctId) {
        try {
            List<box__FRUP__c> frups = new List<box__FRUP__c>();
            String theState = '';
            
            STring grpName = BoxCredentials__c.getOrgDefaults().Box_CSC_Group_Name__c;
            
            if (grpName==null ) {
                throw new BoxUtils.BoxAuthException('See your SF Administrator.  Box CSC Group Name must be specified in Custom Setting BoxCredentials.');
            }
            
            Account busAccount = [Select Id, Incorporation_State__c, Incorporation_State__r.Name, operating_state__c, operating_state__r.Name,RecordTypeId, Name from Account where Id=:acctId];
            Account charterAcct;
            Account schoolAcct;
            
            if (busAccount.Incorporation_State__c==null&&busAccount.RecordTypeId==RecordTypes.IDBusAccount) {
                throw new BoxUtils.BoxAuthException('Business Account must have an Incorporation State');
            } else if (busAccount.RecordTypeId==RecordTypes.IDBusAccount) theState = busAccount.Incorporation_State__r.Name;
            
            if (busAccount.operating_state__c==null&&(busAccount.RecordTypeId==RecordTypes.IDCharterAccount||busAccount.RecordTypeId==RecordTypes.IDSChoolAccount)) {
                throw new BoxUtils.BoxAuthException('Business Account must have an Operating State');
            } else if (busAccount.RecordTypeId==RecordTypes.IDCharterAccount||busAccount.RecordTypeId==RecordTypes.IDSChoolAccount) theState = busAccount.operating_state__r.Name;
            
            
            List<Account> charterAccts = [Select Id, Incorporation_State__c, Incorporation_State__r.Name, operating_state__c, operating_state__r.Name,RecordTypeId,Name from Account where ParentId=:busAccount.Id];
            if (charterAccts.size()==0) {
              if (!test.isrunningtest()) {
                throw new BoxUtils.BoxAuthException('Account must have at least 1 Account as a Child Account');
              }
            }  
            
            String rootFolderPRefix = '';
            if (busAccount.RecordTypeId==RecordTypes.IDCharterAccount)  {
                rootFolderPRefix = 'Charter';
            }else if (busAccount.RecordTypeId==RecordTypes.IDSChoolAccount)  {
                rootFolderPRefix = 'School';
            }else if (busAccount.RecordTypeId==RecordTypes.IDBusAccount)  {
                rootFolderPRefix = '';
            }
            
            BoxFolderIds__c sett = BoxFolderIds__c.getOrgDefaults();
            String parentId = sett.Account_Root_Folder__c;
            if (parentId==null) {
                throw new BoxUtils.BoxAuthException('BoxFolderIds Custom Setting does not have a root Account Folder');
            }
            
            //create State Folder 
            String stateId = '';
            
            BoxFieldStructures.FolderFile state = getFolderFileByName(theState);
            System.debug('****state folder: ' + state);
            if (state==null||state.Id==null) {
                //create
                try {
                    state = createFolder(theState, parentId);
                    stateId = state.Id;
                } catch (EXception e) {
                    BoxFieldStructures.Error err = (BoxFieldStructures.Error)JSON.deserialize(e.getmessage(), 
                        BoxFieldStructures.Error.class);
                    System.debug('*****err');
                    BoxFieldStructures.ErrorInfo ei = err.context_info;
                    List<BoxFieldStructures.ErrorConflicts> m = err.context_info.conflicts; 
                    stateId = m[0].id;
                }
                createCollaborator(stateId,grpName);
                
            } else {stateId = state.Id;}//exists
            
            
            
            //create Root Account Folder 
            BoxFieldStructures.FolderFile bus = createFolder(rootFolderPRefix + ' ' + busAccount.name + ' ( ' + busAccount.Id + ' )', stateId);
            createCollaborator(bus.Id,grpName);
            
            //create BOX acess to the Account folder
            frups = createBoxFRUPs(busAccount.Id, bus.Id, '',frups);
            
            if (charterAccts.size()==0) {
                    BoxFieldStructures.FolderFile schoolupload = createFolder('Uploads', bus.Id);
            }
            //create Charter Folders
            for (Account charter : charterAccts) {
                String subFolderPRefix = '';
                if (charter.RecordTypeId==RecordTypes.IDCharterAccount)  {
                    subFolderPRefix = 'Charter';
                }else if (charter.RecordTypeId==RecordTypes.IDSChoolAccount)  {
                    subFolderPRefix = 'School';
                }
                BoxFieldStructures.FolderFile charterfolder = createFolder(subFolderPRefix + ' ' + charter.name + ' ( ' + charter.Id + ' )', bus.Id);
                //createCollaborator(charter.Id,grpName);
                
                //create School Folders
                List<Account> schoolAccts = [Select Id, Incorporation_State__c, Incorporation_State__r.Name, operating_state__c, operating_state__r.Name,RecordTypeId,Name from Account where ParentId=:charter.Id];
                if (schoolaccts.size()==0) {
                    BoxFieldStructures.FolderFile schoolupload = createFolder('Uploads', charterfolder.Id);
                }
                for (Account a : schoolAccts) {
                    String sub2FolderPRefix = '';
                    if (a.RecordTypeId==RecordTypes.IDCharterAccount)  {
                        sub2FolderPRefix = 'Charter';
                    }else if (a.RecordTypeId==RecordTypes.IDSChoolAccount)  {
                        sub2FolderPRefix = 'School';
                    }
                    BoxFieldStructures.FolderFile school = createFolder(sub2FolderPRefix + ' ' + a.name + ' ( ' + a.Id + ' )', charterfolder.Id);
                    //createCollaborator(school.Id,grpName);
                    BoxFieldStructures.FolderFile schoolupload = createFolder('Uploads', school.Id);
                    //createCollaborator(school.Id,grpName);
                }
            }
            
            if (frups.size()>0) { insert frups; }
            updateRefreshToken();
            
        } catch (Exception e) {
            updateRefreshToken();
            throw new BoxUtils.BoxAuthException(e.getmessage() + ' - ' + e.getstacktracestring());
        }    
        
    }
    
    public static void updateRefreshToken() {
            //update refresh and access tokens in SF if it changed
            System.debug('in updateRefreshTokens');
            BoxCredentials__c creds = BoxCredentials__c.getOrgDefaults();
            if (creds!=null&&creds.Id!=null) {
                if (BoxUtils.latestRefreshToken != creds.Refresh_Token__c && BoxUtils.latestRefreshToken!=null) {
                    System.debug('setting Refresh_Token__c to: ' +  BoxUtils.latestRefreshToken);
                    creds.Refresh_Token__c = BoxUtils.latestRefreshToken;
                }
                if (BoxUtils.latestToken != creds.Access_Token__c  && BoxUtils.latestToken!=null) {
                    System.debug('setting Access_Token__c to: ' +  BoxUtils.latestToken);
                    creds.Access_Token__c = BoxUtils.latestToken;
                }
                try {
                    //
                    update creds;
                } catch (EXception e) {System.debug('**** exception updating BoxCredentials__c ' + e.getstacktracestring() + ' - ' + e.getmessage()); }
            }
    }
    
    public static void createOppFoldersNotFuture(Id oppId) {
        createOppFoldersLogic(oppId);
    }
    
    @Future(callout = true)
    public static void createOppFolders(Id oppId) {
        try {
            createOppFoldersLogic(oppId);
        } catch (Exception e) {
            updateRefreshToken();
            DiligenceUtils.sendErrorEMail('Opportunity: ' + Url.getSalesforceBaseUrl().toExternalForm() + '/' + oppId + '\n' + e.getmessage() + ' - ' + e.getstacktracestring(),'Error Creating Opp Box Folders');
        }   
    }
    
    public static void createOppFoldersLogic(Id oppId) {
        Opportunity o = [SELECT Id, Name, RecordType.DeveloperName, Account.Name 
                            FROM Opportunity 
                            WHERE Id=:oppId];
        List<Box_Read_Only_Shares__c> existing = [Select Id, role__c, opportunity__c, box_url__c from Box_Read_Only_Shares__c where opportunity__c=:oppId];
        
        BoxFolderIds__c sett = BoxFolderIds__c.getOrgDefaults();
        if (BoxCredentials__c.getOrgDefaults() == null) {
            return ;
        }
        
        // String parentId = sett.Opportunity_Root_Folder__c;
        String parentId;
        String templateId;

        //select parent folder depending on opportunity type
        system.debug('@@@ o.RecordType.DeveloperName = ' + o.RecordType.DeveloperName);
        switch on o.RecordType.DeveloperName {
            when 'Facilities' {
                parentId = sett.Opp_Facilities__c;
                templateId = sett.Facilities_Template_Folder__c;
            }
            when 'Broker_Network' {
                parentId = sett.Opp_BrokerNetwork__c;
                templateId = sett.Facilities_Template_Folder__c;
            }
            when 'FOF' {
                parentId = sett.Opp_FOF__c;
            }
            when 'X5DF' {
                parentId = sett.Opp_5DF__c;
                templateId = sett.WC_Template_Folder__c;
            }
            when 'Loan' {
                parentId = sett.Opp_Loans__c;
                templateId = sett.WC_Template_Folder__c;
            }
            when 'Initial_Funding' {
                parentId = sett.Opp_Initial_Funding__c;
            }
            when 'Enrollment_Marketing' {
                parentId = sett.Opp_EM__c;
                templateId = sett.EM_Folder_Template__c;
            }
            when else {
                parentId = sett.Opp_Other__c;
            }
        }

        system.debug('@@@ parentId = ' + parentId);
        system.debug('@@@ templateId = ' + templateId);

        if (parentId==null) {
            throw new BoxUtils.BoxAuthException('BoxFolderIds Custom Setting does not have a root Opportunity Folder');
        }
        
        List<Box_Read_Only_Shares__c> shares = new List<Box_Read_Only_Shares__c>();
        List<box__FRUP__c> frups = new List<box__FRUP__c>();
        
        List<DiligenceRoleMap__mdt> drm = [Select Role__c, Box_Folder_Name__c, Profile_name__c from DiligenceRoleMap__mdt];  
        Map<String,STring> roleMap = new Map<String,STring>(); 
        for (DiligenceRoleMap__mdt d : drm) {
            if (d.Box_Folder_Name__c!=null) {
                //we will create a folder for this Role under the Opportunity
                System.debug('rolemap entry: ' + d.Role__c + ' - ' + d.Box_Folder_Name__c);
                roleMap.put(d.Role__c, d.Box_Folder_Name__c);
            }
        }

        //facilities goes a different path!
        BoxFieldStructures.FolderFile ff = new BoxFieldStructures.FolderFile();
        if (templateId != null){
            ff = copyTemplateFolders(templateId, parentId, o.name + ' ( ' + o.Id + ' )');
        } else {
            ff = createFolder(o.name + ' ( ' + o.Id + ' )', parentId);
        }

        //BoxFieldStructures.FolderFile ff = createFolder(o.name + ' ( ' + o.Id + ' )', parentId);

        if (ff!=null&&ff.Id!=null&&ff.id!='') {
            frups = createBoxFRUPs(oppId, ff.Id, '',frups);
        }

        //create collaborator for this root Oppf folder for the CSC Box Group
        // STring grpName = BoxCredentials__c.getOrgDefaults().Box_CSC_Group_Name__c;
        // if (grpName!=null ) {
        //     BoxFieldStructures.FolderFile collabres = createCollaborator(ff.Id,grpName);
        //     System.debug('***collab result: ' + collabres);
        // }
        
        if (ff!=null&&ff.Id!=null&&ff.id!='') {
            
            if(templateId == null){
                BoxFieldStructures.FolderFile ce = createFolder('Client Sharing', ff.Id);
                ce = createFolder('CSC Internal', ff.Id);
            } else if(o.RecordTypeId == RecordTypes.IDEMOpp){
                String sharingFolder = 'Contractor Sharing(' + removeSpecialCharacters(o.Account.Name) + ' & Charter School Capital)';
                BoxFieldStructures.FolderFile ce = createFolder(sharingFolder, ff.Id);
            } else {
                String sharingFolder = 'External Sharing(' + removeSpecialCharacters(o.Account.Name) + ' & Charter School Capital)';
                BoxFieldStructures.FolderFile ce = createFolder(sharingFolder, ff.Id);
            }
            
            
            //create next subfolder
            
            //always create Client External and sub folders 
            // BoxFieldStructures.FolderFile ce = createFolder('Client Sharing', ff.Id);
            // BoxFieldStructures.FolderFile share = createReadOnlyFolderSharedLink(ce.Id);
            
            //frups = createBoxFRUPs(oppId, ff.Id, '',frups);
                
            // if (share!=null&&share.shared_link!=null) {
            //     System.debug('creating oppfolder for role: ' + DiligenceVars.SchoolTenantRole);
            //     shares = createOppFolderShare(oppId, share.shared_link.url,DiligenceVars.SchoolTenantRole, shares, existing);   
            // }
            
            // if (ce!=null&&ce.Id!=null&&ce.id!='') {
            //     BoxFieldStructures.FolderFile ce2 = createFolder('Uploads', ce.Id);
            //     String externalUploadFolder = ce2.Id;
            //     o.Client_External_Box_Folder_Id__c = externalUploadFolder;
            //     ce2 = createFolder('Production', ce.Id);
            //     ce2 = createFolder('Misc', ce.Id);
            // }
            
            //always create CSC Internal and sub folders
            // ce = createFolder('CSC Internal', ff.Id);
            // share = createReadOnlyFolderSharedLink(ce.Id);
            // if (share!=null&&share.shared_link!=null) {
            //     System.debug('creating oppfolder for role: ' + DiligenceVars.CSCRole);
            //     shares = createOppFolderShare(oppId, share.shared_link.url, DiligenceVars.CSCRole, shares, existing);
            // }
            
            // if (ce!=null&&ce.Id!=null&&ce.id!='') {
            //     BoxFieldStructures.FolderFile ce2 = createFolder('Resolutions', ce.Id);
            //     ce2 = createFolder('Misc', ce.Id);
            // }
            
            //now create rest of the Role sub folders
            // for (STring s : roleMap.keyset()) {
            //     ce = createFolder(roleMap.get(s), ff.Id);
            //     share = createReadOnlyFolderSharedLink(ce.Id);
            //     if (share!=null&&share.shared_link!=null) {
            //         System.debug('creating oppfolder for role: ' + s);
            //         shares = createOppFolderShare(oppId, share.shared_link.url, s, shares, existing);   
            //     }
            // }
            
            // if (shares.size()>0) { upsert shares; }
            if (frups.size()>0) { insert frups; }
        } else {
            throw new BoxUtils.BoxAuthException('Could not create root Opportunity folder');
        }
        
        
        //update Opp
        o.Box_Folder_ID__c = ff.id;
        update o;
        
        updateRefreshToken();
                
    }

    // public static void createFacilitiesFolders(String originalTemplate, String destinationFolder){
    public static BoxFieldStructures.FolderFile copyTemplateFolders(String template, String parentId, String folderName){
        System.debug('I want to copy ' + template + ' to ' + parentId + ' and call it ' + folderName);

        folderName = removeSpecialCharacters(folderName);
        // foldername += 'test';

        String payload = '{"name":"' + folderName + '", "parent":{"id":"' + parentId + '"}}';
        if (!test.isrunningtest()) {
          String resp = getBoxResponse('POST', '/folders/' + template + '/copy/', payload);
          BoxFieldStructures.FolderFile ff = (BoxFieldStructures.FolderFile)JSON.deserialize(resp, BoxFieldStructures.FolderFile.class);
          if (ff==null||ff.Id==null) {
            //BoxFieldStructures.Error e = (BoxFieldStructures.Error)JSON.deserialize(resp, BoxFieldStructures.Error.class);
            throw new BoxUtils.BoxAuthException(resp);
          }
          return ff;
        } else {
          string resp = '{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )","created_at":"2018-05-02T07:22:04-07:00","modified_at":"2018-05-02T07:22:04-07:00","description":"","size":0,"path_collection":{"total_count":3,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},{"type":"folder","id":"48976042670","sequence_id":"0","etag":"0","name":"CSC Salesforce Folder"},{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"}]},"created_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"modified_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"trashed_at":null,"purged_at":null,"content_created_at":"2018-05-02T07:22:04-07:00","content_modified_at":"2018-05-02T07:22:04-07:00","owned_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"},"item_status":"active","item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}';
          BoxFieldStructures.FolderFile ff = (BoxFieldStructures.FolderFile)JSON.deserialize(resp, BoxFieldStructures.FolderFile.class);
          return ff;
        }
       
    }


    /* Find Folder or File with query.   @Returns an enclosing object of FolderFiles (FolderFileRoot) */   
    public static BoxFieldStructures.FolderFiles findFolderFile(String query){
        String search = '/search?content_types=name&type=folder&query=' + query;
        System.debug('Query in API: ' + search);
        BoxFieldStructures.FolderFiles bff;
        if (!test.isrunningtest()) {
          bff = (BoxFieldStructures.FolderFiles)JSON.deserialize(getBoxResponse('GET', search, null), BoxFieldStructures.FolderFiles.class);
          return bff;
        } else {
          String resp = '{"type":"folder","id":"49112924125","sequence_id":"0","etag":"0","name":"Client External","created_at":"2018-05-02T07:22:09-07:00","modified_at":"2018-05-02T07:22:09-07:00","description":"","size":0,"path_collection":{"total_count":4,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},{"type":"folder","id":"48976042670","sequence_id":"0","etag":"0","name":"CSC Salesforce Folder"},{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"},{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )"}]},"created_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"modified_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"trashed_at":null,"purged_at":null,"content_created_at":"2018-05-02T07:22:09-07:00","content_modified_at":"2018-05-02T07:22:09-07:00","owned_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )"},"item_status":"active","item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}';
          bff = (BoxFieldStructures.FolderFiles)JSON.deserialize(resp, BoxFieldStructures.FolderFiles.class);
          return bff;
        }
        
    }
    
   
    /* Performs a query by Folder Name, then attemps to exactly match folder names in the returned enclosing object.  @Returns FolderFileRoot */
    public static BoxFieldStructures.FolderFile getFolderFileByName(String name){
        String query = name;
        BoxFieldStructures.FolderFiles flist = findFolderFile(query);
        List<BoxFieldStructures.FolderFile> folderFiles = new List<BoxFieldStructures.FolderFile>();
        if(flist.entries != null && flist.entries.size() > 0){
            folderFiles = flist.entries;
            for(BoxFieldStructures.FolderFile f : folderFiles){
                if(f != null && f.name != null && f.name == name){
                    return f;
                }
            }
        } 

        return null;   
    }
    
    /* Upload a Document */
    @future(callout=true)
    public static void uploadDocument(String itemId, String folderId, String docName, STring documentId){
       try {
            System.debug('**** getting content for document: ' +documentId);
            
            transient COntentVersion cv = [Select Pushed_To_Box_Error__c,Pushed_To_Box__c, Id, VersionData from COntentVersion where id=:documentId LIMIT 1];
            transient Blob blobfileContent = cv.VersionData;
            transient String fileContent = EncodingUtil.base64Encode(blobfileContent);
                
            //docName = docname.replace('.','');
            docName = docname.replace('..','');
            docName = docname.replace('/','');
            docName = docname.replace('\\','');
            
            //, "password" : "null"
            System.debug('****doc name: ' + docName);
            String payload = '{"name":"' + docName + '", "parent":{"id":"' + folderId + '"}}';
            if (!test.isrunningtest()) {
               
              try {
                  String resp = getBoxResponse('POST', '/files/content?parent_id='+folderId, payload, fileContent, docName, blobfileContent);
                  System.debug('*** response: ' + resp);
                  try {
                      BoxFieldStructures.FolderFiles ff = (BoxFieldStructures.FolderFiles)JSON.deserialize(resp, BoxFieldStructures.FolderFiles.class);
                      if (ff.entries==null||ff.entries[0].id==null) {
                        DiligenceUtils.sendErrorEMail('Cannot upload document: ' + docName + ' for item id ' + itemId + ' to Box: ' + ff.code + ' - ' + ff.status, 'Error uploading document to Box');
                        throw new BoxUtils.BoxAuthException('Document ' + itemId +' not uploaded - ' + ff.code + ' - ' + ff.status);
                      }
                  } catch (EXception e) {
                    //send error email
                    DiligenceUtils.sendErrorEMail('Cannot upload document: ' + docName + ' for item id ' + itemId + ' to Box: response: ' + resp, 'Error uploading document to Box');
                    throw new BoxUtils.BoxAuthException('Document ' + itemId +' not uploaded - ' + ' response: ' + resp + ' - ' + e.getmessage() + ' - ' + e.getstacktracestring() );
                  }
              } catch (EXception e) {
                //send error email
                DiligenceUtils.sendErrorEMail('Cannot upload document: ' + docName + ' for item id ' + itemId + ' to Box: ' + e.getmessage() + ' - ' + e.getstacktracestring(), 'Error uploading document to Box');
                throw new BoxUtils.BoxAuthException('Document ' + itemId +' not uploaded - ' + ' - ' + e.getmessage() + ' - ' + e.getstacktracestring() );
              }
              
                
              
            } else {
              //String resp = '{"type":"folder","id":"49112924125","sequence_id":"0","etag":"0","name":"Client External","created_at":"2018-05-02T07:22:09-07:00","modified_at":"2018-05-02T07:22:09-07:00","description":"","size":0,"path_collection":{"total_count":4,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},{"type":"folder","id":"48976042670","sequence_id":"0","etag":"0","name":"CSC Salesforce Folder"},{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"},{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )"}]},"created_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"modified_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"trashed_at":null,"purged_at":null,"content_created_at":"2018-05-02T07:22:09-07:00","content_modified_at":"2018-05-02T07:22:09-07:00","owned_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )"},"item_status":"active","item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}';
              //return (BoxFieldStructures.FolderFile)JSON.deserialize(resp, BoxFieldStructures.FolderFile.class);
            }
        
            updateRefreshToken();
            
            //COntentVersion cv = [Select Pushed_To_Box_Error__c,Pushed_To_Box__c from ContentVersion where ContentDocumentId=:documentId];
            cv.Pushed_To_Box__c = true;
            cv.Pushed_To_Box_Error__c = 'Success';
            update cv;
                
        } catch (Exception e) {
            updateRefreshToken();
            System.debug('****exception: ' + e.getmessage() + ' - ' + e.getstacktracestring());
            try {
                COntentVersion cv = [Select Pushed_To_Box_Error__c,Pushed_To_Box__c from ContentVersion where Id=:documentId];
                cv.Pushed_To_Box__c = false;
                if (e.getmessage().contains('Item with the same name already exists"')) {
                    cv.Pushed_To_Box_Error__c = 'File with the same name already exists in Box Folder';
                } else if  (e.getmessage().contains('String length exceeds maximum') || e.getmessage().contains('Apex Heap') ) {
                    cv.Pushed_To_Box_Error__c = 'File is too large, please upload it manually.';
                } else {
                    cv.Pushed_To_Box_Error__c = e.getmessage() + ' - ' + e.getstacktracestring();
                }
                update cv;
            } catch (EXception e2) {
                throw new BoxUtils.BoxAuthException(e2.getmessage() + ' - ' + e2.getstacktracestring());    
            }
            
        }  
    }
     
    /* Create a Shared Link */
    public static BoxFieldStructures.FolderFile createReadOnlyFolderSharedLink(String id){
        //, "password" : "null"
        return null;
        
        String payload = '{"shared_link": {"access": "open"}}'; //JC changed from open
        if (!test.isrunningtest()) {
          return (BoxFieldStructures.FolderFile)JSON.deserialize(getBoxResponse('PUT', '/folders/'+id+'?fields=shared_link', payload), BoxFieldStructures.FolderFile.class);
        } else {
          String resp = '{"type":"folder","id":"49112924125","sequence_id":"0","etag":"0","name":"Client External","created_at":"2018-05-02T07:22:09-07:00","modified_at":"2018-05-02T07:22:09-07:00","description":"","size":0,"path_collection":{"total_count":4,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},{"type":"folder","id":"48976042670","sequence_id":"0","etag":"0","name":"CSC Salesforce Folder"},{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"},{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )"}]},"created_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"modified_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"trashed_at":null,"purged_at":null,"content_created_at":"2018-05-02T07:22:09-07:00","content_modified_at":"2018-05-02T07:22:09-07:00","owned_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )"},"item_status":"active","item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}';
          return (BoxFieldStructures.FolderFile)JSON.deserialize(resp, BoxFieldStructures.FolderFile.class);
        }
    }
    /* Get Group */
    public static String getGroupId(string grpName){
        String grpId;
        if (!test.isrunningtest()) {
          //grpName = EncodingUtil.urlEncode(grpName, 'UTF-8');
          BoxFieldStructures.BoxGroups bg = (BoxFieldStructures.BoxGroups)JSON.deserialize(getBoxResponse('GET', '/groups', null), BoxFieldStructures.BoxGroups.class);
          
          if (bg!=null && bg.entries!=null&& bg.entries.size()>0) {
            for (BoxFieldStructures.BoxGroup b : bg.entries) {
              System.debug('*** group: ' + b);
              if (b.name.equalsignorecase(grpName)) {
                System.debug('***Found group: ' + grpName);
                grpId = b.Id;  
              }
            }
          }
        } else {
          grpId = '123';
        }
        return grpId;
    }
    /* Create a Collaborator */
    public static BoxFieldStructures.FolderFile createCollaborator(String id, STring grpName){
        //get group id
        
        STring grpId = getGroupId(grpName);
        string payload = '{"item": { "id": "'+id+'", "type": "folder"}, "accessible_by": { "id": "' + grpId + '", "type": "group" }, "role": "editor"}';	//2018.05.25 J Caughie co-owner to editor
        
        if (!test.isrunningtest()) {
          return (BoxFieldStructures.FolderFile)JSON.deserialize(getBoxResponse('POST', '/collaborations?notify=false', payload), BoxFieldStructures.FolderFile.class);
        } else {
          string resp = '{"total_count":3,"entries":[{"type":"group","id":"1006755325","name":"Client Services","group_type":"managed_group"},{"type":"group","id":"1005566856","name":"CSC Employees","group_type":"managed_group"},{"type":"group","id":"1006718842","name":"WC - Underwriting","group_type":"managed_group"}],"limit":100,"offset":0}';
          return (BoxFieldStructures.FolderFile)JSON.deserialize(resp, BoxFieldStructures.FolderFile.class);
        }
    }
    
    /* Create a folder.  @Returns the new FolderFile object */
    public static BoxFieldStructures.FolderFile createFolder(String name, String parentId){
        name = removeSpecialCharacters(name);
      
        String payload = '{"name":"' + name + '", "parent": {"id": "' + parentId + '"}}';
        if (!test.isrunningtest()) {
          String resp =getBoxResponse('POST', '/folders', payload);
          BoxFieldStructures.FolderFile ff = (BoxFieldStructures.FolderFile)JSON.deserialize(resp, BoxFieldStructures.FolderFile.class);
          if (ff==null||ff.Id==null) {
            //BoxFieldStructures.Error e = (BoxFieldStructures.Error)JSON.deserialize(resp, BoxFieldStructures.Error.class);
            throw new BoxUtils.BoxAuthException(resp);
          }
          return ff;
        } else {
          string resp = '{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )","created_at":"2018-05-02T07:22:04-07:00","modified_at":"2018-05-02T07:22:04-07:00","description":"","size":0,"path_collection":{"total_count":3,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},{"type":"folder","id":"48976042670","sequence_id":"0","etag":"0","name":"CSC Salesforce Folder"},{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"}]},"created_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"modified_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"trashed_at":null,"purged_at":null,"content_created_at":"2018-05-02T07:22:04-07:00","content_modified_at":"2018-05-02T07:22:04-07:00","owned_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"},"item_status":"active","item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}';
          BoxFieldStructures.FolderFile ff = (BoxFieldStructures.FolderFile)JSON.deserialize(resp, BoxFieldStructures.FolderFile.class);
          return ff;
        }
       
    }
    /******************/

    /* Get Folder Items Limit with paging / Offets */
    public static BoxFieldStructures.FolderFiles getFolderFilesList(String folderId, String lmit, String offset){
        String search = '/folders/' + folderId + '/items?limit=' + lmit + '&offset=' + offset;
        if (!test.isrunningtest()) {
          return (BoxFieldStructures.FolderFiles)JSON.deserialize(getBoxResponse('GET', search, null), BoxFieldStructures.FolderFiles.class);
        } else {
          string resp = '{"type":"folder","id":"49112522134","sequence_id":"0","etag":"0","name":"FA - Ohio Coalition for Quality Education ( 0061k000003GgNnAAK )","created_at":"2018-05-02T07:22:04-07:00","modified_at":"2018-05-02T07:22:04-07:00","description":"","size":0,"path_collection":{"total_count":3,"entries":[{"type":"folder","id":"0","sequence_id":null,"etag":null,"name":"All Files"},{"type":"folder","id":"48976042670","sequence_id":"0","etag":"0","name":"CSC Salesforce Folder"},{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"}]},"created_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"modified_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"trashed_at":null,"purged_at":null,"content_created_at":"2018-05-02T07:22:04-07:00","content_modified_at":"2018-05-02T07:22:04-07:00","owned_by":{"type":"user","id":"3526338824","name":"Box Admin","login":"boxadmin@charterschoolcapital.com"},"shared_link":null,"folder_upload_email":null,"parent":{"type":"folder","id":"48977958353","sequence_id":"0","etag":"0","name":"Opportunities"},"item_status":"active","item_collection":{"total_count":0,"entries":[],"offset":0,"limit":100,"order":[{"by":"type","direction":"ASC"},{"by":"name","direction":"ASC"}]}}';
          BoxFieldStructures.FolderFile f = (BoxFieldStructures.FolderFile)JSON.deserialize(resp, BoxFieldStructures.FolderFile.class);
          List<BoxFieldStructures.FolderFile> fff = new List<BoxFieldStructures.FolderFile>();
          fff.add(f);
          BoxFieldStructures.FolderFiles ff = new BoxFieldStructures.FolderFiles();
          ff.entries = fff;
          ff.total_count = 1; 
          return ff;
        }
    }

    public static String getBoxResponse(String method, String request, String payload, STring fileContent, String fileName, Blob theBodyBlob) {
        String token;
      if (BoxUtils.latesttoken==null) {
        token = BoxCredentials__c.getOrgDefaults().Access_Token__c;
      } else {
        token = BoxUtils.latesttoken;
      }
      
        
        System.debug('MEthod: ' + method);
        Http h = new Http();
        HttpRequest req = new HttpRequest();
        if (request.contains('/files/content') || request.contains('/files/upload_sessions')) {
            if (fileContent!=''&&fileContent!=null) {
                req = buildFileRequest(req,  method,  request,  payload,  fileContent,  fileName, token, theBodyBlob);
                System.debug('Request URL: == ' + AUthorizeBoxController.API_ROOT_FOR_UPLOAD + request + ',    Payload === ' + payload + ',    token === ' + token);
                
            }
            // *********************** //
        } else {
            System.debug('Request URL: == ' + AUthorizeBoxController.API_ROOT + request + ',    Payload === ' + payload + ',    token === ' + token);
            req.setEndpoint(AUthorizeBoxController.API_ROOT + request); 
            if (payload != null) {
              req.setBody(payload);
            }
        }
        
        req.setHeader('Authorization', 'Bearer ' + token);
        req.setMethod(method);
                
        
        if (!test.isrunningtest()) {
          HttpResponse response = h.send(req); 
          System.debug('**** HttpResponse: ' + response);
          if (response.getStatusCode()==401) {
            System.debug('**** unauth:' + response);
            //refresh the token
            BoxUtils.OAUthResult boxTokens = BoxUtils.RefreshBoxTokens(false);
            if (boxTokens==null) {
              //throw exception
              throw new BoxUtils.BoxAuthException('Refresh Box Token failed');
            }
            h = new Http();
            req = new HttpRequest();
            
            
            if (request.contains('/files/content') || request.contains('/files/upload_sessions')) {
                if (fileContent!=''&&fileContent!=null) {
                    req = buildFileRequest(req,  method,  request,  payload,  fileContent,  fileName, token, theBodyBlob);

                }
                // *********************** //
            } else {
                System.debug('Request URL: == ' + AUthorizeBoxController.API_ROOT + request + ',    Payload === ' + payload + ',    token === ' + token);
                req.setEndpoint(AUthorizeBoxController.API_ROOT + request); 
                if (payload != null) {
                  req.setBody(payload);
                }
            }
            
            req.setHeader('Authorization', 'Bearer ' + boxTokens.access_token);
            req.setMethod(method);
            
            response = h.send(req);
            System.debug('**** response from retry:' + response);
            
            if (response.getStatusCode()>299) {
              throw new BoxUtils.BoxAuthException('Exception calling Box URL: ' + AUthorizeBoxController.API_ROOT + request + ':  - ' + response);
            }
          }
               
          String jsonString = response.getBody();
          System.debug('BODY ========================= ' + jsonString);
          jsonString = jsonString.replace('"limit":', '"limit_x":');
          jsonString = jsonString.replace('"group":', '"group_x":');
          return jsonString;
        } else {
          String jsonString = '';//'{id=123}';
          return jsonString;
        
      }
    }
    public static HttpRequest buildFileRequest(HttpRequest req, String method, String request, String payload, 
        STring fileContent, String fileName, String token, Blob theBodyBlob) {
            System.debug('Request URL: == ' + AUthorizeBoxController.API_ROOT_FOR_UPLOAD + request + ',    Payload === ' + payload + ',    token === ' + token);
            req.setEndpoint(AUthorizeBoxController.API_ROOT_FOR_UPLOAD + request );
            
            // ****************** //
                
                String boundary = '----------------------------741e90d31eff';
                String header = '--'+boundary+'\nContent-Disposition: form-data; name="file"; filename="'+fileName+'";\nContent-Type: multipart/form-data;'+'\nnon-svg='+True;
                String footer = '--'+boundary+'--';             
                transient String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
                HttpResponse res;
                String strFileId;
              
                while(headerEncoded.endsWith('='))
                {
                    header+=' ';
                    headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
                }
                System.debug('****before bodyEncoded');
                System.debug('***Limits.getHeapSize(): ' + Limits.getHeapSize());
                System.debug('***Limits.getLimitHeapSize(): ' + Limits.getLimitHeapSize());
                
                transient String bodyEncoded = fileContent;//
                System.debug('****after bodyEncoded');
                System.debug('***Limits.getHeapSize(): ' + Limits.getHeapSize());
                System.debug('***Limits.getLimitHeapSize(): ' + Limits.getLimitHeapSize());
                
                transient Blob bodyBlob = null;
                
                String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
                if(last4Bytes.endsWith('==')) 
                {
                    System.debug('****ends with ==');
                      last4Bytes = last4Bytes.substring(0,2) + '0K';
                } else if(last4Bytes.endsWith('=')) 
                {   System.debug('****ends with =');
                    last4Bytes = last4Bytes.substring(0,3) + 'N';
                    footer = '\n' + footer;       
                } else  {
                    footer = '\r\n' + footer; 
                }
                
                System.debug('****before new bodyEncoded');
                System.debug('***Limits.getHeapSize(): ' + Limits.getHeapSize());
                System.debug('***Limits.getLimitHeapSize(): ' + Limits.getLimitHeapSize());
                bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
                transient String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
                System.debug('****before bodyBlob');
                System.debug('***Limits.getHeapSize(): ' + Limits.getHeapSize());
                System.debug('***Limits.getLimitHeapSize(): ' + Limits.getLimitHeapSize());
                bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
                System.debug('****after bodyBlob');
                req.setHeader('Content-Type','multipart/form-data;non_svg='+True+';boundary='+boundary);
                req.setBodyAsBlob(bodyBlob);
                
                
                //req.setBodyAsBlob(theBodyBlob);
                req.setTimeout(120000);
                req.setHeader('Content-Length',String.valueof(req.getBodyAsBlob().size()));
              
                system.debug('*****size****'+req.getBodyAsBlob().size());
         return req;
        
    }
    public static String getBoxResponse(String method, String request, String payload) {
          return getBoxResponse(method, request, payload, '', '', null);
    }
        
    public class CloudBoxApiException extends Exception{}   
    
    private static List<Box_Read_Only_Shares__c> createOppFolderShare(Id oppId, String folderId, String role, List<Box_Read_Only_Shares__c> records, List<Box_Read_Only_Shares__c> existing) {
        Box_Read_Only_Shares__c newentry;
        if (existing!=null&&existing.size()>0) {
            for (Box_Read_Only_Shares__c b : existing) {
                if (b.opportunity__c==oppId&&b.role__c==role) {
                    newentry = b;
                    break;
                }
            }
        }
        if (newentry==null) { newentry = new Box_Read_Only_Shares__c();newentry.opportunity__c=oppId; }
        
        newentry.role__c = role;
        newentry.box_url__c = folderId;//'https://charterschoolcapitalinc.app.box.com/folder/'+folderId;
        records.add(newentry);
        return records;
    }
    
    private static List<box__FRUP__c> createBoxFRUPs( string recId, String folderId, String collaboration, List<box__FRUP__c> records) {
    
        
        //create generic Box Frup
        box__FRUP__c b;
        b = new box__FRUP__c();
        b.box__Folder_ID__c = folderId;
        b.box__Object_Name__c = 'Opportunity';
        b.box__Permission__c = 'Read/Write';
        b.box__Record_ID__c = recId;
        records.add(b);
            
       //create box FRUPS for all Box Users     
       for (User u : DiligenceVars.boxUsers ) { 
            b = new box__FRUP__c(); 
            b.box__Folder_ID__c = folderId;
            b.box__Object_Name__c = 'Opportunity';
            b.box__Permission__c = 'Read/Write';
            b.box__Record_ID__c = recId;
            b.box__Salesforce_User__c = u.Id;
            b.box__Box_user__c = u.Box_User_Id__c;
            
            records.add(b);
       }
        
       return records;
    }

    private static String removeSpecialCharacters(String name){
        name = name.replace('/', '');
        name = name.replace('\\', '');
        name = name.replace('..', '');
        name = name.replace('.', '');
        return name;
    }

    
}
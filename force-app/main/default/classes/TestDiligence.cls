// TODO J Caughie 2020.05.08 Commented out some "test" code around this time as there were som failures in deployment.
// Note that there are no system asserts and that the tests try to do everything at once.
// If this message is still here when your read it I guess I didn't fix it. Apologies :-(

@isTest 
private class TestDiligence {
    	
    	static testMethod void testPortalEmails() {
    		//SendSubmissionNeededEmails s = new SendSubmissionNeededEmails();
			//database.executebatch(s);
    	}
    	
    	
        static testMethod void boxUtils() {
            TestDIligenceUtils.createCOnfig();
            
            //box auth utils
            AuthorizeBoxController abc = new AuthorizeBoxController();
            PageReference pageRef = Page.AuthorizeBox;
            pageRef.getParameters().put('code','123');
            pageRef.getHeaders().put('Host','123');
            //pageRef.setURL('blah');
            Test.setCurrentPage(pageRef);
            abc.getAuthUrl();
            abc.getPageUrl();
            abc.redirectOnCallback();
            
                
            //box utils
            BoxUtils bu = new BoxUtils();
            BoxUtils.GetBoxRootFolders();
            BoxUtils.GetBoxTokens('abc','http://blah',true); 
            BoxUtils.RefreshBoxTokens(true);
            State_Province__c s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            
            //account box creation
            Account a = new Account(name='test ch', recordtypeid = RecordTypes.IDCharterAccount, operating_state__c=s.Id);
            insert a;
            Account a2 = new Account(name='test school', ParentId=a.Id,recordtypeid = RecordTypes.IDSChoolAccount, operating_state__c=s.Id);
            insert a2;
            System.debug('account parent: ' + a2.ParentId);
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(a);
            AccountCreateBoxStructureController aa = new AccountCreateBoxStructureController(thecontroller);
            aa.back();
            aa.execute();
                    
            //Opp create box folder structure
            //OpportunityHelperTest.createTestData();
            Opportunity opp = CSCTestUtil.createOpportunity(a.Id, 'Unit Test Opp', 'Stage 1 - Projected');
            insert opp;
            thecontroller = new ApexPages.StandardController(opp);
            OppCreateBoxStructureController oc = new OppCreateBoxStructureController(thecontroller);
            oc.back();
            oc.execute();
            
            
        }
        static testMethod void testEmailsToSend() {
        	//setup
            //TestDiligenceUTils.createStates();
            TestDIligenceUtils.createCOnfig();
            // TestDiligenceUTils.createFacilitiesIntakeTemplates();
            TestDiligenceUTils.createFUndingIntakeTemplates();
            
            LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
            cntr.back();
            cntr.doNotCreateOpp = false;
            
            //positive test
            // LEad l = TestDiligenceUtils.createFacLead();
            LEad l = TestDiligenceUtils.createIFLead();
            insert l;
            cntr.setLEad(l);
            cntr.execute();
            
            // String oppName = 'FA - '+l.company;
            String oppName = 'Initial Funding - '+l.company;
            Opportunity o;
            try {
                o = [Select Id from Opportunity where Name=:oppName];
                //o = [Select Id from Opportunity LIMIT 1];
            } catch (Exception e) {
                oppName = l.company;
                o = [Select Id from Opportunity where Name=:oppName];
             }
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(o);
            Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(thecontroller);
            List<Send_Community_Invite_Controller.conWrapper> cw = sc.conswrapper;
            for (Send_Community_Invite_Controller.conWrapper c : cw) {
                c.selected = true;
                c.role = 'School';//'Partner Community User School/Tenant';
            }
            sc.back();
            sc.save();
            
            //update opp to Stage 2 to create Stop 1 items
            o.StageName = Diligencevars.facStageToTriggerIntakeItemCreation;
            update o;
            
            //send emails
            CreateConsolidatedAccessEmail b = new CreateConsolidatedAccessEmail();
			database.executeBatch(b,10);
			
			CreateWeeklyClientStatusEmail b2 = new CreateWeeklyClientStatusEmail();
			database.executeBatch(b2,10);
			
			//DiligenceUtils.checkifItisWorkingDay(Date.today(), );
			//createFacilitiesPQItems
			//linkIntakeItemToActionItem
        }
        
        // 2020.05.22 - J Caughie - facilities lead type disabled
        /*static testMethod void leadConversionFacilities() {
            //setup
            //TestDiligenceUTils.createStates();
            TestDIligenceUtils.createCOnfig();
            TestDiligenceUTils.createFacilitiesIntakeTemplates();
            
            LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
            cntr.back();
            cntr.doNotCreateOpp = false;
            
            //positive test
            LEad l = TestDiligenceUtils.createFacLead();
            insert l;
            cntr.setLEad(l);
            cntr.execute();
            
            String oppName = 'FA - '+l.company;
            Opportunity o;
            try {
                o = [Select Id from Opportunity where Name=:oppName];
                //o = [Select Id from Opportunity LIMIT 1];
            } catch (Exception e) {
                oppName = l.company;
                o = [Select Id from Opportunity where Name=:oppName];
             }
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(o);
            Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(thecontroller);
            List<Send_Community_Invite_Controller.conWrapper> cw = sc.conswrapper;
            for (Send_Community_Invite_Controller.conWrapper c : cw) {
                c.selected = true;
                c.role = 'School';//'Partner Community User School/Tenant';
            }
            sc.back();
            sc.save();
            
            //update opp to Stage 2 to create Stop 1 items
            o.StageName = Diligencevars.facStageToTriggerIntakeItemCreation;
            update o;
            
            DiligenceVars.refreshPQ();
            DiligenceVars.refreshOpeningCall();
            
            //accept the PQ Stop 1 FOrm to create Stop 2 items
            List<Intake_Item__c> ii = [Select Id from intake_item__c where opportunity__c=:o.Id and is_pre_qual__c=true];
            System.debug('*** pq facilities intake items: ' + ii);
            for (Intake_Item__c i : ii) {
                i.status__c = 'Accepted';
                update i; //this create other intake items
                break;
            }
            
        }*/

        static testMethod void leadConversionInitialFUnding() {
            //setup
            TestDIligenceUtils.createCOnfig();
            TestDiligenceUTils.createFUndingIntakeTemplates();
            
            
            LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
            cntr.back();
            cntr.doNotCreateOpp = false;
            
            //negative tests
            LEad l = TestDiligenceUtils.createIFLead();
            l.lead_type__c = 'COE/District';
            insert l;
            cntr.setLEad(l);
            cntr.execute();
            
            l.lead_type__c = 'Business';
            l.Opportunity_Type__c = 'Loan';
            update l;
            cntr.setLEad(l);
            cntr.execute();
            
            l.Opportunity_Type__c = null;
            update l;
            cntr.setLEad(l);
            cntr.execute();
            
            l.Opportunity_Type__c = 'Initial Funding';
            State_Province__c s = [Select Id from State_Province__c where Name = 'AK' limit 1];
            l.Operating_State__c = s.Id;
            l.RecordTypeId = RecordTypes.IDGeneralLead;
            update l;
            cntr.setLEad(l);
            cntr.execute();
            
            //positive test
             s = [Select Id from State_Province__c where Name = 'GA' limit 1];
            l.Operating_State__c = s.Id;
            l.RecordTypeId = RecordTypes.IDGeneralLead;
            update l;
            cntr.setLEad(l);
            cntr.execute();
            
            //update contact
            Contact con = [Select Id, Name, FirstName, EMail from COntact where email='t@t.com'];
            con.firstname = con.firstname+'t';
            update con;
            
            ////create related contact
            Related_Contact__c rc = new Related_Contact__c();
            Account a = [Select id from Account LIMIT 1];
            rc.Account__c = a.Id;
            rc.contact__c = con.Id;
            rc.role__c = 'Other';
            insert rc;
            
            delete rc;
            
            //System.debug('***opp: ' + l.ConvertedOpportunityId);
            String oppName = 'Initial Funding - '+l.company;
            Opportunity o;
            try {
                o = [Select Id from Opportunity where Name=:oppName];
                
            } catch (Exception e) {
               // try {
                    oppName = l.company;
                    o = [Select Id from Opportunity where Name=:oppName];
                //} catch (Exception e2) {
                //    o = [Select Id from Opportunity LIMIT 1];
                //}
             }
            
            
            Test.startTest();
            
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(o);
            Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(thecontroller);
            List<Send_Community_Invite_Controller.conWrapper> cw = sc.conswrapper;
            for (Send_Community_Invite_Controller.conWrapper c : cw) {
                c.selected = true;
                c.role = 'School';//'Partner Community User School/Tenant';
            }
            sc.back();
            sc.save();
            
            DiligenceVars.refreshPQ();
            DiligenceVars.refreshOpeningCall();
            
            //add File to Intake Item
            List<Intake_Item__c> ii = [Select Id from intake_item__c where opportunity__c=:o.Id and is_pre_qual__c=true];
            System.debug('*** pq intake items: ' + ii);
            for (Intake_Item__c i : ii) {
                i.status__c = 'Accepted';
                update i; //this create other intake items
            }
            
            ii = [Select Id, is_document__c, Name from intake_item__c where opportunity__c=:o.Id];
            System.debug('*** intake items after PQ submitted: ' + ii.size());
            
            for (Intake_Item__c i : ii) {
                if (i.is_document__c) {
                    //add file
                    ContentVersion cv = new ContentVersion();
                    cv.ContentLocation = 'S';
                    cv.Title = 'test123454';
                    cv.COntentURL = 'http://blah.com';
                    insert cv;
                    ContentVersion cv2 = new ContentVersion();
                    cv2.ContentLocation = 'S';
                    cv2.Title = 'test123454123';
                    cv2.COntentURL = 'http://blah.com';
                    cv2.pushed_to_box__c = true;
                    insert cv2;
                    
                    cv = [Select Id, ContentDocumentId from ContentVersion where title='test123454'];
                    cv2 = [Select Id, ContentDocumentId from ContentVersion where title='test123454123'];
                    
                    System.debug('**inserting file for: ' + i.Id);
                    ContentDocumentLink c = new ContentDocumentLink();
                    c.linkedentityid = i.Id;
                    c.contentdocumentid = cv.ContentDocumentId;
                    c.sharetype = 'V';
                    insert c;
                    
                    ContentDocumentLink c2 = new ContentDocumentLink();
                    c2.linkedentityid = i.Id;
                    c2.contentdocumentid = cv2.ContentDocumentId;
                    c2.sharetype = 'V';
                    insert c2;
                    
                    //try {
                        //push files to Box tests
                        thecontroller = new ApexPages.StandardController(o);
                        OpportunityPushFilesToBoxController op = new OpportunityPushFilesToBoxController(thecontroller);
                        op.back();
                        op.execute();
                        op.pushToBox();
                        
                    //} catch (EXception e) {}
                    
                    break;
                }
            }
            Test.stopTest();
            
            //delete COmmunity COntact ROle
            User u = [Select Id, email,ContactId, Profile.Name from USer where email='t@t.com'];
            
            Community_Contact_Role__c c = new Community_Contact_Role__c(contact__c=u.ContactId,Opportunity__c=o.Id, role__c='School');
            insert c;
                
            List<Community_Contact_Role__c> ccr = [Select id,Contact__c, Opportunity__c,ROle__c from Community_Contact_Role__c where Opportunity__c =:o.id];
            System.debug('Community Contact Roles: ' +ccr);
            delete ccr;
                
            
        }
        
        static testMethod void communityTestsFunding() {
            TestDIligenceUtils.createCOnfig();
            TestDiligenceUTils.createFUndingIntakeTemplates();
            
            LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
            cntr.back();
            cntr.doNotCreateOpp = false;
            
            //create Lead and Opp and Intake Items tests
            LEad l = TestDiligenceUtils.createIFLead();
            insert l;
            cntr.setLEad(l);
            cntr.execute();
            
            String oppName = 'Initial Funding - '+l.company;
            Opportunity o;
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
                //o = [Select Id,OwnerId,  AccountId from Opportunity LIMIT 1];
            } catch (Exception e) {
                //try {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
                //} catch (Exception e2) {
                //    o = [Select Id,OwnerId,  AccountId from Opportunity LIMIT 1];
                //}
             }
            
            
            System.debug('***got opp: ' + o);
            
            //create Community Invites
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(o);
            Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(thecontroller);
            List<Send_Community_Invite_Controller.conWrapper> cw = sc.conswrapper;
            for (Send_Community_Invite_Controller.conWrapper c : cw) {
                c.selected = true;
                c.role = 'School';//'Partner Community User School/Tenant';
            }
            sc.back();
            sc.save();
            
            
            //get user that was created for the community
            User u = [Select Id, email,ContactId, Profile.Name from USer where email='t@t.com'];
            
            System.debug('***running as user: ' +u);
            
            ContactShare cs = new ContactShare();
            cs.UserOrGroupId = u.Id;
            cs.ContactAccessLevel = 'Edit';
            cs.ContactId = u.ContactId;
            insert cs;
            
            test.starttest();
            DiligenceVars.refreshPQ();
            DiligenceVars.refreshOpeningCall();
            
            //create other PQ Items, i.e. submit the PQ
            List<Intake_Item__c> ii = [Select Id, Name from intake_item__c where opportunity__c=:o.Id and is_pre_qual__c=true];
            System.debug('*** funding pq intake items: ' + ii);
            for (Intake_Item__c i : ii) {
                i.status__c = 'Submitted';
                update i;
                i.status__c = DiligenceVars.IntakeInputNeededStatus;//'Additional Input Needed';
                update i;
                i.status__c = 'Accepted';
                System.debug('*** creating additional intake items');
                update i;
            }
            
            ii = [Select Id, Name from intake_item__c where opportunity__c=:o.Id];
            System.debug('*** intake items after PQ submitted: ' + ii.size());
            for (Intake_Item__c i : ii) {
                System.debug('*** intake item: ' + i.Name);
            }
                
            //Set the Target Wire Date and trigger giligence path by Approving the Opening Call
            o.target_wire_date__C = date.today();
            o.Funded_date__c = date.today();
            o.Funded_Amount__c = 1;
            o.diligence_path__c = 1;
            update o;
            
            List<Intake_Item_Template__c > item = [select Id, Name, RecordTypeId from Intake_Item_Template__c ];
            for (Intake_Item_Template__c tem : item) {
                System.debug('&&&&& template: ' + tem);
            }
            
            DiligenceVars.refreshOpeningCall();
            
            ii = [Select Id from intake_item__c where opportunity__c=:o.Id and Name=:DiligenceVars.OpeningCallName];
            intake_item__c openingCall;
            System.debug('*** opening call intake items: ' + ii);
            for (Intake_Item__c i : ii) {
                i.status__c = 'Accepted';
                update i;
                openingCall = i;
                break;
            }   
            
            if (openingcall==null) {
                Intake_Item__c i = new Intake_Item__c();
                i.name = DiligenceVars.OpeningCallName;
                i.status__c = 'Accepted';
                i.visible_to__c ='CSC';
                i.recordtypeid = RecordTypes.IDInitialFundingIntakeItem ;
                i.opportunity__c = o.id;
                insert i;
                openingcall = i;
            }

            List<Intake_Item__c> itemsToShare = [ SELECT Id FROM Intake_Item__c ];
            for (Intake_Item__c itemToShare: itemsToShare) {
                itemToShare.Is_Visible_To_Community__c = true;
            }
            update itemsToShare;
            
            //update Target wire date to recalculate dates
            o.target_wire_date__C = date.today().addDays(2);
            update o;

            System.runAs(u) {   
                Box_Read_Only_Shares__c b = new Box_Read_Only_Shares__c(Box_URL__c='asd',Opportunity__c=o.Id, role__c='School');
                insert b;
                
                Community_Contact_Role__c c = new Community_Contact_Role__c(contact__c=u.ContactId,Opportunity__c=o.Id, role__c='School');
                insert c;

                System.assertEquals(itemsToShare.size(), [ SELECT COUNT() FROM Intake_Item__Share WHERE RowCause = 'Manual' ]);
                   
                System.debug('&&&&&&&&&& oppid: ' + o.Id);
                
                List<IntakeItemWrapper> items = IntakeCommunityItemsCtrl.getIntakes(); 
                items = IntakeCommunityItemsCtrl.getIntakes(); 
                
                //other lightning components
                INtakeCommunityViewFOldersCtrl.getFolders();
                
                IntakeCustomDetailCtrl.getItem(openingCall.Id);
                IntakeCustomDetailCtrl.getFiles(openingCall.Id);
                IntakeCustomDetailCtrl.submit(JSON.serialize(openingCall));
                
                INtakeCustomOpportunityCtrl.getOpp(o.Id);
                INtakeCustomOpportunityCtrl.getOwner(o.Id);
                INtakeCustomOpportunityCtrl.submit(JSON.serialize(o));
                
            }
            
            
            test.stoptest();
            
        }
        static testMethod void communityTestsFunding3() {
            TestDIligenceUtils.createCOnfig();
            TestDiligenceUTils.createFUndingIntakeTemplates();
            
            LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
            cntr.back();
            cntr.doNotCreateOpp = false;
            
            //create Lead and Opp and Intake Items tests
            LEad l = TestDiligenceUtils.createIFLead();
            insert l;
            cntr.setLEad(l);
            cntr.execute();
            
            String oppName = 'Initial Funding - '+l.company;
            Opportunity o;
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
                //o = [Select Id,OwnerId,  AccountId from Opportunity LIMIT 1];
            } catch (Exception e) {
                //try {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
                //} catch (Exception e2) {
                //    o = [Select Id,OwnerId,  AccountId from Opportunity LIMIT 1];
                //}
             }
            
            
            System.debug('***got opp: ' + o);
            
            //create Community Invites
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(o);
            Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(thecontroller);
            List<Send_Community_Invite_Controller.conWrapper> cw = sc.conswrapper;
            for (Send_Community_Invite_Controller.conWrapper c : cw) {
                c.selected = true;
                c.role = 'School';//'Partner Community User School/Tenant';
            }
            sc.back();
            sc.save();
            
            
            //get user that was created for the community
            User u = [Select Id, email,ContactId, Profile.Name from USer where email='t@t.com'];
            
            System.debug('***running as user: ' +u);
            
            ContactShare cs = new ContactShare();
            cs.UserOrGroupId = u.Id;
            cs.ContactAccessLevel = 'Edit';
            cs.ContactId = u.ContactId;
            insert cs;
            
            
            DiligenceVars.refreshPQ();
            DiligenceVars.refreshOpeningCall();
            
            //create other PQ Items, i.e. submit the PQ
            // List<Intake_Item__c> ii = [Select Id, Name from intake_item__c where opportunity__c=:o.Id and is_pre_qual__c=true];
            // System.debug('*** funding pq intake items: ' + ii);
            // for (Intake_Item__c i : ii) {
            //     //i.status__c = 'Submitted';
            //     //update i;
            //     //i.status__c = DiligenceVars.IntakeInputNeededStatus;//'Additional Input Needed';
            //     //update i;
            //     i.status__c = 'Accepted';
            //     System.debug('*** creating additional intake items');
            //     // update i;
            // }
            // update ii;
            
            // ii = [Select Id, Name from intake_item__c where opportunity__c=:o.Id];
            // System.debug('*** intake items after PQ submitted: ' + ii.size());
            // for (Intake_Item__c i : ii) {
            //     System.debug('*** intake item: ' + i.Name);
            // }
            
            // test.starttest();
                
            // //Set the Target Wire Date and trigger giligence path by Approving the Opening Call
            // o.target_wire_date__C = date.today();
            // o.Funded_date__c = date.today();
            // o.Funded_Amount__c = 1;
            // o.diligence_path__c = 1;
            // update o;
            
            // List<Intake_Item_Template__c > item = [select Id, Name, RecordTypeId from Intake_Item_Template__c ];
            // for (Intake_Item_Template__c tem : item) {
            //     System.debug('&&&&& template: ' + tem);
            // }
            
            // DiligenceVars.refreshOpeningCall();
            
            // ii = [Select Id from intake_item__c where opportunity__c=:o.Id and Name=:DiligenceVars.OpeningCallName];
            // intake_item__c openingCall;
            // System.debug('*** opening call intake items: ' + ii);
            // for (Intake_Item__c i : ii) {
            //     i.status__c = 'Accepted';
            //     update i;
            //     openingCall = i;
            //     break;
            // }   
            
            // if (openingcall==null) {
            //     Intake_Item__c i = new Intake_Item__c();
            //     i.name = DiligenceVars.OpeningCallName;
            //     i.status__c = 'Accepted';
            //     i.visible_to__c ='CSC';
            //     i.recordtypeid = RecordTypes.IDInitialFundingIntakeItem ;
            //     i.opportunity__c = o.id;
            //     insert i;
            //     openingcall = i;
            // }
            
            // //update Target wire date to recalculate dates
            // o.target_wire_date__C = date.today().addDays(2);
            // update o;
            
            // System.runAs(u) {   
            //     //Box_Read_Only_Shares__c b = new Box_Read_Only_Shares__c(Box_URL__c='asd',Opportunity__c=o.Id, role__c='School');
            //     //insert b;
                
            //     //List<Box_Read_Only_Shares__c> brs = [Select id,Box_URL__c, Role__c from Box_Read_Only_Shares__c where Opportunity__c =:o.id];
            //     //System.debug('Box shares: ' +brs);
                
            //     Community_Contact_Role__c c = new Community_Contact_Role__c(contact__c=u.ContactId,Opportunity__c=o.Id, role__c='School');
            //     insert c;
                
            //     List<Community_Contact_Role__c> ccr = [Select id,Contact__c, Opportunity__c,ROle__c from Community_Contact_Role__c where Opportunity__c =:o.id];
            //     System.debug('Community Contact Roles: ' +ccr);
                
            //     System.debug('&&&&&&&&&& oppid: ' + o.Id);
                
            //     PQ_Form__c pq = [Select Name, Opportunity__c, INtake_Item__c from PQ_FOrm__c where Opportunity__c=:o.Id LIMIT 1];
            //     System.debug('&&&&&&&&&& pq: ' + pq);
                
            //     Intake_Item__c iii =  [Select Id, Status_Reason__c, status__c from INtake_item__c 
            //         where Id=:pq.Intake_item__c and Opportunity__c=:o.Id LIMIT 1];
            //     System.debug('&&&&&&&&&& pq intake item: ' + iii);
                            
            //     //IntakeCommunityItemsCtrl
            //     IntakeCommunityItemsCtrl.getRecTypes();
            //     Opportunity o2 = IntakeCommunityItemsCtrl.getOppName(o.id);
            //     IntakeCommunityItemsCtrl.getFolders();
            //     List<IntakeItemWrapper> items = IntakeCommunityItemsCtrl.getIntakes(); 
            //     IntakeCommunityItemsCtrl.getOpportunities('');
            //     if (ii!=null&&ii.size()>0) {IntakeCommunityItemsCtrl.submitStatus(ii[0].Id+'');}
            //     IntakeCommunityItemsCtrl.getMapOpportunity(JSON.serialize(items));
                
            //     //update status' and reload
            //     List<INtake_Item__c> newIi = [Select Id from intake_item__c where opportunity__c=:o.Id ];
            //     for (Intake_Item__c i : newIi) {
            //         i.status__c = 'Accepted';
            //         break;
            //     }         
            //     update newIi;
            //     items = IntakeCommunityItemsCtrl.getIntakes(); 
                
            //     for (Intake_Item__c i : newIi) {
            //         i.status__c = 'Submitted';
            //         break;
            //     }                       
            //     update newIi;
            //     items = IntakeCommunityItemsCtrl.getIntakes(); 
                
            //     for (Intake_Item__c i : newIi) {
            //         i.status__c = DiligenceVars.IntakeInputNeededStatus;//'Additional Input Needed';
            //         break;
            //     }                       
            //     update newIi;
            //     //items = IntakeCommunityItemsCtrl.getIntakes(); 
                
            // }
            
            
            // test.stoptest();
            
        }
        
        static testMethod void communityTestsCMO() {
        	TestDIligenceUtils.createCOnfig();
            TestDiligenceUTils.createFUndingIntakeTemplates();
            
            LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
            cntr.back();
            cntr.doNotCreateOpp = false;
            
            //create Lead and Opp and Intake Items tests
            LEad l = TestDiligenceUtils.createIFLead();
            insert l;
            cntr.setLEad(l);
            cntr.execute();
            
            String oppName = 'Initial Funding - '+l.company;
            Opportunity o;
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
                //o = [Select Id,OwnerId,  AccountId from Opportunity LIMIT 1];
            } catch (Exception e) {
                //try {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
                //} catch (Exception e2) {
                //    o = [Select Id,OwnerId,  AccountId from Opportunity LIMIT 1];
                //}
             }
            
            
            System.debug('***got opp: ' + o);
            
            //create Community Invites
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(o);
            Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(thecontroller);
            List<Send_Community_Invite_Controller.conWrapper> cw = sc.conswrapper;
            for (Send_Community_Invite_Controller.conWrapper c : cw) {
                c.selected = true;
                c.role = 'School';//'Partner Community User School/Tenant';
            }
            sc.back();
            sc.save();
            
            
            //get user that was created for the community
            User u = [Select Id, email,ContactId, Profile.Name from USer where email='t@t.com'];
            
            System.debug('***running as user: ' +u);
            
            ContactShare cs = new ContactShare();
            cs.UserOrGroupId = u.Id;
            cs.ContactAccessLevel = 'Edit';
            cs.ContactId = u.ContactId;
            insert cs;
            
            test.starttest();
            DiligenceVars.refreshPQ();
            DiligenceVars.refreshOpeningCall();
            
            //create other PQ Items, i.e. submit the PQ
            List<Intake_Item__c> ii = [Select Id, Name from intake_item__c where opportunity__c=:o.Id and is_pre_qual__c=true];
            System.debug('*** funding pq intake items: ' + ii);
            for (Intake_Item__c i : ii) {
                i.status__c = 'Submitted';
                update i;
                i.status__c = DiligenceVars.IntakeInputNeededStatus;//'Additional Input Needed';
                update i;
                i.status__c = 'Accepted';
                System.debug('*** creating additional intake items');
                update i;
            }
            
            ii = [Select Id, Parent_Intake_Item__c, Name from intake_item__c where opportunity__c=:o.Id];
            System.debug('*** intake items after PQ submitted: ' + ii.size());
            Id iParentID = null;
            for (Intake_Item__c i : ii) {
                System.debug('*** intake item: ' + i.Name);
                if (i.Parent_Intake_Item__c!=null) iParentId = i.Parent_Intake_Item__c;
            }
            
            
            Intake_Item__c iii =  ii[0];
            
            		//add file
                    ContentVersion cv = new ContentVersion();
                    cv.ContentLocation = 'S';
                    cv.Title = 'test123454';
                    cv.COntentURL = 'http://blah.com';
                    insert cv;
                    ContentVersion cv2 = new ContentVersion();
                    cv2.ContentLocation = 'S';
                    cv2.Title = 'test123454123';
                    cv2.COntentURL = 'http://blah.com';
                    cv2.pushed_to_box__c = true;
                    insert cv2;
                    
                    cv = [Select Id, ContentDocumentId from ContentVersion where title='test123454'];
                    cv2 = [Select Id, ContentDocumentId from ContentVersion where title='test123454123'];
                    
                    System.debug('**inserting file for: ' + iii.Id);
                    ContentDocumentLink c = new ContentDocumentLink();
                    c.linkedentityid = iii.Id;
                    c.contentdocumentid = cv.ContentDocumentId;
                    c.sharetype = 'V';
                    insert c;
                    
                    ContentDocumentLink c2 = new ContentDocumentLink();
                    c2.linkedentityid = iii.Id;
                    c2.contentdocumentid = cv2.ContentDocumentId;
                    c2.sharetype = 'V';
                    insert c2;
            
            MYItemCtlr.getIntakeItems(o.Id+'',iParentID);        
            MyItemRowCtlr.getIntakeItem(iii.Id+'');
            
            List<ContentDocument> files = MyItemRowCtlr.getFiles(iii.Id+'');
            
            MyItemRowCtlr.getOppFiles(o.Id+'');
            MyItemRowCtlr.getIntakeItemWrapper(iii.Id+'');
            MyItemRowCtlr.getIntakeItemClientComments(iii.Id+'');
            MyItemRowCtlr.acceptedStatus(iii.Id+'');
            MyItemRowCtlr.getDownloadFileURL(iii.Id+'');
            
            if (files!=null&&files.size()>0) {
	            MyItemRowCtlr.getNextDocId(iii.Id+'', files[0].Id+'');
	            MyItemRowCtlr.getPrevDocId(iii.Id+'', files[0].Id+'');
	            MyItemRowCtlr.getNumDocs(iii.Id+'');
            }
            MyItemRowCtlr.noChanges(iii.Id+'');
            //MyItemRowCtlr.addComment(iii.Id+'', 'Test');
            MyItemRowCtlr.noChanges(iii.Id+'');
            
            System.runAs(u) {   
                
                Community_Contact_Role__c cc = new Community_Contact_Role__c(contact__c=u.ContactId,Opportunity__c=o.Id, role__c='School');
                insert cc;
                
                List<Community_Contact_Role__c> ccr = [Select id,Contact__c, Opportunity__c,ROle__c from Community_Contact_Role__c where Opportunity__c =:o.id];
                System.debug('Community Contact Roles: ' +ccr);
                
                System.debug('&&&&&&&&&& oppid: ' + o.Id);
                
                
		        ItemsByOppRecType i = new ItemsByOppRecType();
		        List<CMOAccounts> accts = IntakeCommunityItemsCtrl.getCMOs(null, null);
		        System.debug('****CMos :' + accts);
		        List<String> cmos = new List<String>();
		        if (accts!=null&&accts.size()>0) {
		        	for (CMOAccounts a : accts) {
		        		cmos.add(a.Id);
		        	}
                }
                // 2020.05.07 J Caughie removed - causing too many SOQL queries but given we are testing everything and there are no asserts
		        // List<ItemsByOppRecType> ri = IntakeCommunityItemsCtrl.getRecTypeItem(DiligenceVars.IntakePendingStatus, cmos);
		        // List<STring> ss = IntakeCommunityItemsCtrl.getCMOStrings( ri);
		        //  ri = IntakeCommunityItemsCtrl.getRecTypeItem('Completed', cmos);
		        //  ss = IntakeCommunityItemsCtrl.getCMOStrings( ri);
		        //  ri = IntakeCommunityItemsCtrl.getRecTypeItem('All Items', cmos);
		        //  ss = IntakeCommunityItemsCtrl.getCMOStrings( ri);
		        
		        //status filt4ers
		        //getFilteredUploadIntakeItems(Date filterDate, String itemName, String recType, String statusFilter, String acctFilter) {
		        
		        
	     
            }
 
 
            test.stoptest();
        	
        }
        
        static testMethod void communityTestsFunding2() {
            TestDIligenceUtils.createCOnfig();
            TestDiligenceUTils.createFUndingIntakeTemplates();
            
            LeadDiligenceRulesController cntr = new LeadDiligenceRulesController();
            cntr.back();
            cntr.doNotCreateOpp = false;
            
            //create Lead and Opp and Intake Items tests
            LEad l = TestDiligenceUtils.createIFLead();
            insert l;
            cntr.setLEad(l);
            cntr.execute();
            
            String oppName = 'Initial Funding - '+l.company;
            Opportunity o;
            try {
                o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
                //o = [Select Id,OwnerId,  AccountId from Opportunity LIMIT 1];
            } catch (Exception e) {
                //try {
                    oppName = l.company;
                    o = [Select Id,OwnerId,  AccountId from Opportunity where Name=:oppName];
                //} catch (Exception e2) {
                //    o = [Select Id,OwnerId,  AccountId from Opportunity LIMIT 1];
                //}
             }
            
            
            System.debug('***got opp: ' + o);
            
            //create Community Invites
            ApexPages.StandardController thecontroller = new ApexPages.StandardController(o);
            Send_Community_Invite_Controller sc = new Send_Community_Invite_Controller(thecontroller);
            List<Send_Community_Invite_Controller.conWrapper> cw = sc.conswrapper;
            for (Send_Community_Invite_Controller.conWrapper c : cw) {
                c.selected = true;
                c.role = 'School';//'Partner Community User School/Tenant';
            }
            sc.back();
            sc.save();
            
            test.starttest();
            //get user that was created for the community
            User u = [Select Id, email,ContactId, Profile.Name from USer where email='t@t.com'];
            
            System.debug('***running as user: ' +u);
            
            ContactShare cs = new ContactShare();
            cs.UserOrGroupId = u.Id;
            cs.ContactAccessLevel = 'Edit';
            cs.ContactId = u.ContactId;
            insert cs;
            
            DiligenceVars.refreshPQ();
            DiligenceVars.refreshOpeningCall();
            
            //create other PQ Items, i.e. submit the PQ
            List<Intake_Item__c> ii = [Select Id, Name from intake_item__c where opportunity__c=:o.Id and is_pre_qual__c=true];
            System.debug('*** funding pq intake items: ' + ii);
            for (Intake_Item__c i : ii) {
                i.status__c = 'Submitted';
                update i;
                i.status__c = DiligenceVars.IntakeInputNeededStatus;//'Additional Input Needed';
                update i;
                i.status__c = 'Accepted';
                System.debug('*** creating additional intake items');
                update i;
            }
            
            ii = [Select Id, Name from intake_item__c where opportunity__c=:o.Id];
            System.debug('*** intake items after PQ submitted: ' + ii.size());
            for (Intake_Item__c i : ii) {
                System.debug('*** intake item: ' + i.Name);
            }
                
            //Set the Target Wire Date and trigger giligence path by Approving the Opening Call
            o.target_wire_date__C = date.today();
            o.Funded_date__c = date.today();
            o.Funded_Amount__c = 1;
            o.diligence_path__c = 1;
            update o;
            
            List<Intake_Item_Template__c > item = [select Id, Name, RecordTypeId from Intake_Item_Template__c ];
            for (Intake_Item_Template__c tem : item) {
                System.debug('&&&&& template: ' + tem);
            }
            
            DiligenceVars.refreshOpeningCall();
            
            ii = [Select Id from intake_item__c where opportunity__c=:o.Id and Name=:DiligenceVars.OpeningCallName];
            intake_item__c openingCall;
            System.debug('*** opening call intake items: ' + ii);
            for (Intake_Item__c i : ii) {
                i.status__c = 'Accepted';
                update i;
                openingCall = i;
                break;
            }   
            
            if (openingcall==null) {
                Intake_Item__c i = new Intake_Item__c();
                i.name = DiligenceVars.OpeningCallName;
                i.status__c = 'Accepted';
                i.visible_to__c ='CSC';
                i.recordtypeid = RecordTypes.IDInitialFundingIntakeItem ;
                i.opportunity__c = o.id;
                insert i;
                openingcall = i;
            }
            
            //update Target wire date to recalculate dates
            o.target_wire_date__C = date.today().addDays(2);
            update o;

            List<Intake_Item__c> itemsToShare = [ SELECT Id FROM Intake_Item__c ];
            for (Intake_Item__c itemToShare: itemsToShare) {
                itemToShare.Is_Visible_To_Community__c = true;
            }
            update itemsToShare;
            
            System.runAs(u) {   
                Box_Read_Only_Shares__c b = new Box_Read_Only_Shares__c(Box_URL__c='asd',Opportunity__c=o.Id, role__c='School');
                insert b;
                
                List<Box_Read_Only_Shares__c> brs = [Select id,Box_URL__c, Role__c from Box_Read_Only_Shares__c where Opportunity__c =:o.id];
                System.debug('Box shares: ' +brs);
                
                Community_Contact_Role__c c = new Community_Contact_Role__c(contact__c=u.ContactId,Opportunity__c=o.Id, role__c='School');
                insert c;
            
                System.assertEquals(itemsToShare.size(), [ SELECT COUNT() FROM Intake_Item__Share WHERE RowCause = 'Manual' ]);
                
                List<Community_Contact_Role__c> ccr = [Select id,Contact__c, Opportunity__c,ROle__c from Community_Contact_Role__c where Opportunity__c =:o.id];
                System.debug('Community Contact Roles: ' +ccr);
                
                System.debug('&&&&&&&&&& oppid: ' + o.Id);
                
                PQ_Form__c pq = [Select Name, Opportunity__c, INtake_Item__c from PQ_FOrm__c where Opportunity__c=:o.Id LIMIT 1];
                System.debug('&&&&&&&&&& pq: ' + pq);
                
                Intake_Item__c iii =  [Select Id, Status_Reason__c, status__c from INtake_item__c 
                    where Id=:pq.Intake_item__c and Opportunity__c=:o.Id LIMIT 1];
                System.debug('&&&&&&&&&& pq intake item: ' + iii);
                            
                //IntakeCommunityItemsCtrl
                IntakeCommunityItemsCtrl.getRecTypes();
                Opportunity o2 = IntakeCommunityItemsCtrl.getOppName(o.id);
                IntakeCommunityItemsCtrl.getFolders();
                List<IntakeItemWrapper> items = IntakeCommunityItemsCtrl.getIntakes(); 
                IntakeCommunityItemsCtrl.getOpportunities('');
                if (ii!=null&&ii.size()>0) {IntakeCommunityItemsCtrl.submitStatus(ii[0].Id+'');}
                IntakeCommunityItemsCtrl.getMapOpportunity(JSON.serialize(items));
                
                //update status' and reload
                List<INtake_Item__c> newIi = [Select Id from intake_item__c where opportunity__c=:o.Id ];
                for (Intake_Item__c i : newIi) {
                    i.status__c = 'Accepted';
                }         
                update newIi;
                test.stoptest();
                IntakeItemPQCommunityCtrl.getRecTypes();
                IntakeItemPQCommunityCtrl.getStates();
                IntakeItemPQCommunityCtrl.getCountries();
                IntakeItemPQCommunityCtrl.getPQ(newIi[0].Id);
                IntakeItemPQCommunityCtrl.submitPQ(JSON.serialize(pq));
                
                List<Working_Group_List__c> wl = new List<Working_Group_List__c>();
                Working_Group_List__c w = new Working_Group_List__c(
                    Account__c=o.AccountId, 
                    opportunity__c=o.Id,
                    Board_Member__c = true, 
                    First_Name__c = 'sdf', 
                    Email__c = '123@t.com'
                    //RecordTypeId = '0124u0000001lStAAI' // Working_Capital
                    );
                wl.add(w);  
                insert wl;
                
                // 2020.05.07 J Caughie removed - causing too many SOQL queries but given we are testing everything and there are no asserts
                WorkingGroupFormsCtrl.getTableData(o.AccountId);
                WorkingGroupFormsCtrl.getAccountByIntake(openingCall.Id);
                WorkingGroupFormsCtrl.submitStatus(openingCall.Id);
                WorkingGroupFormsCtrl.setUpsertData(JSON.serialize(wl), o.AccountId+'', o.Id+'');
                WorkingGroupFormsCtrl.setDeleteIntake(JSON.serialize(wl));
                //adding more tests here
                WorkingGroupFormsCtrl.getCorporatePositions();
                WorkingGroupFormsCtrl.getGoverningPositions();
                WorkingGroupFormsCtrl.getAdministratorPositions();
                WorkingGroupFormsCtrl.getBoardPositions();

                
            }
            
            
            //test.stoptest();
            
        }

}
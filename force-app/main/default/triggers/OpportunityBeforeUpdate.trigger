trigger OpportunityBeforeUpdate on Opportunity (before update) {
    //M Olinger - 04/27/18 - Set the Opp Owner fiedls - this is needed becasue we have too many object references to create formual fields on the Opportunity
    //2021.03.17 J Caughie - looks redundant, the field updates on Owner_Email__c/Owner_Name__c/Owner_Phone__c were already commented out. Review during Technical Debt assessment
    /*
    Map<Id,Opportunity> ownerIds = new Map<Id,Opportunity>();
    
    for(Opportunity opp : trigger.new) {
    	System.debug('**** opp owner: ' + opp.ownerId);
    	if (opp.ownerid!=null) {
    		ownerIds.put(opp.ownerId,opp);
    	}
    }
    
    if (ownerIds.size()>0) {
    	Map<Id,User> userMap = new Map<Id,User>();
    	List<User> uu = [Select Id, FirstName, LastName, Email, Phone from User where Id IN:ownerIds.keyset()];
    	for (User u : uu) {
    		userMap.put(u.Id,u);
    	}
    	for(Id i : ownerIds.keyset()) {
    		System.debug('****setting opp owner email: ' + userMap.get(i).EMail);
    		ownerIds.get(i).Owner_Email__c = userMap.get(i).EMail;
    		ownerIds.get(i).Owner_Name__c = userMap.get(i).FirstName + ' ' + userMap.get(i).LastName;
    		ownerIds.get(i).Owner_Phone__c = userMap.get(i).Phone;
    		
    		//opp.Owner_Email__c = opp.owner.Email;
    		//opp.Owner_Name__c = opp.owner.FIrstName + ' ' + opp.owner.LastName;
    		//opp.Owner_Phone__c = opp.owner.Phone;
    	}	
    		
    }
    */
    /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
      the triggers, validation rules and workflow rules fire*/
    BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance(UserInfo.getUserId());
    // 05/06/2014 : Manisha Gupta : Add null check (T-276525)
    if(ProfileCustomSettings.Trigger_Objects__c == null){
    	ProfileCustomSettings.Trigger_Objects__c = '';
	}
	if(ProfileCustomSettings.Triggers_Disabled__c == null){
	    ProfileCustomSettings.Triggers_Disabled__c = false;
	}
	if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('opportunity') && ProfileCustomSettings.Triggers_Disabled__c)){
        
        //2017.04.06 J Caughie - update Signers before
        System.debug('old:' + Trigger.old);
        new OpportunityHelper().onBeforeUpdate(Trigger.newMap, Trigger.oldMap);
        System.debug('new:' + Trigger.new);
        //2017.04.06 J Caughie - update Signers before
    
        //2021.03.17 J Caughie - almost added run once condition. This code can probably be removed during Technical Debt assessment
        // if(!Flags.OpportunityBeforeUpdate){
        //     Flags.OpportunityBeforeUpdate = true;
            /*[04/03/14] - T-268092 - RA - This custom setting is used to conditionally control for which users/profile or the entire org
            the triggers, validation rules and workflow rules fire*/
            Map<Id, List<Opp_School__c>> oppSchoolsMap = new Map<Id, List<Opp_School__c>>();
            Map<Id, List<String>> oppSchoolNamesMap = new Map<Id, List<String>>();
            Map<Id, List<String>> emailCCMap = new Map<Id, List<String>>();
            Map<Id, List<List<String>>> oppTermsMap = new Map<Id, List<List<String>>>();
            Map<Id, List<List<String>>> oppAddressesMap = new Map<Id, List<List<String>>>();
            Map<Id, Set<String>> oppCountiesMap = new Map<Id, Set<String>>();
            Map<Id, Set<String>> oppCOEMap = new Map<Id, Set<String>>();
            Map<Id, Set<String>> oppCSOSMap = new Map<Id, Set<String>>();
            Map<Id, Set<String>> oppDistrictMap = new Map<Id, Set<String>>();
            List<Opportunity>  opps = new List<Opportunity>();
            Map<Integer, String> charPrefixMap = new Map<Integer, String> {
                1 => 'a', 2 => 'b', 3 => 'c', 4 => 'd', 5 => 'e', 6 => 'f', 7 => 'g', 8 => 'h', 9 => 'i', 10 => 'j', 11 => 'k', 12 => 'l', 13 => 'm',
                14 => 'n', 15 => 'o', 16 => 'p', 17 => 'q', 18 => 'r', 19 => 's', 20 => 't', 21 => 'u', 22 => 'v', 23 => 'w', 24 => 'x', 25 => 'y', 26 => 'z'
            };

            for(Opportunity opp : trigger.new) {
                Opportunity old = trigger.oldMap.get(opp.Id);
                Boolean oppSchoolsChanged = opp.Num_of_Opp_Schools__c != old.Num_of_Opp_Schools__c;
                Boolean manualTermsChanged = !opp.Manual_Charter_Terms__c && old.Manual_Charter_Terms__c;
                Boolean manualAuthChanged = !opp.Manual_Auth_Entity__c && old.Manual_Auth_Entity__c;
                Boolean manualObligorChanged = !opp.Manual_Obligor__c && old.Manual_Obligor__c;
                Boolean manualAddrChanged = !opp.Manual_School_Address__c && old.Manual_School_Address__c;

                // run it everytime for the time being
                // 2021.03.17 J Caughie - re-enabled boolean check
                if(Flags.ForceOpportunitySchoolsUpdate || oppSchoolsChanged || manualTermsChanged || manualAuthChanged || manualObligorChanged || manualAddrChanged) {
                    opps.add(opp);
                    oppSchoolsMap.put(opp.Id, new List<Opp_School__c>());
                    oppSchoolNamesMap.put(opp.Id, new List<String>());
                    emailCCMap.put(opp.AccountId, new List<String>());
                    oppTermsMap.put(opp.Id, new List<List<String>>());
                    oppAddressesMap.put(opp.Id, new List<List<String>>());
                    oppCountiesMap.put(opp.Id, new Set<String>());
                    oppCOEMap.put(opp.Id, new Set<String>());
                    oppCSOSMap.put(opp.Id, new Set<String>());
                    oppDistrictMap.put(opp.Id, new Set<String>());
                }
            }

            if(!opps.isEmpty()) {
                for(Related_Contact__c rc : [SELECT Account__c, Contact__c, Contact__r.Email FROM Related_Contact__c WHERE Account__c IN :emailCCMap.keySet() AND Funding_Docs__c = true AND Contact__r.Email != null]) {
                    List<String> emails = emailCCMap.get(rc.Account__c);
                    emails.add(rc.Contact__r.Email);
                }

                for(Opp_School__c oppSchool : [SELECT Id, Opportunity__c, Legal_Name__c, County__c, CSOS__c, Charter_Terms__c, Address__c, Authorizer__c, Authorizer__r.Name, COE__c, COE__r.Name, School_District__c, School_District__r.Name FROM Opp_School__c WHERE Opportunity__c IN :trigger.newMap.keySet() ORDER BY Opportunity__c, Legal_Name__c]) {
                    List<Opp_School__c> oppSchools = oppSchoolsMap.get(oppSchool.Opportunity__c);
                    List<String> schoolNames = oppSchoolNamesMap.get(oppSchool.Opportunity__c);
                    List<List<String>> termsComponentsList = oppTermsMap.get(oppSchool.Opportunity__c);
                    List<List<String>> addressComponentsList = oppAddressesMap.get(oppSchool.Opportunity__c);
                    Set<String> counties = oppCountiesMap.get(oppSchool.Opportunity__c);
                    Set<String> coes = oppCOEMap.get(oppSchool.Opportunity__c);
                    Set<String> csoss = oppCSOSMap.get(oppSchool.Opportunity__c);
                    Set<String> districts = oppDistrictMap.get(oppSchool.Opportunity__c);

                    oppSchools.add(oppSchool);
                    schoolNames.add(oppSchool.Legal_Name__c);

                    if(String.isNotBlank(oppSchool.Charter_Terms__c)) {
                        termsComponentsList.add(new List<String> { oppSchool.Charter_Terms__c, oppSchool.Legal_Name__c });
                    }

                    counties.add(oppSchool.County__c);
                    csoss.add(oppSchool.CSOS__c);

                    if(oppSchool.COE__c != null) {
                        coes.add(oppSchool.COE__r.Name);
                    }

                    if(oppSchool.School_District__c != null) {
                        districts.add(oppSchool.School_District__r.Name);
                    }

                    if(String.isNotBlank(oppSchool.Address__c)) {
                        addressComponentsList.add(new List<String> { oppSchool.Address__c, oppSchool.Legal_Name__c + ': ' +  oppSchool.Address__c});
                    }
                }

                for(Opportunity opp : opps) {
                    List<Opp_School__c> oppSchools = oppSchoolsMap.get(opp.Id);
                    List<String> schoolNames = oppSchoolNamesMap.get(opp.Id);
                    List<String> schoolNamesUpper = new List<String>();
                    List<String> obligors = new List<String>();
                    List<String> paaCounties = new List<String>();
                    List<List<String>> addressComponentsList = oppAddressesMap.get(opp.Id);
                    Set<String> counties = oppCountiesMap.get(opp.Id);
                    Set<String> coes = oppCOEMap.get(opp.Id);
                    Set<String> csoss = oppCSOSMap.get(opp.Id);
                    Set<String> districts = oppDistrictMap.get(opp.Id);

                    counties.remove(null);
                    counties.remove('');
                    coes.remove(null);
                    coes.remove('');
                    csoss.remove(null);
                    csoss.remove('');
                    districts.remove(null);
                    districts.remove('');

                    for(String schoolName : schoolNames) {
                        schoolNamesUpper.add(schoolName.toUpperCase());
                    }

                    if(schoolNames.size() > 2) {
                        Integer i = schoolNames.size() - 1;
                        String schoolName = 'and ' + schoolNames.get(i);
                        schoolNames.remove(i);
                        schoolNames.add(schoolName);

                        schoolName = 'and ' + schoolNamesUpper.get(i);
                        schoolNamesUpper.remove(i);
                        schoolNamesUpper.add(schoolName);
                    }

                    opp.Schools__c = String.join(schoolNamesUpper, schoolNamesUpper.size() > 2 ? ', ' : ' and ');
                    opp.School_LC__c = String.join(schoolNames, schoolNames.size() > 2 ? ', ' : ' and ');

                    if(!opp.Manual_Charter_Terms__c) {
                        opp.TL_Charter_Terms__c = '';
                        List<List<String>> termsComponentsList = oppTermsMap.get(opp.Id);
                        List<String> terms = new List<String>();

                        if(!termsComponentsList.isEmpty()) {
                            if(termsComponentsList.size() == 1) {
                                opp.TL_Charter_Terms__c = termsComponentsList.get(0).get(0);
                            } else {
                                for(List<String> termsComponents : termsComponentsList) {
                                    terms.add('(' + charPrefixMap.get(terms.size() + 1) + ') for ' + termsComponents.get(1) + ' ' + termsComponents.get(0));
                                }

                                opp.TL_Charter_Terms__c = String.join(terms, '; ');
                            }
                        }
                    }

                    if(!opp.Manual_Auth_Entity__c) {
                        opp.TL_Auth_Entity__c = '';
                        List<Opp_School__c> authSchools = new List<Opp_School__c>();

                        for(Opp_School__c oppSchool : oppSchools) {
                            if(String.isNotBlank(oppSchool.Legal_Name__c) && oppSchool.Authorizer__c != null) {
                                authSchools.add(oppSchool);
                            }
                        }

                        if(!authSchools.isEmpty()) {
                            if(authSchools.size() == 1) {
                                Opp_School__c oppSchool = authSchools.get(0);
                                opp.TL_Auth_Entity__c = oppSchool.Authorizer__r.Name;
                            } else {
                                List<String> authEntities = new List<String>();

                                for(Opp_School__c oppSchool : authSchools) {
                                    String prefix = '(' + charPrefixMap.get(authEntities.size() + 1) + ') ';
                                    authEntities.add(prefix + 'with respect to ' + oppSchool.Legal_Name__c + ', the ' + oppSchool.Authorizer__r.Name);
                                }

                                opp.TL_Auth_Entity__c = String.join(authEntities, ' ');
                            }
                        }
                    }

                    for(String county : counties) {
                        obligors.add(county + ' County');
                        paaCounties.add(county + ' County');
                    }

                    for(String coe : coes) {
                        obligors.add('the ' + coe);
                    }

                    for(String csos : csoss) {
                        obligors.add(csos);
                    }

                    obligors.add('the Special Education Local Plan Area (SELPA)');

                    for(String district : districts) {
                        obligors.add(district);
                        paaCounties.add(district);
                    }

                    if(!opp.Manual_Obligor__c) {
                        opp.TL_Obligor__c = '';

                        if(!obligors.isEmpty()) {
                            opp.TL_Obligor__c = String.join(obligors, ', ');
                        }
                    }

                    if(!opp.Manual_PAA_County__c) {
                        opp.PAA_County__c = '';

                        if(!paaCounties.isEmpty()) {
                            List<String> splitCounties = paaCounties.clone();
                            String lastPAACounty = splitCounties.remove(splitCounties.size() - 1);

                            if(!splitCounties.isEmpty()) {
                                opp.PAA_County__c = String.join(splitCounties, ', ') + ' and ';
                            }

                            opp.PAA_County__c += lastPAACounty;
                        }
                    }

                    if(!opp.Manual_School_Address__c) {
                        opp.TL_School_Address__c = '';

                        if(!addressComponentsList.isEmpty()) {
                            if(addressComponentsList.size() == 1) {
                                opp.TL_School_Address__c = addressComponentsList.get(0).get(0);
                            } else {
                                List<String> addresses = new List<String>();

                                for(List<String> addressComponents : addressComponentsList) {
                                    addresses.add('(' + charPrefixMap.get(addresses.size() + 1) + ') for ' + addressComponents.get(1));
                                }

                                opp.TL_School_Address__c = String.join(addresses, ' ');
                            }
                        }
                    }

                    if(!opp.Manual_Additional_To__c) {
                        List<String> emails = emailCCMap.get(opp.AccountId);
                        opp.Additional_To_FD__c = String.join(emails, ', ').left(255).trim();
                    }
                }
            }
        // }
    }
}
//
// (c) 2014 Appirio, Inc.
// MakeActiveSchoolAttendance_RateCardCont
//
// Common Controller class for MakeActiveRateCard_VF and MakeActiveSchoolAttendance_VF page
//
// MakeActiveRateCard_VF and MakeActiveSchoolAttendance_VF page : these pages are opened 
// from 'Make Active' button on Rate Card and Scholl attendance detail page respectively
//
// 12 May 2014     Anjali K(JDC)       Original

public with sharing class MakeActiveSchoolAttendance_RateCardCont {
	
	public Rate_Card__c rateCard {get;set;}
	public School_Attendance__c schoolAttendance {get;set;}
	
	//Constructor : Identify which is is the current object either Rate_Card__c or School_Attendance__c
	public MakeActiveSchoolAttendance_RateCardCont(ApexPages.StandardController controller) { 
    sObject obj= (sObject)controller.getRecord();
		String objType =  String.valueOf(obj.getSObjectType());
		if(objType == 'Rate_Card__c'){
			rateCard = (Rate_Card__c) obj;
		}else if(objType == 'School_Attendance__c'){
			schoolAttendance = (School_Attendance__c) obj;
		}
	}
	
	//Make Current Rate Card record to Active and make other Rate Card records to Inactive
	//Pick relative Rate cards as per current Rate Card's State_Province__c or COE_District__c
	//At a time only one field from State_Province__c & COE_District__c will have value
	public Pagereference makeCurrentRateCardActive(){
		List<Rate_Card__c> rateCardListToUpdate = new List<Rate_Card__c>();
		if(!rateCard.Active__c){
			rateCard.Active__c = true;
			rateCardListToUpdate.add(rateCard);
		}
		
		String SOQL = 'Select id from Rate_Card__c where id != \''+rateCard.id+'\'';
		if(rateCard.State_Province__c != null){
			SOQL += ' AND State_Province__c =\''+ rateCard.State_Province__c+'\'';
		}else if(rateCard.COE_District__c != null){
			SOQL += ' AND COE_District__c =\''+ rateCard.COE_District__c+'\'';
		}
		System.debug('SOQL::' + SOQL);
		for(Rate_Card__c otherRateCard : Database.query(SOQL)){
			otherRateCard.Active__c = false;
			rateCardListToUpdate.add(otherRateCard);
		}
		
		if(rateCardListToUpdate.size() > 0){
			update rateCardListToUpdate;
		}
		return new Pagereference('/'+rateCard.id);
	}
            
  //Make Current School_Attendance__c record to Active and make other School_Attendance__c records to Inactive related to current School_Attendance__c's School     
	public Pagereference makeCurrentSchoolAttendanceActive(){
		List<School_Attendance__c> schoolAttendancesToUpdate = new List<School_Attendance__c>();
		
		if(!schoolAttendance.Active__c){
			schoolAttendance.Active__c = true;
			schoolAttendancesToUpdate.add(schoolAttendance);
		}
		for(School_Attendance__c otherSchoolAttendance : [Select id from School_Attendance__c 
																											where id != :schoolAttendance.id 
																											AND School__c = :schoolAttendance.School__c]){
			otherSchoolAttendance.Active__c = false;
			schoolAttendancesToUpdate.add(otherSchoolAttendance);
		}
		
		if(schoolAttendancesToUpdate.size() > 0){
			update schoolAttendancesToUpdate;
		}
		return new Pagereference('/'+schoolAttendance.id);
	}
}
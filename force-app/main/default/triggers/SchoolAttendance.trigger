/**=====================================================================
 * Trigger Name: SchoolAttendance
 * Description: Trigger to update Charter Holder with total active attendance value
 * Created Date: [2016/01/25]
 * Created By: John Caughie
 * Date Modified                Modified By                  Description of the update
 * 
 =====================================================================*/

trigger SchoolAttendance on School_Attendance__c (after delete, after insert, after update) {
  BypassRulesandTriggers__c ProfileCustomSettings = BypassRulesandTriggers__c.getInstance();
  if(ProfileCustomSettings.Trigger_Objects__c == null){
      ProfileCustomSettings.Trigger_Objects__c = '';
  }
  if(ProfileCustomSettings.Triggers_Disabled__c == null){
      ProfileCustomSettings.Triggers_Disabled__c = false;
  }
  if(!(ProfileCustomSettings.Trigger_Objects__c.toLowerCase().contains('school_attendance__c') && ProfileCustomSettings.Triggers_Disabled__c)){
      if(Trigger.isAfter){
          if(Trigger.isInsert || Trigger.isUpdate){
            SchoolAttendanceTriggerManager.updateCharters(Trigger.New);
          }
          if(Trigger.isDelete){
            SchoolAttendanceTriggerManager.updateCharters(Trigger.Old);
          }
        } 
    }
}
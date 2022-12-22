/**=====================================================================
 * Charter School Capital
 * Name: AcademicRatingReportCtrl
 * Test Class: AcademicRatingReportCtrlTest
 * Description: support the AUM Academic Rating report, see academicRatingReport lwc
 * Created Date: []
 * Created By: [] 
 *
 * Date Modified                Modified By                  Description of the update
 * [MON DD, YYYY]             	[FirstName LastName]		 [Short description for changes]
 *  Sep 6, 2022				     Slava Krel				     fiscal year
 =====================================================================*/
public with sharing class AcademicRatingReportCtrl {

    @AuraEnabled(cacheable=true)
    public static List<SchoolDataWrapper> getSchoolData(){
        List<SchoolDataWrapper> schoolDataList = new List<SchoolDataWrapper>();

        //Get list of 'Active' Lease Schools
        List<Lease_School__c> leaseSchools = new List<Lease_School__c>();
        leaseSchools = [SELECT Id, Name, Account_School__r.Name, Account_School__r.Owner_Portfolio_Formula__c, Account_School__r.Grade_Level_Served__c, Account_School__r.Operating_State__r.Name, Lease__r.Property__r.Name, Lease__r.Owner_Portfolio__c, Lease__r.Property__r.Nick_Name__c, Lease_Status__c, Lease__r.Property__r.Equity_Investor__r.Name 
                        FROM Lease_School__c 
                        WHERE Lease_Status__c = 'Active' 
                        AND (Off_Date__c >= Today OR Off_Date__c = null) 
                        ORDER BY Lease__r.Property__r.Nick_Name__c];

        //Create list of School Ids
        List<Id> schoolIds = new List<Id>();
        for(Lease_School__c ls : leaseSchools){
            schoolIds.add(ls.Account_School__r.Id);
        }

        //Calculate current and previous Fiscal Year
        List<String> years = new List<String>();
        String currentYear, lastYear, twoYearsAgo, threeYearsAgo;
        Integer year;
        if (Date.today().year() == 2022){
            year = Date.today().year() - 1;
        } else {
            if(Date.today().month()>=11){
                year = Date.today().year();
                } else {
                year = Date.today().year() - 1;
            }
        }

        currentYear = String.valueOf(year).right(2) + '-' + String.valueOf(year + 1).right(2);
        System.debug('currentYear == '+currentYear);
        lastYear = String.valueOf(year - 1).right(2) + '-' + String.valueOf(year).right(2);
        System.debug('lastYear == '+lastYear);
        twoYearsAgo = String.valueOf(year - 2).right(2) + '-' + String.valueOf(year - 1).right(2);
        System.debug('twoYearsAgo == '+twoYearsAgo);
        threeYearsAgo = String.valueOf(year - 3).right(2) + '-' + String.valueOf(year - 2).right(2);
        System.debug('threeYearsAgo == '+threeYearsAgo);

        years.add(currentYear);
        years.add(lastYear);
        years.add(twoYearsAgo);
        years.add(threeYearsAgo);

        //Create a map of account Id to school with attendance and charter terms records
        Map<Id, Account> idToSchool = new Map<Id, Account>([SELECT Id, (SELECT Id, Name, Fiscal_Year__c, Description__c, Total_Attendance__c, Attendance_Type__c, Student_Count_Source__c, Report_Date__c, School__r.Id, School__r.Name 
                                                            FROM School_Attendance__r 
                                                            WHERE RecordType.DeveloperName = 'Facilities' 
                                                            AND Fiscal_Year__c IN :years 
                                                            ORDER BY School__r.Id, Fiscal_Year__c asc, Report_Date__c desc), (SELECT Start_Date__c, End_Date__c, Days_Left__c, Enrollment_Cap__c, No_Cap_Limit__c FROM Terms__r WHERE Status__c = 'Active') FROM Account WHERE id IN :schoolIds ORDER BY Name]);
		
        List <Academic_Rating__c> schoolARs = [SELECT Id, Name, FY__c, CSC_Color_Rating__c, Total_Grade__c, Account__c, Account__r.Name 
                                                FROM Academic_Rating__c 
                                                WHERE FY__c IN :years 
                                                ORDER BY Account__r.Id, FY__c asc];

        Id schoolId;

        for(Lease_School__c ls : leaseSchools){
            // System.debug('============================');
            SchoolDataWrapper schoolData = new SchoolDataWrapper();
            Account school = idToSchool.get(ls.Account_School__r.Id);
            schoolData.currentFY = currentYear;
            schoolData.previousFY = lastYear;
            schoolData.previous2FY = twoYearsAgo;
            schoolData.PropertyNickName = ls.Lease__r.Property__r.Nick_Name__c;
            schoolData.SchoolName = ls.Account_School__r.Name;
            schoolData.SchoolUrl = Url.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Account/' + ls.Account_School__r.Id + '/view' ;
            schoolData.StateName = ls.Account_School__r.Operating_State__r.Name;
            schoolData.PropertyOwner = ls.Lease__r.Owner_Portfolio__c;
            schoolData.GradeServed = ls.Account_School__r.Grade_Level_Served__c;

            Boolean currentYearARSet = false;
            Boolean previousYearARSet = false;
            Boolean twoYearsAgoARSet = false;
            Boolean threeYearsAgoARSet = false;

            for(Academic_Rating__c ar : schoolARs){

                if(ar.Account__c == school.Id){
                    if(ar.FY__c == currentYear && !currentYearARSet){
                        schoolData.CRCurrentYear = ar.CSC_Color_Rating__c;
                        schoolData.TGCurrentYear = ar.Total_Grade__c;
                        currentYearARSet = true;
                    }
                    if(ar.FY__c == lastYear && !previousYearARSet){ 
                        schoolData.CRPreviousYear = ar.CSC_Color_Rating__c;
                        schoolData.TGPreviousYear = ar.Total_Grade__c;
                        previousYearARSet = true;
                    }
                    if(ar.FY__c == twoYearsAgo && !twoYearsAgoARSet){
                        schoolData.CRTwoYearsAgo = ar.CSC_Color_Rating__c;
                        schoolData.TGTwoYearsAgo = ar.Total_Grade__c;
                        twoYearsAgoARSet = true;
                    }
                    if(ar.FY__c == threeYearsAgo && !threeYearsAgoARSet){
                        schoolData.CRThreeYearsAgo = ar.CSC_Color_Rating__c;
                        schoolData.TGThreeYearsAgo = ar.Total_Grade__c;
                        threeYearsAgoARSet = true;
                    }
                }

            }

            Boolean currentYearSet = false;
            Boolean previousYearSet = false;
            Boolean twoYearsAgoSet = false;

            for(School_Attendance__c sa : school.School_Attendance__r){

                if(sa.Fiscal_Year__c == currentYear && !currentYearSet){
                    schoolData.EnrollmentCurrentYear = sa.Total_Attendance__c.setScale(0);
                    currentYearSet = true;
                }
                if(sa.Fiscal_Year__c == lastYear && !previousYearSet){
                    schoolData.EnrollmentPreviousYear = sa.Total_Attendance__c.setScale(0);
                    previousYearSet = true;
                }
                if(sa.Fiscal_Year__c == twoYearsAgo && !twoYearsAgoSet){
                    schoolData.EnrollmentTwoYearsAgo = sa.Total_Attendance__c.setScale(0);
                    twoYearsAgoSet = true;
                }

            }

            if(schoolData.EnrollmentPreviousYear != null && schoolData.EnrollmentCurrentYear != null){
                schoolData.EnrollmentDiffCurrPrev = ((schoolData.EnrollmentCurrentYear - schoolData.EnrollmentPreviousYear)/schoolData.EnrollmentPreviousYear).setScale(2);
            }
            if(schoolData.EnrollmentPreviousYear != null && schoolData.EnrollmentTwoYearsAgo != null){
                schoolData.EnrollmentDiffPrevTwo = ((schoolData.EnrollmentPreviousYear - schoolData.EnrollmentTwoYearsAgo)/schoolData.EnrollmentTwoYearsAgo).setScale(2);
            }

            //cycle through Charter Terms records getting the cap and end date
            for(Charter_Term__c ct : school.Terms__r){
                schoolData.CharterExpirationDate = ct.End_Date__c;
                schoolData.RemainingCharterTerms = ct.Days_Left__c;

                if (ct.No_Cap_Limit__c == true){
                    schooldata.CharterCapacity = 'No limit';
                } else if (ct.Enrollment_Cap__c == null){
                    schooldata.CharterCapacity = 'Not listed';
                } else {
                    schooldata.CharterCapacity = String.valueOf(ct.Enrollment_Cap__c);
                }     
            }

            schoolDataList.add(schoolData);
        }
        return schoolDataList;
    }


    public class SchoolDataWrapper{
        @AuraEnabled
        public String PropertyNickName{get;set;}
        @AuraEnabled
        public String SchoolName{get;set;}
        @AuraEnabled
        public String SchoolUrl{get;set;}
        @AuraEnabled
        public String StateName{get;set;}
        @AuraEnabled
        public String PropertyOwner{get;set;}
        @AuraEnabled
        public Date CharterExpirationDate{get;set;}
        @AuraEnabled
        public Decimal RemainingCharterTerms{get;set;}
        @AuraEnabled
        public String CharterCapacity{get;set;}
        @AuraEnabled
        public String GradeServed{get;set;}
        @AuraEnabled
        public Decimal EnrollmentCurrentYear{get;set;}
        @AuraEnabled
        public Decimal EnrollmentPreviousYear{get;set;}
        @AuraEnabled
        public Decimal EnrollmentTwoYearsAgo{get;set;}
        @AuraEnabled
        public Decimal EnrollmentDiffCurrPrev{get;set;}
        @AuraEnabled
        public Decimal EnrollmentDiffPrevTwo{get;set;}
        @AuraEnabled
        public String CRCurrentYear{get;set;}
        @AuraEnabled
        public String TGCurrentYear{get;set;}
        @AuraEnabled
        public String CRPreviousYear{get;set;}
        @AuraEnabled
        public String TGPreviousYear{get;set;}
        @AuraEnabled
        public String CRTwoYearsAgo{get;set;}
        @AuraEnabled
        public String TGTwoYearsAgo{get;set;}
        @AuraEnabled
        public String CRThreeYearsAgo{get;set;}
        @AuraEnabled
        public String TGThreeYearsAgo{get;set;}
        @AuraEnabled
        public String currentFY{get;set;}
        @AuraEnabled
        public String previousFY{get;set;}
        @AuraEnabled
        public String previous2FY{get;set;}
    }
    
}
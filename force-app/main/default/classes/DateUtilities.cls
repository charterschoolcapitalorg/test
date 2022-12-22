public class DateUtilities {

    private static BusinessHours currentBusinessHours{
        get{
            if (currentBusinessHours == null) {
                currentBusinessHours = [SELECT Id, MondayStartTime, MondayEndTime, IsDefault FROM BusinessHours WHERE IsDefault = true];
            }
            return currentBusinessHours;
        }
        private set;
    }
    
    public static Date calculateStartDate(Date dueDate, Integer daysPrior) {
        //use the start of the due date as the target time, ie 8am
        DateTime completeBy = DateTime.newInstance(dueDate, currentBusinessHours.MondayStartTime);
        Integer standardHours = standardDailyHours();
        Long millis = (Long)daysPrior * standardHours * 60 * 60 * 1000;
        DateTime beginning = BusinessHours.add((String)currentBusinessHours.Id, completeBy, -millis);
        //System.debug(beginning);
        return beginning.date();
    }
    
    public static Integer calculateBusinessDays(Date startDate, Date endDate){
        DateTime startTime = DateTime.newInstance(startDate, currentBusinessHours.MondayEndTime);
        DateTime endTime = DateTime.newInstance(endDate, currentBusinessHours.MondayEndTime);
        Integer standardHours = standardDailyHours();
        Integer days;
        Long millis = BusinessHours.diff((String)currentBusinessHours.Id, startTime, endTime);
        //System.debug('mills: ' + millis);
        days = (Integer)(millis / ((Long)standardHours * 60 * 60 * 1000));
        return days;
    }

    public static Date getNextBusinessDay(Date startDate){
        //calculate from the end of the date specified
        DateTime startTime = DateTime.newInstance(startDate, currentBusinessHours.MondayEndTime);
        Integer standardHours = standardDailyHours();
        DateTime nextBusinessDay = BusinessHours.nextStartDate((String)currentBusinessHours.Id, startTime);
        //System.debug(beginning);
        return nextBusinessDay.date();
    }

    public static Date addBusinessDays(Date startDate, Integer additionalDays) {
        //use the end of the start date as the start time, ie 4pm
        DateTime start = DateTime.newInstance(startDate, currentBusinessHours.MondayEndTime);
        Integer standardHours = standardDailyHours();
        Long millis = (Long)additionalDays * standardHours * 60 * 60 * 1000;
        DateTime beginning = BusinessHours.add((String)currentBusinessHours.Id, start, millis);
        //System.debug(beginning);
        return beginning.date();
    }

    public static Boolean isBusinessDay(Date theDate){
        Boolean isBusinessDay;
        isBusinessDay = (theDate == getNextBusinessDay(calculateStartDate(theDate, 1)));
        return isBusinessDay;
    }
    
    private static Integer standardDailyHours(){
        Integer hours = 0;
        hours = currentBusinessHours.MondayEndTime.hour() - currentBusinessHours.MondayStartTime.hour();
        return hours;
    }
    
    //Matches SFDC Date class month, eg 1 = January, 2 = February
    public static String getLongMonth(Integer month){
        List<String> months = new List<String>{'January', 'February', 'March', 'April', 'May', 'June','July', 'August', 'September', 'October', 'November', 'December'};
        return months[month - 1];    
    }

    public static String getShortMonth(Integer month){
        return getLongMonth(month).left(3);    
    }    

    public static String getFiscalYear(Date inputDate){
        String fiscalYear;
        Integer year;
        if(inputDate.month()>=7){
            year = inputDate.year();
            } else {
            year = inputDate.year() - 1;
        }
        fiscalYear = String.valueOf(year).right(2) + '-' + String.valueOf(year + 1).right(2);
        return fiscalYear;
    }
}
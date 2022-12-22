/**=====================================================================
 * Name: HelperClass
 * Description: Misc helper classes
 * Created Date: [03/22/2017]
 * Created By: [John Caughie]
 *
 * Date Modified            Modified By                 Description of the update
 * [dd/mm/yyyy]            [name]              			[details]

 =====================================================================*/

public class HelperClass {

    public static Decimal CalculateInterest(Decimal principal, Date startDate, Date endDate, Decimal rate){
        Decimal interest = 0;
        interest = (principal * startDate.daysBetween(endDate) * rate / 100) / 360;
        return interest.setScale(2);
    }
    

}
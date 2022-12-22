public with sharing class DrawActivate {
    @InvocableMethod(label='Activate draw' description='Returns a boolean indicating if the draw was activated based on the Id passed in.' category='Other')
    public static List<Boolean> activateDraw(List<Id> drawIds){
        List<Boolean> returnValues = new List<Boolean>();
        returnValues.add(ActivateDraw.ActivateDrawNoteTX(drawIds[0]));
        return returnValues;
    }
}
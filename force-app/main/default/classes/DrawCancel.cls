public with sharing class DrawCancel {
    @InvocableMethod(label='Cancel draw' description='Cancels draw based on the Id passed in.' category='Other')
    public static void cancelDraw(List<Id> drawIds){
        ActivateDraw.cancelDraw(drawIds[0]);
    }
}
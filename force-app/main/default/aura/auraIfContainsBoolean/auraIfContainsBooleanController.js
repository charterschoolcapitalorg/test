({
	doInit: function(component, event, helper) {
        
        var getList = component.get('v.items'); 
        console.log('items in auraIf: ' + getList);
        var getElement = component.get('v.element');
        var getElementIndex = getList.indexOf(getElement);
        
        component.set('v.condition',false);
       for(var j = 0; j < getList.length; j++){
           if (getList[j]==getElement) {
               component.set('v.condition',true);
           }
       }
        /*
       // if getElementIndex is not equal to -1 it's means list contains this element. 
        if(getElementIndex != -1){ 
          component.set('v.condition',true);
        }else{
          component.set('v.condition',false);
        }
        */
    }
})
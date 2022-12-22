({ 
    doInit : function(component, event, helper) {
        var intakeItem = component.get("v.intakeItem");
        console.log('%%%%%% red flag on item: ' + intakeItem.Red_Flag_Instructions_For_Client__c);
        if (intakeItem.Red_Flag_Instructions_For_Client__c) {
            console.log('***** firing hasredflag');
            var myEvent = component.getEvent("hasredflag");
            myEvent.fire();
        }
        
        var today = new Date();
        var monthDigit = today.getMonth() + 1;
        if (monthDigit <= 9) {
            monthDigit = '0' + monthDigit;
        }
        component.set('v.today', today.getFullYear() + "-" + monthDigit + "-" + today.getDate());
	},
    reviewfile : function (component, event, helper){ 
        var intakeItem = component.get("v.intakeItem");
        console.log('Intake Item ' + intakeItem.Id);
        var action = component.get("c.getDownloadFileURL");
        action.setParams({"iId" : intakeItem.Id});
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            console.log('getFileURL Status ' + state);
            if (state === "SUCCESS") {               
				console.log(response.getReturnValue() );
                var ids = response.getReturnValue();
                if (ids!='') {
                    var separated = ids.split(",");
                    
                        for (var i in separated) {
                            //console.log('i: ' + separated[i]);
                            var theid = separated[i];
                            console.log('theid: ' + theid);
                            if (theid != '') {
                            	var url = '../sfc/servlet.shepherd/version/renditionDownload?rendition=SVGZ&versionId=' + theid; 
                                console.log('opening:' + url);
                                window.open(url);    
                            }
                            
                        }
                      
                }
                  
                
            } else {
                var message = 'There has been an error getting the file';
                helper.showToast('Error', message, '4000', 'info_alt', 'error', 'dismissible');                  
            }
          
        });
        
        $A.enqueueAction(action);     
    },
	handleCheck : function(component, event, helper) {   
        console.log('****** in handleCheck: ' + event);
        var source = event.getSource();
        var checked = source.get("v.checked");
        var recordId = source.get("v.value");
        component.set("v.selectedId", recordId);
        console.log('Selected ID: ' + component.get("v.selectedId"));
		var rowEvent = component.getEvent("rowEvent");
        rowEvent.setParams({"recordId" : recordId, "checked" : checked});
        rowEvent.fire();
        var fUpload = component.find("singleFileUpload");
        if(checked){
            fUpload.set("v.disabled", true);
        } else {
            fUpload.set("v.disabled", false);
        }
	},
    
    handleSingleUploadFinished : function(component, event, helper){
        var selectedIds = component.get("v.selectedIds");
        var uploadedFiles = event.getParam("files");
        for(var i = 0; i < uploadedFiles.length; i++){
        	console.log('File Name : ' + uploadedFiles[i].name);
            console.log('Doc Id : ' + uploadedFiles[i].documentId);
        }
        
        console.log('***** in handleSingleUploadFinished: firing docUploaded');
        var myEvent = component.getEvent("docUploaded");
        myEvent.fire();
        console.log('***** after handleSingleUploadFinished firing docUploaded');
        
        console.log('***** firing docUploadedToTop AGAIN ');
        var myEvent = component.getEvent("docUploadedToTop");
        myEvent.fire();
        console.log('***** after firing docUploadedToTop');
        
        helper.showUploadInfoToast(component, event, uploadedFiles[0].name);
    },
    FireOppEvent : function(component, event, helper) {
      var idx = event.currentTarget.getAttribute("id");
      console.log('***** id for FIreOppEvent: ' + idx);
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
          "url": '/itemdetail?res='+idx,
          "res": idx
        });
        urlEvent.fire();
     },
})
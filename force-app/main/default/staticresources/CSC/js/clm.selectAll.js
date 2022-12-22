var CLM = {};

(function($) {
var skipProcessing = false;
$(document).ready(function() {
	CLM.initSelectAll();
	
	$("form").on("change", ".clmSelectAllContainer .clmSelectAllCheck", function(e) {
		if(skipProcessing) {
			return false;
		}
		
		var elem = $(this);
		var checked = elem.is(":checked");
		skipProcessing = true;
		elem.parents(".clmSelectAllContainer").first().find(".clmSelectAllEnabled").each(function() {
			var origVal = $(this).is(":checked");
			$(this).prop("checked", checked);
			
			if(origVal != checked) {
				$(this).trigger("change");
			}
		});
		skipProcessing = false;
		
	});
	
	$("form").on("change", ".clmSelectAllContainer .clmSelectAllEnabled", function(e) {
		if(skipProcessing) {
			return false;
		}
		
		var elem = $(this);
		var container = elem.parents(".clmSelectAllContainer").first();
		var allChecks = container.find(".clmSelectAllEnabled");
		var checked = container.find(".clmSelectAllEnabled:checked");
		
		skipProcessing = true;
		container.find(".clmSelectAllCheck").prop("checked", allChecks.size() == checked.size());
		skipProcessing = false;
	});
});

CLM.checkSelectAllStatus = function() {
	$(".clmSelectAllContainer").each(function() {
		var container = jQuery(this);
		var allChecks = container.find(".clmSelectAllEnabled");
		var checked = container.find(".clmSelectAllEnabled:checked");
		
		skipProcessing = true;
		container.find(".clmSelectAllCheck").prop("checked", allChecks.size() == checked.size());
		skipProcessing = false;
	});
}

CLM.initSelectAll = function() {
	CLM.checkSelectAllStatus();
}
})(jQuery);
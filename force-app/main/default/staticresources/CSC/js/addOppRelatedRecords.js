(function($) {
$(document).ready(function() {
	var firstRpa = $(".rpaRadio").first();
	
	if(firstRpa.size() == 1) {
		firstRpa.prop("checked", "checked");
		updateHiddenVal(firstRpa);
	}
	
	var firstTl = $(".tlRadio").first();
	
	if(firstTl.size() == 1) {
		firstTl.prop("checked", "checked");
		updateHiddenVal(firstTl);
	}
	
	$(".rpaRadio, .tlRadio").change(function(e) {
		updateHiddenVal($(this));
	});
});

function updateHiddenVal(elem) {
	var hiddenElem = $("#" + elem.attr("data-hidden-field").replace(/(:|\.)/g,'\\$1'));
	hiddenElem.val(elem.val());
}
})(jQuery);
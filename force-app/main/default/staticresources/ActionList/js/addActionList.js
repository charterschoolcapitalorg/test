(function($) {
$(document).ready(function() {
	$(".actionListRadio").change(function(e) {
		$(".hiddenCheck").attr("checked", null);
		var elem = $(this);
		var checkElem = $("#" + elem.attr("data-checkbox").replace(/(:|\.)/g,'\\$1'));
		checkElem.attr("checked", elem.attr("checked"));
	});
});
})(jQuery);
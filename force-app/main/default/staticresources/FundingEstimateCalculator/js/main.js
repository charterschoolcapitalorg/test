$(document).ready(function() {
	$(".changeFlag").change(function() {
		$(this).addClass('changed');
	});
	
	$(".checkbox").click(function() {
		$(this).toggleClass('checked');
		$(this).closest('tr').find('td').toggleClass('highlightRow');
	});
	
	$("#schoolSelection td .checkbox").click(function() {
		var grv = $(this).closest('tr').find('.grv').asNumber();
		var $grvTotal = $(this).closest('table').find('.grvtotal');
		var grvTotal = $grvTotal.asNumber();
		grvTotal = ($(this).hasClass('checked') ? grvTotal + grv : grvTotal - grv);
		$grvTotal.html(grvTotal).formatCurrency({ roundToDecimalPlace: 0 });
	});
	
	$(".table-responsive th .checkbox").click(function() {
		var $parentTable = $(this).closest('table')
		var $checkboxes = $parentTable.find('.checkbox');
		var $rows = $parentTable.find('tbody td');
		var $grvs = $parentTable.find('.grv');
		var $grvTotal = $(this).closest('table').find('.grvtotal');
		if ($(this).hasClass('checked')) {
			$checkboxes.addClass('checked');
			$rows.addClass('highlightRow');
			var grvTotal = 0;
			$grvs.each(function() {
				grvTotal = grvTotal + $(this).asNumber();
			});
			$grvTotal.html(grvTotal).formatCurrency({ roundToDecimalPlace: 0 });;
		}
		else {
			$checkboxes.removeClass('checked');
			$rows.removeClass('highlightRow');
			$grvTotal.html("$000,000");
		}
	});
	
	$(".date-picker").datepicker();
	
	$(".closeModal").click(function() {
		if ($(this).attr('data-target')) {
			$($(this).attr('data-target')).modal('hide');
		}
	});
	
	$("#upaidBalance").change(function() {
		$(this).siblings('.long-description').show();
	});
	// NAVIGATION
	
	$("#step1-btn").click(function() {
		if ($(this).hasClass('btn-primary')){
			window.location.href='step2.html';
		}
	});
	$("#step2-btn").click(function() {
		window.location.href='step3.html';
	});
	$("#step2-prev-btn").click(function() {
		window.location.href='index.html';
	});
	$(".step3-prev-btn").click(function() {
		window.location.href='step2.html';
	});
	$(".step3-internal-btn").click(function() {
		window.location.href='internalSummary.html';
	});
});
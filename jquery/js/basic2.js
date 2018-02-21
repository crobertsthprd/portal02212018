jQuery(function ($) {
	// Load dialog on page load
	//$('#basic-modal-content').modal();

	// Load dialog on click
	$('.throttlecheckout').click(function (e) {
		$('#basic-modal-content').modal({onShow: function(dialog) {
			var delayseed=Math.floor(Math.random()*11);
               var delaymultiple = (delayseed * 1000) + 10000;
			//alert(delaymultiple);
			var delay = setTimeout("dosomething();",5000);
			
			
			//window.clearTimeout(delay)
			//$.modal.close();
			}
		} 
		);
		return false;
	});
});

function manualcall(theform) {	
	var theformname = document[theform];
	var delay = setTimeout(function(){theformname.submit()},5000);
	//var delay = setTimeout("myform.submit();",3000);
	var delay2 = setTimeout("$.modal.close();",6000);
	
	$('#basic-modal-content').modal({onClose: function (dialog) {
	//$.modal.close();
	//alert("close the modal!!!!!!!");
	$.modal.close();
	window.clearTimeout(delay);
	//return false;
}});

}

function nodelay(theform) {	
	var theformname = document[theform];
	theformname.submit();
};


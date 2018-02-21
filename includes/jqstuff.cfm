<!-- modal content -->
<CFPARAM name="currentstep" default="1">

<CFIF currentstep EQ 4>
	<!--- Message when we go to processor --->
	<CFSET themsg = "We are currently processing your request. Server load is quite heavy at the present, so it may take us some extra time to complete the transaction. Your classes have already been reserved - just be sure to complete payment in the next four hours. Thanks for your patience.">
<CFELSE>
	<!--- Message when we are checking out --->
	<CFSET themsg = "Thanks for using THPRD Online Registration. Please be patient as we gather your payment information. Please note that your class selections have been reserved - just be sure to complete payment in the next four hours. ">
</CFIF>



<div id="basic-modal-content">
     <h3 style="font-family:Verdana, Geneva, sans-serif">THPRD Registration Checkout</h3>
     <p align="center" style="font-family:Verdana, Geneva, sans-serif;font-size:12px;"><CFOUTPUT>#themsg#</CFOUTPUT><br>
     <br><img src="/portal/images/spinner.gif"></p>
     <div align="center"><img src="/portal/images/coffee4.jpg"></div>
</div>

<!-- preload the images -->
<div style='display:none'>
     <img src='/portal/jquery/img/basic/x.png' alt='' />
</div>

<!-- Load jQuery, SimpleModal and Basic JS files -->
<script type='text/javascript' src='/portal/jquery/js/jquery.js'></script>
<script type='text/javascript' src='/portal/jquery/js/jquery.simplemodal.js'></script>
<script type='text/javascript' src='/portal/jquery/js/basic2.js?v=<CFOUTPUT>#datepart('s',now())#</CFOUTPUT>'></script>

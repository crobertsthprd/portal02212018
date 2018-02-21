<cfquery name="Patron" datasource="#application.dopsds#">
	select   primarypatronID,
	         patronlookup,
	         firstname,
	         lastname,
	         indistrict,
	         loginstatus,
	         detachdate,
	         loginemail,
	         relationtype,
	         logindt,
	         insufficientID,
	         verifyexpiration,
	         locked
	from     dops.patroninfo
	where    ( patronlookup = <cfqueryparam value="#lTrim( rTrim( ucase( cookie.login ) ) )#" cfsqltype="cf_sql_varchar" list="no"> )
	and      loginstatus = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
	and      detachdate is null
</cfquery>

<!---<CFDUMP var="#form#">--->

<CFIF structkeyexists(form,"processcard")>

<!--- server side validation --->
<cfset ccNum = form.cardnumber>
<cfset firstNum = left(form.cardnumber,1)>
<cfset ccExp = form.cardExpMonth & "/" & right(form.cardExpYear,2)>
<cfset ccType = form.cardTypeName>
<!--- check card type and number for validity --->




<CF_mod10 ccType = "#firstnum#" ccNum="#ccNum#" ccExp="#ccExp#">


<cfset ccv1 = REREPLACE(form.cvNum,"[^0-9]","","ALL")>



<cfif len(ccv1) neq 3>
     <cfset valid = 0>
</cfif>

<cfif valid is 0>
     <CFSET maincontent="An invalid credit card number/CCV/expiration date was entered.<br> <a href=""javascript:history.back(); "">Please go back and try gain.</a>">
     <CFINCLUDE template="includes/layout.cfm">
     <cfabort>
</cfif>




<!---	<cf_cryp	[ type = "{ en* | de }" ] (en=encrypt, de=decrypt; default is "en")
                                   string = "{ string to encrypt or decrypt }"
                                   key = "{ key to use for encrypt or decrypt }"
                                   [ return = "{ name a variable to return to the calling page as a structure, default is 'cryp' }" --->
<cfset ccNum = REPLACE(ccNum," ","","ALL")>
<cfset ccNum = REREPLACE(ccNum,"[^0-9]","","ALL")>
<cfset ccExp = REPLACE(ccExp," ","","ALL")>
<cfset ccExp = REREPLACE(ccExp,"[^0-9]","","ALL")>
<cfset cc4 = trim(right(ccNum,4))>

<CFDUMP var="#variables#">

<cf_cryp type="en" string="#ccNum#" key="#skey#">
<cfset ccd = cryp.value>

<cfif ltrim(rtrim(ccv1)) is not "">
     <cf_cryp type="en" string="#ccv1#" key="#skey#">
     <cfset ccven = cryp.value>
</cfif>

<CFQUERY name="insertSession" datasource="#application.dopsds#">
Insert into dops.sessionccd 
(
sessionid, 
type, 
cca, 
exp, 
ccv,
cew
)
VALUES
(
<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.currentsessionid#">,
<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#firstNum#">,
<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#ccd#">,
<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#ccExp#">,
<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#ccven#">,
<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#cc4#">
)
</CFQUERY>




<!---- all done --->
<CFSAVECONTENT variable="maincontent">
An approval was received but you have not finished the transaction.
Close this window and click the Finish Transaction button on
the calling page to complete the transaction.<BR><BR>
<script>
alert("Finalizing Transaction for THPRD");
window.opener.document.finishtransaction.submit();
alert("Closing this window. ");
window.close();
</script>
<form name="f">
<input type="button" value="Close Window" onClick="window.close()" name="close1">
</form>
</CFSAVECONTENT>
<CFINCLUDE template="includes/layout.cfm">
<CFABORT>

<CFELSE>



<CFSAVECONTENT variable="maincontent">
<CFOUTPUT>
<form method="post" action="#cgi.script_name#">
<input type="hidden" name="processcard" value="true">
<input type="hidden" name="currentsessionID" value="#form.currentsessionID#">

<div align="center">        

<table>
<tr>
<td colspan="2"><div class="header">BILLING INFORMATION</div> (Must match the billing address for your credit card)<br></td>
</tr>
<tr>
<td>Name:</td>
<td><input type="text" name="BillToName" value="#patron.firstname# #patron.lastname#" class="field" size="45" /></td>
</tr>
<tr>
<td valign="top">Address:</td>
<td><input type="text" name="BillToStreet" value="" class="field" size="45" />
<div style="padding-top:2px;"><input type="text" name="BillToStreet2" value="" class="field" size="45" /></div></td>
</tr>
<tr>
<td>City:</td>
<td><input type="text" name="BillToCity" value="" class="field" size="45" /></td>
</tr>
<tr>
<td>State / Zip:</td>
<td><select name="BillToState" class="field">
<option value=''>Select...</option>
<option value='AL'>Alabama</option><option value='AK'>Alaska</option><option value='AZ'>Arizona</option><option value='AR'>Arkansas</option><option value='CA'>California</option><option value='CO'>Colorado</option><option value='CT'>Connecticut</option><option value='DE'>Delaware</option><option value='DC'>Dist of Columbia</option><option value='FL'>Florida</option><option value='GA'>Georgia</option><option value='HI'>Hawaii</option><option value='ID'>Idaho</option><option value='IL'>Illinois</option><option value='IN'>Indiana</option><option value='IA'>Iowa</option><option value='KS'>Kansas</option><option value='KY'>Kentucky</option><option value='LA'>Louisiana</option><option value='ME'>Maine</option><option value='MD'>Maryland</option><option value='MA'>Massachusetts</option><option value='MI'>Michigan</option><option value='MN'>Minnesota</option><option value='MS'>Mississippi</option><option value='MO'>Missouri</option><option value='MT'>Montana</option><option value='NE'>Nebraska</option><option value='NV'>Nevada</option><option value='NH'>New Hampshire</option><option value='NJ'>New Jersey</option><option value='NM'>New Mexico</option><option value='NY'>New York</option><option value='NC'>North Carolina</option><option value='ND'>North Dakota</option><option value='OH'>Ohio</option><option value='OK'>Oklahoma</option><option selected="selected" value='OR'>Oregon</option><option value='PA'>Pennsylvania</option><option value='RI'>Rhode Island</option><option value='SC'>South Carolina</option><option value='SD'>South Dakota</option><option value='TN'>Tennessee</option><option value='TX'>Texas</option><option value='UT'>Utah</option><option value='VT'>Vermont</option><option value='VA'>Virginia</option><option value='WA'>Washington</option><option value='WV'>West Virginia</option><option value='WI'>Wisconsin</option><option value='WY'>Wyoming</option>
</select> / <input type="text" name="BillToZip" class="field" size="14" value="" /></td>
</tr>
<tr>
<td>Phone:</td>
<td><input type="text" name="BillToPhone" value="" class="field" size="45" /></td>
</tr>
<tr>
<td>Email:</td>
<td><input type="text" name="BillToEmail" value="" class="field" size="45" /></td>
</tr>
<tr>
<td>Total:</td>
<td><input type='text' value='#form.TOTALAMT#' name='TotalAmt' disabled='disabled' readonly='readonly' class='field amount' size='12' /></td>
</tr>



<tr>
<td colspan="2"><!-- PaymentInformation --><br><div class="header">
PAYMENT INFORMATION</div></td>
</tr>
<tr>
<td>Payment Method:</td>
<td><select name="CardTypeName" class="field" >
	<option value=''>Select...</option>
	<option value='6'  st='cc'>Discover</option>
	<option value='4'  st='cc'>Visa</option>
	<option value='5'  st='cc'>Mastercard</option>
</select></td>
</tr>



<tr>
<td>Card Number:</td>
<td><input type="text" name="CardNumber" value="" class="field" size="20" maxlength="16" /></td>
</tr>
<tr>
<td>Exp. Date:</td>
<td>                                            <span><select name="CardExpMonth" class="field">
	<option value="01">- -</option>
	<option >01</option>
	<option >02</option>
	<option >03</option>
	<option >04</option>
	<option >05</option>
	<option >06</option>
	<option >07</option>
	<option >08</option>
	<option >09</option>
	<option >10</option>
	<option >11</option>
	<option >12</option>
</select>
</span> / 
									        <span><select name="CardExpYear" class="field">
	<option value='01'>- - - -</option>
	<option >2016</option>
	<option >2017</option>
	<option >2018</option>
	<option >2019</option>
	<option >2020</option>
	<option >2021</option>
	<option >2022</option>
	<option >2023</option>
	<option >2024</option>
	<option >2025</option>
</select>
</span>
</td>
</tr>
<tr>
<td>Security Code</td>
<td><input type="text" name="CVNum" value="" class="field" size="4" maxlength="4" />
<a href="cvv.htm" target="_blank" class="whatisthis">What is this?</a></td>
</tr>
<tr>
<td colspan="2" align="center">
<br>
<div class="button-container">
 <button type="submit" value="MAKE PAYMENT"><span><span><span class="ok">MAKE PAYMENT</span></span></span></button>  
         <button  type="reset" value="CLEAR FORM"><span><span><span class="redo">CLEAR FORM</span></span></span></button>
 <!-- CancelPayment -->
 <button  type="button" value="CANCEL"><span><span><span class="redo">CANCEL</span></span></span></button>
 <!-- /CancelPayment -->
</div>
</td>
</table>
</div>

                                        
                                    






<div class="error">
                                    
</div>

<input type="hidden" name="tg_IsPostBack" value="1" />
<input type="hidden" name="tg_WalletCardType" id="tg_WalletCardType" value="" />
<input type="hidden" name="tg_WalletExpDate" id="tg_WalletExpDate" value="" />
<input type="hidden" name="tg_WalletCardNumber" id="tg_WalletCardNumber" value="" />
<input type="hidden" name="ReturnUrl" id="ReturnUrl" value="https://www.thprd.org/portal/classes/checkoutregbp_www.cfm" />
<input type="hidden" name="CancelUrl" id="CancelUrl" value="https://www.thprd.org/isecure/bpcancel_www.cfm" />
</form>
</CFOUTPUT>
</CFSAVECONTENT>

<CFINCLUDE template="includes/layout.cfm">
</CFIF>
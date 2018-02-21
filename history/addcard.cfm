<CFSILENT>

<!--- offline pending rollout strategy 
<CFLOCATION url="/portal/main.cfm">--->

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>
<cfset mode = "PP">



<cfquery datasource="#application.reg_dsn#" name="patron">
	select patronID from patrons
     where patronlookup = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#cookie.login#">
</cfquery>

<cfquery datasource="#application.reg_dsn#" name="getCards">
	select * from patrontokens
     where patronid = <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#patron.patronid#">
     and invaliddt IS NULL
</cfquery>


</CFSILENT>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Manage Payment Options - Add New Payment Method</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
     <SCRIPT>
	function valid() {
		if (document.token.pin.value.length == 4 && document.token.confirmpin.value.length == 4 && document.token.pin.value == document.token.confirmpin.value) {
			return true;
		}
		else {
			alert("PIN numbers must be four digits and match each other.");
			return false;
		}
	}
	</script>
</head>
<cfoutput>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">

<table border="0" cellpadding="0" cellspacing="0" width="750">
  
  <!--- <cfinclude template="#request.includes#/top_nav.cfm"> --->
	<tr>
		<td valign=top>
   			<table border=0 cellpadding=2 cellspacing=0 width=749>
					<tr>
						<td colspan=3 class="pghdr">
						<!--- start header --->
						<CFINCLUDE template="/portalINC/dsp_header.cfm">
						<!--- end header --->
						</td>
					</tr>
				<tr>
					<td valign=top>
						<table border=0 cellpadding=2 cellspacing=0>
							<tr>
								<td><img src="/siteimages/spacer.gif" width="130" height="1" border="0" alt=""></td>
							</tr>
							<tr>
								<td valign=top nowrap class="lgnusr"><br>
								<!--- start nav --->
								<cfinclude template="/portalINC/admin_nav_history.cfm">
								<!--- end nav --->
								</td>
							</tr>		
						</table>		
					</td>
					<td valign=top colspan=2 class="bodytext" align=left>
					<!--- START HISTORY CONTENT --->
					<span class="pghdr"><br>Add New Payment Method</span><br>
	
     
     <p><b>Credit Cards</b><br>
THPRD accepts MasterCard, Visa and Discover.</p>

<CFIF Isdefined("form.formaction") and form.formaction EQ "addToken">

<!--- get token and generate link --->
<CFINCLUDE template="../freedompay/fetchToken.cfm">
<!--- refurns requestID and URL in data struct --->

<CFIF NOT Isdefined("data.TransactionId") OR len(form.pin) NEQ 4 OR form.pin NEQ form.confirmpin>
	<CFABORT>
</CFIF>

<CFOUTPUT>

<table width="80%">
<tr>
<td><strong>Label</strong></td>
<td><strong>Name on Card</strong></td>
<td><strong>Four Digit PIN</strong></td>
<td><strong>Confirm PIN</strong></td>
</tr>
<tr>
<td valign="top">#form.cardlabel#</td>
<td valign="top">#form.cardname#</td>
<td valign="top">XXX#right(form.pin,1)#</td>
<td valign="top">XXX#right(form.confirmpin,1)#</td>
<tr><td colspan="2" align="center"><br></td></tr>
</table>


THPRD and our credit card processor offer the option to tokenize credit card information.
We create a secure encrypted link that you can use in place of your actual credit card.
Presently we only use tokens as an alternative to card-present tranactions involving a card read 
as well as in phone operator assisted transactions. 
<a href="https://www.nerdwallet.com/blog/credit-cards/credit-card-tokenization-explained/" target="_blank">Click here</a> for more information about credit card tokens<br><br>
<form action="#data.checkoutURL#" method="get" target="_blank">
<input type="hidden" name="transid" value="#data.TransactionId#" />
<input type="submit" value="Launch Credit Card Window" />
</form>

<!---  build form that will get submitted --->



<form action="#cgi.script_name#" method="post" name="finalizetoken">
<input type="hidden" name="formaction" value="confirmToken">
<input type="hidden" name="cardlabel" value="#form.cardlabel#">
<input type="hidden" name="cardname" value="#form.cardname#">
<input type="hidden" name="transid" value="#data.TransactionId#">
<input type="hidden" name="pin" value="#form.pin#">
<CFIF Isdefined("form.preferred")>
<input type="hidden" name="preferred" value="#form.preferred#">
</CFIF>
<!---
<input type="submit" value="Continue" />
--->
</form>
</CFOUTPUT>

<CFELSEIF Isdefined("form.formaction") AND form.formaction EQ "confirmToken">
<CFINCLUDE template="../freedompay/getTransaction.cfm">
<!--- refurns token information in data struct --->

<!---<CFDUMP var="#data#">--->


<CFSET token = data.TokenInformation.Token>
<CFSET cardnumber = data.MaskedCardNumber>
<CFSET tokenexpires = left(data.TokenInformation.TokenExpiration,10)>
<CFSET themonth = numberformat(data.TokenInformation.CardExpirationMonth,"09")>
<CFSET theyear = left(data.TokenInformation.CardExpirationYear,2)>


<cfquery datasource="#application.reg_dsn#" name="getCards">
	insert into patrontokens
     (patronid,valid,token,tokenexpiredt,cardnumber,cardexpirationdate,cardname,cardreference,pin,preferred)
     VALUES
     (
     <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#patron.patronid#">,
     true,
     <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#token#">,
     <CFQUERYPARAM cfsqltype="cf_sql_date" value="#tokenexpires#">,
     <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#cardnumber#">,
     <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#themonth##theyear#">,
     <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.cardname#">,
     <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.cardlabel#">,
     <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#hash(form.pin,'MD5')#">
     <CFIF Isdefined("form.preferred") and form.preferred EQ "true">
     ,true
     <CFELSE>
     ,false
     </CFIF>
     )
</cfquery>

<br>Token successfully added.<br>
<CFLOCATION url="cardoptions.cfm?success=true">

<CFELSE>
<CFOUTPUT>
<form name="token" action="#cgi.script_name#" method="post" onSubmit="return valid();">
<input type="hidden" name="formaction" value="addToken">
<table>
<tr>
<td><strong>Label</strong></td>
<td><strong>Name on Card</strong></td>
<td><strong>Four Digit PIN</strong></td>
<td><strong>Confirm PIN</strong></td>
<!---<td>Expiration Date</td>--->
</tr>
<tr>
<td valign="top"><input type="text" name="cardlabel"></td>
<td valign="top"><input type="text" name="cardname"></td>
<td valign="top"><input type="password" name="pin" maxlength="4" size="6"></td>
<td valign="top"><input type="password" name="confirmpin" maxlength="4" size="6"></td>
<td valign="top"><input type="submit" value="Next"></td>
<!---<td valign="top"><select name="month"><CFLOOP from="01" to="12" index="i"><option value="#numberformat(i,"09")#">#numberformat(i,"09")#</option></CFLOOP></select>
&nbsp;<select name="year"><CFLOOP from="#year(now())#" to="#year(now())+10#" index="y"><option value="#y#">#i#</option></CFLOOP></select>
</td>--->
</tr>
<tr>
<td><span style="font-size:9px">Simple description e.g. 'Chase Visa'</span></td>
</tr>
<!---
<tr>
<td colspan="2"><input type="checkbox"> Use this card for all THPRD web transactions.</td>
</tr>
--->
<tr><td colspan="2" align="center"><br></td></tr>
</table>

<strong>About PINs</strong><br>
<p>The four digit PIN allows patrons to use a token for drop-in and phone transactions. Please remember your PIN.
Once created THPRD staff cannot reset or change the PIN. If forgotten the token will have to be deleted and recreated with a new PIN.</p>
</form>
</CFOUTPUT>
</CFIF>


	<table width="675" cellpadding=3 cellspacing="0" border=0>
		
	</table>
					<!--- END HISTORY CONTENT --->
					</td>
				</tr>
			</table>
		</td>
    </tr>
	<tr>
		<td colspan="3"><img src="#request.imagedir#/spacer.gif" width="1" height="11" border="0" alt=""></td>
	</tr>
<cfinclude template="/portalINC/footer.cfm">
</table>
</body>
</html>
</cfoutput>


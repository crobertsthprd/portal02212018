<!--- opened back up nov 23 <CFABORT> --->


<!---

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>



<CFIF Isdefined("url.clearcart") and Isdefined("session.myCart")>
	<CFSET temp = arrayClear(session.myCart)>
</CFIF>

<cfset module = "WWW">
<cfset localfac = "WWW">
<cfset localnode = "W1">




<!--- remove reload item --->
<CFIF Isdefined("url.removeid") and arraylen(session.myCart) GTE url.removeid>
	<CFSET temp = ArrayDeleteAt(session.myCart, url.removeid)>
</CFIF>


<!--- routine to update reload item in shopping cart --->
<CFIF Isdefined("form.reloadamount")>
	<cfset reloaderrormsg = "">
	<CFSCRIPT>
		if (not Isdefined("session.myCart") ) {
			session.myCart = arrayNew(1);
		}
	</CFSCRIPT>
	<!--- Get Balance --->
	<cfset ocNum = replace(form.reloadcardnumber," ","","all")>
	<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
	<cfset thereloadamount = rereplace(form.reloadamount,"[^1234567890.]","","ALL")>
	<cf_cryp type="en" string="#ocNum#" key="#skey#">
	<cfset enOtherCreditData = cryp.value>
	<cfquery datasource="#application.reg_dsn#" name="GetOtherCreditBalance">
		SELECT   othercreditdata.valid, othercredithistorysums.sumcredit - sumdebit AS bal,othercreditdata.activated,
				 othercredithistorysums.isfa
		FROM     othercredithistorysums othercredithistorysums
				 INNER JOIN othercredittypes othercredittypes ON othercredithistorysums.othercredittype=othercredittypes.othercredittype 
				 INNER JOIN othercreditdata on othercreditdata.cardid=othercredithistorysums.cardid
		WHERE    othercreditdata.othercreditdata = '#enOtherCreditData#'
	</cfquery>	
	<!--- make sure amount is numeric --->
	<CFIF trim(thereloadamount) EQ "">
		<cfset errormsg = "Reload amount was not numeric.">
	</CFIF>
	<!--- Check resulting new amount --->
	<CFIF (GetOtherCreditBalance.bal + thereloadamount GT 500) and trim(reloadamount) NEQ "">
		<cfset errormsg = "Reload will cause card maximum to be exceeded.">
	</CFIF>
	<!--- make sure no duplicate --->

	<CFLOOP from="1" to="#arraylen(session.myCart)#" index="i">
		<CFIF session.myCart[i].reloadcardnumber EQ trim(ocNum)>
			<cfset reloaderrormsg = "Specified card already has a pending reload in the shopping cart. Only one reload per card per shopping cart.">
		</CFIF>
	</CFLOOP>
	
	<!--- add to cart if no error --->
	<CFIF reloaderrormsg EQ "">
		<CFSCRIPT>
			thisrow = arraylen(session.myCart) + 1;
			session.myCart[thisrow] = structNew();	
			session.myCart[thisrow].transactiontype = "reload";
			session.myCart[thisrow].newpurchase = 0;
			session.myCart[thisrow].reloadcardnumber = trim(ocNum);	
			session.myCart[thisrow].reloadamount = trim(form.reloadamount);	
		</CFSCRIPT>
	</CFIF>
</CFIF>

<!--- calculate amount owed --->
<CFSET amountDue = 0>
<CFIF Isdefined("session.myCart") AND arraylen(session.myCart) GT 0>
<CFLOOP from="1" to="#arraylen(session.myCart)#" index="i">
	<CFSET amountDue = amountDue + session.myCart[i].reloadamount>
</CFLOOP>
</CFIF>

<!--- query to register a card; must be activated and valid number --->
<CFIF Isdefined("form.cardnumber2reg")>
	<cfset ocNum = replace(form.cardnumber2reg," ","","all")>
	<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
	<cf_cryp type="en" string="#ocNum#" key="#skey#">
	<cfset enOtherCreditData = cryp.value>
	<cfquery datasource="#application.reg_dsn#" name="GetOtherCreditBalance">
		SELECT   othercreditdata.valid, othercredithistorysums.sumcredit - sumdebit AS bal,othercreditdata.activated
		FROM     othercredithistorysums othercredithistorysums
				 INNER JOIN othercredittypes othercredittypes ON othercredithistorysums.othercredittype=othercredittypes.othercredittype 
				 INNER JOIN othercreditdata on othercreditdata.cardid=othercredithistorysums.cardid
		WHERE    othercreditdata.othercreditdata = '#enOtherCreditData#'
	</cfquery>
	<cfquery datasource="#application.reg_dsn#" name="CheckForCardInStock">
		select pk
		from   othercreditdatastock
		where  othercreditdata = '#enOtherCreditData#'
	</cfquery>
	<cfquery datasource="#application.reg_dsn#" name="CheckCardStatus">
		select cardid, valid, primarypatronid,activated
		from   othercreditdata
		where  othercreditdata = '#enOtherCreditData#'
	</cfquery>
	<cfset errormsg = "">
	<cfif GetOtherCreditBalance.recordcount is 0>
		<cfset errormsg = "Specified card was not found.">
	<cfelseif CheckForCardInStock.recordcount is 0>
		<cfset errormsg = "Specified card was not found.">
	<cfelseif CheckCardStatus.activated is 0>
		<cfset errormsg = "Specified card was found but has not been activated.">
	<cfelseif CheckCardStatus.valid is 0>
		<cfset errormsg = "Specified card was found but is listed as invalid.">
	<cfelseif CheckCardStatus.primarypatronid is not '' AND CheckCardStatus.primarypatronid is not cookie.uid>
		<cfset errormsg = "Specified card is registered to another household.">
	<cfelseif CheckCardStatus.primarypatronid is not '' AND CheckCardStatus.primarypatronid is  cookie.uid>
		<cfset errormsg = "Specified card is already registered to this household.">
	</cfif>
	<CFIF errormsg EQ "">
		<cfquery datasource="#application.dopsds#" name="UpdateCard">
			update othercreditdata
			set primarypatronid = #cookie.uid#
			where cardid = #CheckCardStatus.cardid#
		</cfquery>
		<cfquery datasource="#application.dopsds#" name="InsertNewCardActivationHistory">
			insert into othercreditdatahistory
				(cardid, invoicefacid, action, userid, module)
			values
				(#CheckCardStatus.cardid#, '#LocalFac#', 'S', 0, '#module#')
		</cfquery>
		<cfset confirmed = "Card has been registered for current household">	
	</CFIF>
</CFIF>

<!--- query to get registered cards --->
<cfquery datasource="#application.dopsds#" name="getCards">
	<!--- select d.*, s.sumnet, s.isfa
	from othercreditdata d, othercredithistorysums s
	where d.primarypatronid = #cookie.uid#
	and d.activated is true
	and d.valid is true
	and s.cardid = d.cardid
	order by d.cardid --->


	SELECT   s.sumnet, s.isfa, s.cardid, s.othercreditdata 
	FROM     othercredithistorysums s
	WHERE    s.primarypatronid = #cookie.uid#
	ORDER BY s.cardid
</cfquery>

--->

<!--- there should be no more than one record per card since there is only one registration --->
		




<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Giftcards</title>
	<SCRIPT language="javascript" src="/portal/js/autotab.js"></SCRIPT>
	<SCRIPT language="javascript">
		function register() {
			if (document.gift.cardnumber2reg.value.length != 16) {
 				alert('Cardnumbers have 16 digits without any spaces. Please enter the card number in its correct format.');
				document.gift.cardnumber2reg.focus();
				return false;
 			}
			else {
				document.gift.submit();
			}
		}
	</SCRIPT>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
<style> 
#liner{
	padding: 2px 2px 2px 2px;
	background-color:#ffffff;
	border-top-color:#999999;
	border-top-style:solid;
	border-top-width:1px;
}
</style>

<script language="javascript">
function checkAmount() {
	if (document.gift.reloadamount.value < 5) {
		alert("Minimum value for a gift card reload is $5.00");
		document.gift.reloadamount.focus();
		return false;
	}
	else if (document.gift.reloadamount.value > 500) {
		alert("Maximum value for a gift card reload is $500.00");
		document.gift.reloadamount.focus();
		return false;
	}
	else {
		//alert("Amount okay");
		return true;
	}
}	
</script>
	
</head>

<body leftmargin="0" topmargin="0">


<cfset localfac = "WWW">
<cfset localnode = "W1">
<cfset DS = "thirst">

<!--- <cfif not IsDefined("PrimaryPatronID")>
	<strong>No patron ID specified.</strong>
	<cfabort>
</cfif> --->

<cfoutput>






<table border="0" cellpadding="0" cellspacing="0" width="750">
  <tr>
   <td valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
			<tr>
				<td colspan=2 class="pghdr">
				<!--- start header --->
				<CFINCLUDE template="/portalINC/dsp_header.cfm">
				<!--- end header --->
				</td>
			</tr>
			<tr>
				<td valign=top>
					<table border=0 cellpadding=2 cellspacing=0>
						<tr>
							<td><img src="images/spacer.gif" width="130" height="1" border="0" alt=""></td>
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
				<td valign=top class="bodytext" width="100%">
				<!--- start content --->
				<br><span class="pghdr">Registered Gift Cards</span><br>
				This page is currently unavailable. To reload a gift card please call one of the district's recreation or aquatic centers.<br> >> <a target="_blank" href="http://www.thprd.org/contact/directory.cfm">District Directory</a>
				<!---
				<table border="0" cellpadding="3" cellspacing="0" width="100%">
					<tr bgcolor="dddddd" >
						<td><strong>Card Number</strong></td>
						<td><strong>Date Registered</strong></td>
						<td><strong>Balance</strong></td>
						<td align="center"><strong>Actions</strong></td>
					</tr>
					<CFLOOP query="getcards">
					<cfquery datasource="#application.dopsds#" name="getAct">
						select h.dt from othercreditdatahistory h
						where h.cardid = #getcards.cardid#
						and h.action = 'S'
						order by h.dt desc
						limit 1
					</cfquery>
					<cf_cryp type="de" string="#getcards.othercreditdata#" key="#skey#">
					<CFSET allowreloadflag = 1>
					<!---<CFSET temp = arrayclear(session.myCart)>length: #arraylen(session.myCart)#<CFABORT>--->
					<CFIF Isdefined("session.myCart") and arraylen(session.myCart) GT 0>
						<CFLOOP from="1" to="#arraylen(session.myCart)#" index="i">
							<CFIF session.myCart[i].reloadcardnumber EQ cryp.value>
								<CFSET allowreloadflag = 0>
							</CFIF>
						</CFLOOP>
					</CFIF>
					<tr >
						<td>#left(cryp.value,4)# #insert(" ",mid(cryp.value,5,8),4)# #right(cryp.value,4)#</td>
						<td>#dateformat(getAct.dt,"mmmm dd, yyyy")#</td>
						<td>$#numberformat(sumnet,"____.__")#</td>
						<td align="center"><CFIF allowreloadflag EQ 1 AND getcards.isfa EQ 0><a href="giftcards.cfm?reloadcardnumber=#cryp.value#">Reload</a> | </CFIF><a href="giftcards.cfm?historycardnumber=#cryp.value#">View History</a></td>
					</tr>
					</CFLOOP>
				</table>
				
				<CFIF Isdefined("url.reloadcardnumber") OR (Isdefined("session.myCart") AND arraylen(session.myCart) GT 0) >
				<br><span class="pghdr">Reload Gift Card</span><br>
				<CFIF Isdefined("reloaderrormsg") AND trim(reloaderrormsg) NEQ ''>
					<font color="red"><b>#reloaderrormsg#</b></font><br>
				</CFIF>
				<table width="70%" border="0" cellpadding="3" cellspacing="0" >
					<tr bgcolor="dddddd">
						<td><strong>Card Number</strong></td>
						<td><strong>Reload Amount</strong></td>
						<td><strong>&nbsp;</strong></td>
					</tr>

				<CFIF Isdefined("session.myCart") AND arraylen(session.myCart) GT 0>
				<CFLOOP from="1" to="#arraylen(session.myCart)#" index="i">
					<tr>
						<td>#left(session.myCart[i].reloadcardnumber,4)# #insert(" ",mid(session.myCart[i].reloadcardnumber,5,8),4)# #right(session.myCart[i].reloadcardnumber,4)#</td>
						<td>$#numberformat(session.myCart[i].reloadamount,"____.__")#</td>
						<td><a href="giftcards.cfm?removeid=#i#">Remove</a></td>
					</tr>
				</CFLOOP>
				</CFIF>
				<CFIF Isdefined("url.reloadcardnumber")>
					<!--- make sure not fa --->
					<cfset ocNum = replace(url.reloadcardnumber," ","","all")>
					<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
					<cf_cryp type="en" string="#ocNum#" key="#skey#">
					<cfset enOtherCreditData = cryp.value>
					<CFQUERY name="checkfa" dbtype="query">
						select isfa from getcards
						where othercreditdata = '#enOtherCreditData#'
					</CFQUERY>
					
					<!--- look up balance --->
					<CFIF checkfa.recordcount EQ 0>
					<tr><td colspan="3">
					<font color="red"><strong>There was a problem accessing this card number.</strong></font>
					</td></tr>
					<CFELSEIF checkfa.isfa EQ 1>
					<tr><td colspan="3">
					<font color="red"><strong>Family assistance cards cannot be reloaded.</strong></font>
					</td></tr>
					<CFELSE>
					<form action="#cgi.script_name#" method="post" name="reload" onSubmit="return checkAmount();">
						<tr>
							<td>#left(url.reloadcardnumber,4)# #insert(" ",mid(url.reloadcardnumber,5,8),4)# #right(url.reloadcardnumber,4)#<input type="hidden" name="reloadcardnumber" value="#url.reloadcardnumber#"></td>
							<td>$<input type="text" size="8" name="reloadamount" class="form_input">&nbsp;</td>
							<td><input type="submit" value="Add To Cart" class="form_input"></td>
						</tr>	
					</form>	
					</CFIF>	
				</CFIF>
					<tr>
						<td colspan="3" align="center" id="liner">&nbsp;</td>
					</tr>
				
				</table>
				
<!--- start checkout --->				
				<CFIF amountDue GT 0>
				<cfset lastmonth = dateadd('m','-1',now())>
				<!--- look up credit; etc --->
				<CFSET netBalance = GetAccountBalance(cookie.uID)>
				<cfset creditUsed = min(netBalance,amountDue)>
				<cfset NetToPay = max(0,amountDue - NetBalance)>
				<table border="0" cellspacing="1" cellpadding="2">
				<form action="finishgcreload.cfm" method="post" name="reload" onSubmit="return checkAmount();">
					<TR>
					<td class="bodytext" colspan="2" valign=top nowrap bgcolor="FFFFCC"><cfset lastmonth = dateadd('m','-1',now())>
					<cfif nettopay gt 0><!--- only show cc fields if there is a non-credit balance --->
					<strong>Please enter payment information:</strong><br>
						<select name="ccType" class="form_input">
							<option value="V">Visa</option>
							<option value="MC">MasterCard</option>
							<option value="DISC">Discover</option>
						</select>
						<input name="ccNum1" size="4" type="Text" maxlength="4" class="form_input" onKeyDown="autotab(this,'down',4)" onKeyUp="autotab(this,'up',4,this.form.ccNum2)">-<input name="ccNum2" size="4" type="Text" maxlength="4" class="form_input" onKeyDown="autotab(this,'down',4)" onKeyUp="autotab(this,'up',4,this.form.ccNum3)">-<input name="ccNum3" size="4" type="Text" maxlength="4" class="form_input" onKeyUp="autotab(this,'up',4,this.form.ccNum4)">-<input name="ccNum4" size="4" type="Text" maxlength="4" class="form_input"><br>
						<select name="ccExpMonth" class="form_input">
							<cfloop from="1" to="12" step="1" index="q">
								<option value="#numberformat(q,"00")#" <cfif month(lastmonth) is q>selected</cfif>>#numberformat(q,"00")#
							</cfloop>
						</select>
						<select name="ccExpYear" class="form_input">
							<option value="#year(dateadd('yyyy','-1',now()))#">#year(dateadd('yyyy','-1',now()))#</option>
							<cfloop from="0" to="9" step="1" index="q"><!--- allow 10 years ahead --->
								<option value="#year(now()) + q#">#year(now()) + q#
							</cfloop>
						</select>
						<br><a href="javascript:void(0);" onClick="window.open('../classes/ccv.cfm','ccv','width=340, height=400, toolbar=no, scrollbars=yes, noresize');">CCV Number</a> (back of credit card)&nbsp;&nbsp;&nbsp;<input name="ccv" size="3" type="Text" maxlength="3" class="form_input">
					<cfelse><!--- patron had more credit than amount due, just pass fields to satisfy processing --->
					You have a $0.00 balance - no credit card needed.
						<input type="hidden" name="cctype" value="">
						<input type="hidden" name="ccnum1" value="">
						<input type="hidden" name="ccnum2" value="">
						<input type="hidden" name="ccnum3" value="">
						<input type="hidden" name="ccnum4" value="">
						<input type="hidden" name="ccExpMonth" value="">
						<input type="hidden" name="ccExpYear" value="">
						<input type="hidden" name="ccv" value="">
					</cfif>
					</TD>
					<td bgcolor="FFFFCC">&nbsp;</td>
					<td class="bodytext" align="right" colspan=2 valign=top nowrap bgcolor="FFFFCC">Account Starting Balance<br>
					 Total Fees<br>
					 Credit Used<br>
					 Amount Due<br>
					 <strong>Account Ending Balance</strong><br>
					</TD>
					<td bgcolor="FFFFCC">&nbsp;</td>
					<td class="bodytext" align="right" valign=top bgcolor="FFFFCC">#numberformat(NetBalance,"999,999.99")# <br>
					#numberformat(amountDue,"999,999.99")# <br>
					#numberformat(CreditUsed,"999,999.99")# <br>
					<span class="bodytext_red">#numberformat(NetToPay,"999,999.99")#</span> <br>
					<span class="bodytex"><strong>#numberformat(NetBalance - CreditUsed,"999,999.99")#</strong></span>
					</TD>
					<input type="hidden" name="netbalance" value="#netbalance#">
					<input type="hidden" name="primarypatronid" value="#cookie.uID#">
					<input type="hidden" name="creditused" value="#creditused#">
					<input type="hidden" name="amountDue" value="#amountdue#">
					</TR>
					<tr>
						<td colspan=7 align="right"><input type="button" class="form_input" value="Clear Selections" onClick="location.href='#cgi.script_name#?clearcart=true';"> <input type="submit" class="form_input" value="Complete Purchase"></td>
						<td>&nbsp;</td>
					</tr>
					<CFIF Isdefined("url.error") AND trim(url.error) NEQ ''>
					<tr><td colspan="8">
					<font color="red"><b>#url.error#</b></font><br>
					</td></tr>
					</CFIF>			
				</table>
				</form>
				</CFIF>
<!--- end checkout --->			
			</CFIF>
				

<CFIF NOT Isdefined("url.historycardnumber")>
	<br><span class="pghdr">Register a Gift Card</span><br>
				All patrons with a valid THPRD Residency Card are able to register their gift cards online through their portal page. While registering your Gift Card is not required, we strongly recommend that you register your card as soon as you receive it. A registered Gift Card will allow only your household members to use the funds available, enable you to track your usage, and check or reload your balance at any time. Also, if a registered Gift Card is lost or stolen, the registered cardholder can contact us and we will immediately freeze the remaining balance of the card and issue a replacement card for the balance shown on our records. (A $5.00 replacement card fee will be deducted from your balance).
<br><br>
If your card is not registered, you must treat your card like cash. The bearer is responsible for its loss or theft. THPRD is not responsible for any unauthorized card use, nor can we replace it if lost or stolen.<br><br>
				<CFIF Isdefined("confirmed")>
					<font color="green"><b>Card #form.cardnumber2reg# has been registered to this household.</b></font><br>
				</CFIF>
				<CFIF Isdefined("errormsg") AND trim(errormsg) NEQ ''>
					<font color="red"><b>#errormsg#</b></font><br>
				</CFIF>
				
				<table >
					<tr>
						<form action="#cgi.script_name#" method="post" name="gift">
						<td class="bodytext" valign="middle">Gift Card Number:</td>
						<td valign="middle"><input class="form_input" type="text" name="cardnumber2reg" maxlength="16" size="22">&nbsp;<input type="button" value="Register Card" onClick="register();" class="form_input"></td>
						</form>
					</tr>
					<tr>
						<td><CFIF Isdefined("session.mycart")><a href="giftcards.cfm?clearcart=true">Clear session cart</a></CFIF></td>
					</tr>
				</table>
				
<CFELSEIF Isdefined("url.historycardnumber")>
	<CFINCLUDE template="giftcards_viewhistory.cfm">
</CFIF>

<p>If you would like to purchase a new gift card please visit our <a href="/store/giftcard_home.cfm" target="_blank">online store</a>.</p>
					--->
				<!--- end content --->
				</td>
			</tr>
		</table>   
   </td>
  </tr>
  <tr>
   <td colspan="2" valign="top">&nbsp;</td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">

</table>
</body>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</html>
</cfoutput>







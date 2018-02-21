<CFSETTING showdebugoutput="true">
<!--- this page gets run as an include from ccinfo is giftcard is selected --->

<cfif NOT structkeyexists(cookie,"uID")>
     <cflocation url="../index.cfm?msg=3&page=checkoutgiftcard">
     <cfabort>
</cfif>

<cfset tc = "">
<cfset primarypatronid = cookie.uID>
<CFPARAM name="form.unreg_gc1" default="">
<CFPARAM name="form.unreg_gc2" default="">
<CFPARAM name="form.unreg_gc3" default="">
<CFPARAM name="form.unreg_gc4" default="">
<CFPARAM name="form.maxgcamount" default="">
<CFPARAM name="selectcardmessageerror" default="">
<CFPARAM name="famsg" default="">
<CFPARAM name="form.gctype" default="">
<cfset moneywidth=70>

<cfinclude template="functionscommon.cfm">

<!--- load FA balances, if any --->
<cfquery datasource="#application.dopsdsro#" name="LoadFABalance">
	SELECT   dops.loadfabalance(<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">)
</cfquery>

<CFINCLUDE template="passesinbasket_nodisplay.cfm">
<CFSET variables.netdue = variables.runningsum>
<cfset totalfees = variables.runningsum>
<cfset useextensivemode = 0>
<cfset disableenterkey = "">
<cfset hidecreditcardpaymentfields = 0>
<cfset useextensivemode = 1>

<!--- money needs to be calculated based sum of all fees for transaction --->
	<cfif not IsDefined("getOCCards")>
     

     
<cfquery datasource="#application.dopsds#" name="getOCCards">
		SELECT   othercreditdata,
		         othercredittype,
		         cardname,
                   cardid,
		         dops.getavailableocfunds(
		         	othercredithistorysums.cardid,
		         	othercredithistorysums.primarypatronid,
		         	<cfqueryparam value="99999999" cfsqltype="cf_sql_numeric">,
		         	<cfqueryparam value="99999999" cfsqltype="cf_sql_numeric">,
		         	<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no"> ) as sumnet
		FROM     dops.othercredithistorysums
		where    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		and      valid
		and      activated
		and      ( faappstatus = <cfqueryparam value="G" cfsqltype="cf_sql_varchar" list="no"> or faappstatus is null )
		and      not holdforreview
		and      othercreditdata is not null

		<cfif not GetHousehold.indistrict[1]>
			and      not isfa
		</cfif>

	</cfquery>

	<!--- remove 0 bal cards --->
	<cfquery dbtype="query" name="getOCCards">
		select  *
		from    getOCCards
		where   sumnet > 0
	</cfquery>
     


</cfif>

<CFIF Isdefined("pickgiftcard")>
     <cfparam name="TenderedOC" default="0.00">
     <CFSET variables.thecardnumber = trim(form.unreg_gc1) & trim(form.unreg_gc2) & trim(form.unreg_gc3) & trim(form.unreg_gc4)>
	<!--- do the look up; get balance and create display info --->
     <CFIF Isnumeric(variables.thecardnumber) and len(variables.thecardnumber) EQ 16>
               
               <cfset ocNum = REReplace( variables.thecardnumber, "[^0-9]", "", "all" )>
	<cf_cryp type="en" string="#variables.ocNum#" key="#variables.key#">
	<cfset enOtherCreditData = cryp.value>

	<!--- lookup card by id - improves speed --->
	<cfquery datasource="#application.dopsds#" name="getCardID">
		SELECT   cardid
		FROM     dops.othercredithistorysums
		where    othercreditdata = <cfqueryparam value="#variables.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>

	<cfquery datasource="#application.dopsds#" name="getCardData">
		SELECT   othercreditdesc,
		         cardid,
		         cardname,
		         othercredittype,
		         isfa,
		         faapptype,
		         valid,
		         activated,
		         holdforreview,
		         dops.getavailableocfunds(
		         	othercredithistorysums.cardid,
		         	othercredithistorysums.primarypatronid,
		         	<cfqueryparam value="#DollarRound( variables.TotalFees )#" cfsqltype="cf_sql_numeric">,
		         	<cfqueryparam value="#DollarRound( variables.NetDue )#" cfsqltype="cf_sql_numeric">,
		         	<cfqueryparam value="#variables.useextensivemode#" cfsqltype="cf_sql_bit" list="no">
		         	<cfif IsDefined("variables.otherfacreditlimit")>
		         		, <cfqueryparam value="#max( 0, variables.otherfacreditlimit )#" cfsqltype="cf_sql_numeric" list="no">
		         	</cfif> ) as sumnet
		FROM     dops.othercredithistorysums
		where    cardid = <cfqueryparam value="#getCardID.cardid#" cfsqltype="cf_sql_integer">

		<cfif not GetHousehold.indistrict[1]>
			and      not isfa
		</cfif>

	</cfquery>
		<!--- <cfdump var="#form#"> --->
		<cfif getCardData.recordcount eq 1>
			<cfset TenderedOC = min( getCardData.sumnet, TenderedOC )>
			<input type="hidden" name="occardid" value="#getCardData.cardid#">
		<cfelse>
			<cfset TenderedOC = 0>
			<cfset OCCardNumber = "">
		</cfif>


               
			
    	<CFIF getCardData.recordcount EQ 0>
			<CFSET selectcardmessageerror = "Selected card does not exist, is no longer valid, or may have a balance of zero. Please use a different card. The number you entered was: #thecardnumber#.">
		<CFELSEIF getCardData.recordcount EQ 1 and form.MaxGCAmount GT getCardData.sumnet and getCardData.othercredittype neq 'V'>
			<CFSET selectcardmessageerror = "Allocated amount exceeds available funds. Card allocation for this transaction is #dollarformat(getCarddata.sumnet)#. Balances for registered gift cards (including amount available per household member) can found by clicking Gift Cards in the left-hand navigation menu.">
		<CFELSEIF getCardData.recordcount EQ 1>
			<CFIF form.gctype EQ 'unregisteredfetch'>
        		<CFSET gcpayment = min(form.netdue,getCardData.sumnet)>
            	<CFSET MaxGCAmount = gcpayment>
			<CFELSE>
            	<CFSET gcpayment = min(min(form.netdue, MaxGCAmount), getCardData.sumnet)>
        	</CFIF>
			<cfoutput>gcpayment: #gcpayment#</cfoutput>
		
               <!--- set details --->
        	<CFSET theselectedcard = thecardnumber>
        	<CFSET theselectedcardbalance = getCardData.sumnet>
        	<CFSET theselectedcardFA = getCardData.isfa>
        	<cfset TrueBalance = getCardData.sumnet>
        	<cfif IsNumeric(MaxGCAmount) and MaxGCAmount GT 0>
        		<cfset QuerySetCell(getCardData, "sumnet", min(MaxGCAmount, getCardData.sumnet))>
        	<CFELSE>
            	<CFSET selectcardmessageerror = "Please enter a valid gift card amount greater than zero.">
            	<CFSET theselectedcard = 0>
            	<CFSET gcpayment = 0>
        	</cfif>
		<CFELSE>
        	<CFSET selectcardmessageerror = "There was a error looking up your card. Please contact Administration. The number you entered was: #thecardnumber#.">
    	</CFIF>
	<CFELSE>
		<CFSET selectcardmessageerror = "Card number should contain 16 digits. The card number you entered is not in the correct format. The number you entered was: #thecardnumber#.">
    </CFIF>
</CFIF>
	<cfset localfac = "WWW">
	<cfset localnode = "W1">
	<cfset DS = "#application.reg_dsn#">
	<cfset pid = cookie.uID>
	<cfset GLLineNo = 0>
	<cfset ShowCurrentReg = 0>
	<!--- set to 0 to suppress showing current regs --->

	<!--- toggle vars to show msg do ease in formatting --->
	<cfset ShowInSession = 0>
	<cfset ShowDeleteConfirm = 0>
	<cfset ShowCancelled = 0>
	<cfset ShowAlreadyEnrolled = 0>
	<cfset ShowNoAssmt = 0>
	<cfset ShowWaitList = 0>
	<cfset ShowError = 0>
	<cfset ShowNonExistanceError = 0>
	<cfset ShowNoRecords = 0>
	<cfset ShowNoClasses = 0>
	<cfset ShowNoActions = 0>
	<cfset ShowNotAvail = 0>
	<!--- end --->

	<!--- what is this? - cr --->
	<cfif IsDefined("cont1")>
     <!--- call class selection loading page --->
     <cflocation url="index.cfm">
     <cfabort>
</cfif>
	<CFINCLUDE template="/portalINC/familyassistance_functions.cfm">
	<cfquery datasource="#application.dopsdsro#" name="GetPrimary">
	SELECT   patrons.lastname, patrons.firstname, patrons.middlename, patronRelations.verifyexpiration,
	         patrons.DOB, PatronAddresses.address1,
	         PatronAddresses.address2, PatronAddresses.city, patrons.patronid, patrons.insufficientid,
	         PatronAddresses.state, PatronAddresses.zip, PatronRelations.RelationType,
	         PatronRelations.InDistrict, patrons.patronlookup, patrons.verified, patrons.inactive, patrons.gender, patrons.admcomments
	FROM     PatronRelations PatronRelations
	         INNER JOIN patrons patrons ON PatronRelations.PrimaryPatronid=patrons.PatronID
	         LEFT OUTER JOIN PatronAddresses PatronAddresses ON PatronRelations.AddressID=PatronAddresses.AddressID
	where    patronRelations.PrimaryPatronid = <cfqueryparam value="#pid#" cfsqltype="cf_sql_integer" list="no">
	and      patronRelations.SecondaryPatronid = <cfqueryparam value="#pid#" cfsqltype="cf_sql_integer" list="no">
	and      not patrons.inactive
</cfquery>
	<cfset InDistrictStatus = 1>
	<cfif GetPrimary.insufficientid is 1 or GetPrimary.InDistrict is 0>
     <cfset InDistrictStatus = 0>
</cfif>
<CFSILENT></cfsilent>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta http-equiv='cache-control' content='no-cache'>
<meta http-equiv='expires' content='0'>
<meta http-equiv='pragma' content='no-cache'>
<title>Tualatin Hills Park & Recreation District</title>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
<link type='text/css' href='/portal/jquery/css/demo.css' rel='stylesheet' media='screen' />
<link type='text/css' href='/portal/jquery/css/basic.css' rel='stylesheet' media='screen' />
<script language="javascript">
function updateGCamount() {
document.updatecard.unreg_gc1.value = document.class_sum.unreg_gc1.value;
document.updatecard.unreg_gc2.value = document.class_sum.unreg_gc2.value;
document.updatecard.unreg_gc3.value = document.class_sum.unreg_gc3.value;
document.updatecard.unreg_gc4.value = document.class_sum.unreg_gc4.value;
//document.updatecard.gctype.value = 'unregistered';
document.updatecard.TotalFees.value = document.class_sum.TotalFees.value;
document.updatecard.NetDue.value = document.class_sum.NetDue.value;
document.updatecard.MaxGCAmount.value = document.class_sum.newgcamount.value;
document.updatecard.submit();
}

function fetchUnRegGC() {

document.updatecard.unreg_gc1.value = document.class_sum.unreg_gc1.value;
document.updatecard.unreg_gc2.value = document.class_sum.unreg_gc2.value;
document.updatecard.unreg_gc3.value = document.class_sum.unreg_gc3.value;
document.updatecard.unreg_gc4.value = document.class_sum.unreg_gc4.value;
document.updatecard.gctype.value = 'unregisteredfetch';
document.updatecard.TotalFees.value = document.class_sum.TotalFees.value;
document.updatecard.NetDue.value = document.class_sum.NetDue.value;
document.updatecard.MaxGCAmount.value = 0;
document.updatecard.submit();
}


function updateUnRegGC() {

document.updatecard.unreg_gc1.value = document.class_sum.unreg_gc1.value;
document.updatecard.unreg_gc2.value = document.class_sum.unreg_gc2.value;
document.updatecard.unreg_gc3.value = document.class_sum.unreg_gc3.value;
document.updatecard.unreg_gc4.value = document.class_sum.unreg_gc4.value;
document.updatecard.gctype.value = 'unregistered';
document.updatecard.TotalFees.value = document.class_sum.TotalFees.value;
document.updatecard.netdue.value = document.class_sum.NetDue.value;
document.updatecard.MaxGCAmount.value = 0;
document.updatecard.submit();
}

function updateRegGC() {
//alert("calling updateRegGC!");
theccnum = document.class_sum.registeredcard.options[document.class_sum.registeredcard.options.selectedIndex].value;

if (theccnum != "None") {
c1 = theccnum.substring(0,4);
c2 = theccnum.substring(4,8);
c3 = theccnum.substring(8,12);
c4 = theccnum.substring(12,16);
document.updatecard.unreg_gc1.value = c1;
document.updatecard.unreg_gc2.value = c2;
document.updatecard.unreg_gc3.value = c3;
document.updatecard.unreg_gc4.value = c4;
//document.updatecard.gctype.value = 'registered';
document.updatecard.TotalFees.value = document.class_sum.TotalFees.value;
document.updatecard.NetDue.value = document.class_sum.NetDue.value;
document.updatecard.MaxGCAmount.value = theccnum.substring(16,26);
//document.updatecard.GCString.value = theccnum;
document.updatecard.submit();
}
else {
alert("No card has been selected.");
}
}
</script>
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
<cfoutput>
<table border="0" cellpadding="0" cellspacing="0" width="750">

<!--- <cfinclude template="#request.includes#/top_nav.cfm"> --->
<tr>
<td valign=top>
<table border=0 cellpadding=2 cellspacing=0 width=749>
<tr>
     <td colspan=3 class="pghdr"><!--- start header --->

          <CFINCLUDE template="/portalINC/dsp_header.cfm">

          <!--- end header ---></td>
</tr>
<tr>
<td valign=top><table border=0 cellpadding=2 cellspacing=0>
          <tr>
               <td><img src="/portal/images/spacer.gif" width="130" height="1" border="0" alt=""></td>
          </tr>
          <tr>
               <td valign=top nowrap class="lgnusr"><br>

                    <!--- start nav --->

                    <cfinclude template="/portalINC/admin_nav_classes.cfm">

                    <!--- end nav ---></td>
          </tr>
     </table></td>
<td valign=top colspan=2 class="bodytext" align=left>

<table>
<CFINCLUDE template="passesinbasket.cfm">
</table>
<cfset hiddenfieldsdebug = 0>
<cfset totalfees = variables.runningsum>
<cfset disableenterkey = "">
<cfset hidecreditcardpaymentfields = 0>
<cfset useextensivemode = 0>
<cfset NetFees = variables.TotalFees - max( 0, min( variables.StartCredit, variables.TotalFees ) )>
<cfset NetDue = variables.NetFees>
<!--- end set payment block vars 

<cfset occalcpage = "passesoccalc.cfm">
<!--- payment sequence is 1 --->
<cfinclude template="paymentblock.cfm"> --->




     <CFPARAM name="gcpayment" default="0">
     <CFPARAM name="newcardbalance" default="0">
     <CFPARAM name="theselectedcard" default="0">
     <CFPARAM name="theselectedcardbalance" default="0">
     <CFPARAM name="theselectedcardisfa" default="0">

<CFIF theselectedcard NEQ 0>
     <CFSET newgcbalance = theselectedcardbalance - form.netdue - gcpayment>
     <cf_cryp type="en" string="#theselectedcard#" key="#skey#">
     <cfset CardLimit = getCardData.sumnet>
     <CFIF getCardData.isfa IS true>
          <CFSET famsg = "Available funds are determined by eligibility of individual household members for family assistance.">
     </CFIF>
</CFIF>



<form method="post" action="checkoutgiftcard.cfm" name="updatecard" autocomplete="off">
     <input type="hidden" name="unreg_gc1" value="">
     <input type="hidden" name="unreg_gc2" value="">
     <input type="hidden" name="unreg_gc3" value="">
     <input type="hidden" name="unreg_gc4" value="">
     <input type="hidden" name="GCString" value="">
     <input type="hidden" name="MaxGCAmount" value="">
     <input name="TotalFees" type="Hidden" value="">
     <input name="NetDue" type="Hidden" value="">
     <input name="pickgiftcard" type="Hidden" value="true">
     <input type="hidden" name="gctype" value="">
     <CFIF structkeyexists(form,"fieldnames")>
     <CFLOOP list="#form.fieldnames#" index="i">
	<CFIF i NEQ "fieldnames" and i NEQ "othercreditused" and i NEQ "NetDue" and i neq "TotalFees" and findnocase("_gc",i) EQ 0 and i NEQ "MaxGCAmount" and i NEQ "gctype">
     <CFOUTPUT>
	<input type="hidden" name="#i#" value="#evaluate('form.#i#')#">
     </CFOUTPUT>
     </CFIF>
     </CFLOOP>
     </CFIF>
     
</form>

<!--- display code --->
<form method="post" action="checkoutccinfo.cfm" name="class_sum" autocomplete="off">
     <input type="hidden" name="classregistrationtransaction" value="true">
     <table border="0" width=730 cellpadding="2" cellspacing="1">
     <TR>
          <td class="pghdr" colspan=8><br>
                    Pass Purchase - Checkout<br><hr color="##f58220" width=100% align="center" size="5px">
               </TD>
     </TR>
          <TR>
               <TD colspan="8" align="center"><CFSET currentstep="2"><CFINCLUDE template="wizardsteps.cfm">
                    </TD>
          </TR>
     <TR>
     <td class="bodytext" colspan="8" style="padding-left:10px;padding-right:10px;"><span class="pghdr">Gift Card Details</span>
          <table border="0" cellpadding="1" cellspacing="1" style="margin-top:3px;">
               <TR align="right">
                    <td align="left" rowspan="4"><table cellpadding="2" border="0" width="100%" style="padding-right:10px;">
                              <tr>
                                   <td colspan="3" rowspan="2">
                                   <table width="100%">
                                             <CFIF theselectedcard EQ 0>
                                                  <tr>

                                                       <td valign="top"><strong>Registered Card</strong><br>
                                                            <a href="/portal/history/giftcards.cfm">Card balance(s)</a></td>
                                                       <td valign="top"><select name="registeredcard" class="form_input" onChange="updateRegGC();">
                                                                 <option value="None">Select</option>
                                                                 <cfif IsDefined("getOCcards")>
                                                                      <CFLOOP query="getOCcards">
                                                                           <cf_cryp type="de" string="#getOCcards.othercreditdata#" key="#skey#">
                                                                           <option value="#trim(cryp.value)##numberformat( getOCcards.sumnet, "9999999.99" )#"  >#left(cryp.value,4)# #insert(" ",mid(cryp.value,5,8),4)# #right(cryp.value,4)#($#numberformat( getOCcards.sumnet, "99,999.99" )#)</option>
                                                                      </CFLOOP>
                                                                 </cfif>
                                                            </select></td>
                                                  </tr>
                                                  <tr>

                                                       <td><strong>Unregistered Card</strong></td>
                                                       <td> <input type="text" id="unreg_gc1" name="unreg_gc1" size="4" maxlength="4" class="form_input" value="#form.unreg_gc1#" autocomplete="off" onkeyup="if(this.value.length==4) {document.getElementById('unreg_gc2').focus();}">
                                                            <input type="text" id="unreg_gc2" name="unreg_gc2" size="4" maxlength="4" class="form_input" value="#form.unreg_gc2#" autocomplete="off" onkeyup="if(this.value.length==4) {document.getElementById('unreg_gc3').focus();}">
                                                            <input type="text" id="unreg_gc3" name="unreg_gc3" size="4" maxlength="4" class="form_input" value="#form.unreg_gc3#" autocomplete="off" onkeyup="if(this.value.length==4) {document.getElementById('unreg_gc4').focus();}">
                                                            <input type="text" id="unreg_gc4" name="unreg_gc4" size="4" maxlength="4" class="form_input" value="#form.unreg_gc4#" autocomplete="off">
                                                            <input type="button" style="font-size:10px;" value="Go" onClick="fetchUnRegGC();"></td>
                                                  </tr>
                                                  <CFELSE>
                                                  <tr>
                                                       <td width="100%"><input type="hidden" name="unreg_gc1" size="4" maxlength="4" class="form_input" value="#form.unreg_gc1#" autocomplete="off">
                                                            <input type="hidden" name="unreg_gc2" size="4" maxlength="4" class="form_input" value="#form.unreg_gc2#" autocomplete="off">
                                                            <input type="hidden" name="unreg_gc3" size="4" maxlength="4" class="form_input" value="#form.unreg_gc3#" autocomplete="off">
                                                            <input type="hidden" name="unreg_gc4" size="4" maxlength="4" class="form_input" value="#form.unreg_gc4#" autocomplete="off">
                                                            Use selected card to pay  $#trim(numberformat(gcpayment,"999,999.99"))# of the $#trim(numberformat(form.netdue,"999,999.99"))# due. Use buttons below to clear card or enter a different amount.

<CFIF gcpayment LT form.netdue><br><br>Remaining balance of $#trim(numberformat(form.netdue - gcpayment,"999,999.99"))# must be paid by credit/debit card.</CFIF> <CFIF famsg NEQ ""><br><br><strong>#famsg#</strong></CFIF></td>
                                                  </tr>
                                             </CFIF>
                                        </table></td>
                                   <td rowspan="2">&nbsp;</td>
                                   <CFIF Isdefined("gcpayment") and gcpayment GT 0>
                                        <td  style="background-color:##99CCFF;width:160px;padding:3px;font-size:12px;" align="center"><strong>Selected Gift Card</strong>
                                             <div align="center" style="background-color:##000;color:##fff;margin-top:2px;margin-bottom:2px;font-size:12px;font-weight:bold;">#left(theselectedcard,4)# #insert(" ",mid(theselectedcard,5,8),4)# #right(theselectedcard,4)#</div>
                                             <div align="center" style="background-color:##eee;color:##000;margin-top:2px;margin-bottom:2px;font-size:10px;">#dollarformat(truebalance)# available for this transaction.</div>
                                             </div>


                                             <input type="hidden" name="giftcardnumber" value="#thecardnumber#">
									<input type="hidden" name="occardnumber" value="#thecardnumber#">
                                             <input type="hidden" name="occardid" value="#getCardData.cardID#">
                                             </td>
                                        <CFELSE>
                                        <td  style="width:180px;padding:3px;">
                                        <strong>Instructions</strong><br>
                                        1. Select card or enter number<br>

                                        2. Adjust amount if needed<br>

                                        3. Click Continue.


                                        </td>
                                   </CFIF>
                              </tr>

                              <CFIF selectcardmessageerror NEQ "">
                                   <SCRIPT>
		alert("#selectcardmessageerror#");
		</SCRIPT>
                              </CFIF>
                              <tr>
                                   <td>&nbsp;</td>
                              </tr>
                         </table></td>
                    <TD nowrap bgcolor="##eeeeee">Account Balance</TD>
                    <td align="right" width="1%"><input value="#trim( NumberFormat(variables.StartCredit,'99999.99'))#" name="AvailableCredit" type="text" readonly style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
               </TR>
               <TR align="right">
                    <TD nowrap bgcolor="##eeeeee">Total Fees</TD>
                    <td align="right" width="1%"><input readonly value="#trim( NumberFormat(variables.TotalFees,"999999.99"))#" type="Text" name="TotalFees" style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
               </TR>
               <TR align="right">
                    <TD bgcolor="##eeeeee">Credit Used</TD>
                    <TD><input value="#trim( NumberFormat(max(0,min(StartCredit, TotalFees)),"999999.99"))#" name="CreditUsed" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
               </TR>
               <TR align="right">
                    <TD bgcolor="##eeeeee">Net Due</TD>
                    <TD><input value="#trim( NumberFormat( variables.NetFees, '99999.99' ))#" name="NetDue" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
               </TR>
               <TR align="right">
                    <td valign="top" bgcolor="##99CCFF" align="center"><CFIF Isdefined("gcpayment") and gcpayment GT 0 and 0>
                              <CFIF getcarddata.isfa>
                              <b>Apply
                              $<input readonly type="text" size="6"  name="newgcamount" value="#numberformat(gcpayment,'_.__')#" style="  font-size:10px;">
                              to this transaction.
                              
                              <input type="button" value="Clear Card" style="font-size:10px;" onClick="window.location='checkoutgiftcard.cfm';">
                              <CFELSE>
                              <b>Apply
                              $<input type="text" size="6"  name="newgcamount" value="#numberformat(gcpayment,'_.__')#" style="  font-size:10px;">
                              to this transaction.
                              <input type="button" value="Update Amount" style="font-size:10px;" onClick="updateGCamount();">
                              <input type="button" value="Clear Card" style="font-size:10px;" onClick="window.location='checkoutgiftcard.cfm';">
                              </b>
                              </CFIF>
                         </CFIF>


                         <CFSET ThisOtherCreditAvailableLimit = 0></td>
                    <TD bgcolor="##99CCFF" valign="middle"><!---<cfif IsDefined("getCardData.othercreditdesc")>#getCardData.othercreditdesc#<cfelse>Card</cfif><br>Funds To Apply--->
                    	<CFIF Isdefined("gcpayment") and gcpayment GT 0>Gift Card</CFIF>
                         </TD>
                         <CFIF Isdefined("gcpayment") and gcpayment GT 0><CFSET thegcpay = gcpayment><CFELSE><CFSET thegcpay = gcpayment></CFIF>
                    <TD bgcolor="##99CCFF" valign="middle"><input type="Text" <cfif ThisOtherCreditAvailableLimit is 0> style="text-align: right; width: #moneywidth#px; font-size:10px;" readonly<cfelse> style="background-color:##FFFF99; text-align: right; width: #moneywidth#px; font-size:10px;" onChange="this.value=formatCurrency(this.value);calcfee()" </cfif> name="giftcarddebitamount" value="#numberformat(thegcpay,'99999999.99')#" class="form_input" >
                    <input type="hidden" name="tenderedoc" value="#numberformat(thegcpay,'99999999.99')#">
                    </TD>
               </TR>
               <TR align="right">
                    <td bgcolor="##FFFF99" ></td>
                    <td valign="middle" align="right" nowrap bgcolor="##FFFF99">Adjusted Net Due</td>
                    <td valign="middle" align="right" bgcolor="##FFFF99"><input value="#numberformat(variables.NetFees - gcpayment  ,"999,999.99")#" type="Text" readonly="yes" name="AdjustedNetDue" style="text-align: right; background: white; width: #moneywidth#px;" class="form_input"></td>
               </TR>
          </table>

</TD>
<CFIF isdefined("getcarddata") and structkeyexists(getcarddata,"isfa") and getcarddata.isfa >
<CFINCLUDE template="passesoccalc.cfm">
</CFIF>
</TR>

          <TR>
               <td colspan="8" align="center"><div style="height:50px;"></div>
                    <hr color="##f58220" width=100% align="center" size="5px">
                    <input type="Button" class="GoButton" onClick="history.back()" value="Go Back" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;">
                    <!---cfif nettopay gte 0 and Get4NewRegistrations.tmp is 1 AND theselectedcard NEQ 0></cfif>--->
                    <input name="checkout" value="Continue" type="Button" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;" class="throttlecheckout2" onclick="<CFOUTPUT>#application.checkoutonclick#('class_sum');</CFOUTPUT>">
                    <CFIF listfind(application.developerip,cgi.remote_addr) GT 0>
                         <input type="checkbox" name="testmode" value="1">
                         Test Mode: Rollback and display invoice tables
                    </CFIF></TD>
          </TR>
	<CFIF structkeyexists(form,"fieldnames")>
     <CFLOOP list="#form.fieldnames#" index="i">
	<CFIF i NEQ "fieldnames" and i NEQ "othercreditused" and i NEQ "NetDue" and i neq "TotalFees" and findnocase("_gc",i) EQ 0 and i NEQ "MaxGCAmount" and i NEQ "gctype" and i neq "adjustednetdue" and i neq "AVAILABLECREDIT" and i neq "CREDITUSED">
     <CFOUTPUT>
	<input type="hidden" name="#i#" value="#evaluate('form.#i#')#">
     </CFOUTPUT>
     </CFIF>
	</CFLOOP>
     </CFIF>
     <cfif Isdefined("othercreditdata") AND IsNumeric(OtherCreditData)>
     <input type="hidden" name="othercreditdata" value="#getcarddata.cardid#">
     
     </cfif>
</form>

<!--- END CLASS CONTENT --->
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
</cfoutput>
<cfinclude template="/portalINC/jqstuff.cfm">
<CFINCLUDE template="/portalINC/googleanalytics.cfm">



</body>
</html>
<CFIF isdefined("getcarddata") and 0>
	<CFDUMP var="#getcarddata#">
	<CFDUMP var="#getoccards#">
</CFIF>
<CFIF 0>
	<CFDUMP var="#getsession#">
	<CFDUMP var="#form#">
</CFIF>

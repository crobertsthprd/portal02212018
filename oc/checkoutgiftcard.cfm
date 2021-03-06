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

<!---// must confirm user is in WWW session before continuing //

<!--- ADD check to see if the sessionid has any completed transactions with it --->
<CFSET checksession = sessioncheck(primarypatronid)>
<CFIF checksession.sessionID NEQ 0>
     <CFSET CurrentSessionID = checksession.sessionID>
     <CFELSE>
     <CFSET CurrentSessionID = 0>
     <!--- generic alert page --->
     <CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(checksession.message)#">
     <CFABORT>
</CFIF>--->

<!--- reset session for testing 
<CFIF Isdefined("url.resetsession")>
     <cfset newsessionid = uCase(application.IDmaker.randomUUID().toString())>
     <CFQUERY name="newsession" datasource="#application.dopsds#">
insert into sessions
(sessionid)
VALUES
('#newsessionid#');
update sessionpatrons set sessionid = '#newsessionid#' where sessionid = '#CurrentSessionID#';
update sessionpatronsorigdata set sessionid = '#newsessionid#' where sessionid = '#CurrentSessionID#';
update sessionquerylisting set sessionid = '#newsessionid#' where sessionid = '#CurrentSessionID#';
update sessionquerywords set sessionid = '#newsessionid#' where sessionid = '#CurrentSessionID#';
</CFQUERY>
     <!--- recheck --->
     <CFSET rechecksession = sessioncheck(primarypatronid)>
     <CFSET CurrentSessionID = rechecksession.sessionID>
</CFIF>
--->

<!--- load FA balances, if any --->
<cfquery datasource="#application.dopsdsro#" name="LoadFABalance">
	SELECT   dops.loadfabalance(<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">)
</cfquery>

<cfset TotalMonies = 0>
<cfset TotalCost = 0>
<cfset problems = 0>
<cfset TotalBalance = 0>
<cfset AssmtErrors = 0>
<CFSET FAmax = 0>
<!--- include for card; displayed below; called here because queries are needed --->
<cfset suppresstitle = 0>
<cfset suppressdropbutton = 1>

<cfset TotalCost = form.totalfees>
<cfset NetBalance = GetAccountBalance(PrimaryPatronID)>
<cfset NetToPay = max(0,TotalCost - NetBalance)>

<cfset CreditUsed = min(NetBalance,TotalCost)>
<!--- <cfoutput>totalcost:#totalcost#, netbalance:#netbalance#, nettopay:#nettopay#</cfoutput> --->
<!--- money needs to be calculated based sum of all fees for transaction --->
	<cfif not IsDefined("getCards")>
     
	<!--- for fa use min(leagfee, faavailable) --->
	
	<cfloop list="#form.selectapptype#" index="leagstr">
		<cfif listgetat(leagstr,2, '^') gt 0>
			<!--- set fasessionusedfa to min(leagfee, sessionavailablefa) --->
            <CFQUERY name="getthisleagfee" datasource="#application.dopsdsro#">
               		select getyouthleagrate(#form.primarypatronid#, #listgetat(leagstr,1, '^')#, 'AC',#listgetat(leagstr,2, '^')#, 'false') as val
            </CFQUERY><!--- <cfdump var="#getthisleagfee#"> --->
            <CFSET thispatronfee = getthisleagfee.val>

            <CFQUERY name="getthisfaavailfee" datasource="#application.dopsdsro#">
               	select sessionavailablefa as val
				from     dops.patronrelations
        		where    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
				and secondarypatronid = <cfqueryparam value="#listgetat(leagstr,1, '^')#" cfsqltype="cf_sql_integer" list="no">
            </CFQUERY><!--- <cfdump var="#getthisfaavailfee#"> --->
            <CFSET thisfaavailfee = getthisfaavailfee.val>
			<!--- <cfoutput>#min(thispatronfee, thisfaavailfee)#</cfoutput> --->
									
		     <cfquery name="updateApplicableFAFunds" datasource="#application.dopsdsro#">
		        update     dops.patronrelations
		        set	sessionusedfa = <cfqueryparam value="#min(thispatronfee, thisfaavailfee)#" cfsqltype="CF_SQL_MONEY">
		        where    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">			
				and secondarypatronid in (<cfqueryparam value="#listgetat(leagstr,1, '^')#" cfsqltype="cf_sql_integer" list="yes">)
			</cfquery>			
		</cfif>
	</cfloop>
     <cfquery name="GetApplicableFAFunds" datasource="#application.dopsdsro#">
        select   sum( sessionusedfa ) as sumsessionusedfa, sum( sessionavailablefa ) as sumsessionavailablefa
        from     dops.patronrelations
        where    primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">
		
	and secondarypatronid in (<cfqueryparam value="#form.patronactivethisinvoice#" cfsqltype="cf_sql_integer" list="yes">)
	and secondarypatronid != <cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">
	</cfquery>
	<!--- <cfdump var="#GetApplicableFAFunds#"> --->
	<cfif GetApplicableFAFunds.sumsessionusedfa gt 0>
        <cfset otherfacreditlimit = GetApplicableFAFunds.sumsessionusedfa>
        <!--- <cfset otherfacreditlimit = GetApplicableFAFunds.sumsessionavailablefa> --->
	</cfif>
     
     <!--- query 
     <cfquery datasource="#application.dopsdsro#" name="getCards">
		SELECT   othercreditdata,
		         othercredittype,
		         faappexpiredate,
		         isfa,
		         dops.getavailableocfunds( othercredithistorysums.cardid, <cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="#TotalCost#" cfsqltype="cf_sql_numeric" list="no">, <cfqueryparam value="#NetToPay#" cfsqltype="cf_sql_numeric" list="no">, <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no"> ) as sumnet
		FROM     othercredithistorysums
		where    primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">
		and      valid
		and      activated
		and      not holdforreview
		and      othercreditdata is not null
		and      dops.getavailableocfunds( othercredithistorysums.cardid, 
          							<cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">, 
                                             <cfqueryparam value="#TotalCost#" cfsqltype="cf_sql_numeric" list="no">, 
                                             <cfqueryparam value="#NetToPay#" cfsqltype="cf_sql_numeric" list="no">, 
                                             <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no"> 
									<cfif IsDefined("otherfacreditlimit")>, <cfqueryparam value="#max(0, otherfacreditlimit)#" cfsqltype="cf_sql_numeric" list="no"></cfif>
                                             ) > <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
		and      ((isfa IS true and current_date < faappexpiredate) OR isfa IS false)
	</cfquery>
	--->

     <!--- gets cards but carddata will not work 
     <cfquery datasource="#application.dopsdsro#" name="getCards">
		SELECT   othercreditdata,
		         othercredittype,
		         dops.getocbalance(othercredithistorysums.cardid, <cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">) as sumnet
		FROM     othercredithistorysums
		where    primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">
		and      valid
		and      activated
		and      not holdforreview
		and      othercreditdata is not null
		and      dops.getocbalance(othercredithistorysums.cardid, 
          					<cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">) > <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
	</cfquery>
--->

	

	<cfquery datasource="#application.dopsds#" name="getCards">
		SELECT   othercreditdata,
          	    othercreditdesc,
		         cardid, --cardid
		         othercredittype,
		         isfa,
		         faapptype,
		         faappid,
		         acctid,
		         faappcurrent,
		         faloadacctid,
		         primarypatronid,
                   <!---
		         dops.getocavailablefunds(othercredithistorysums.cardid, othercredithistorysums.primarypatronid, <cfqueryparam value="#DollarRound(totalfees)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="#DollarRound(netdue)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="-1" cfsqltype="CF_SQL_NUMERIC">) as sumnet--->
                   dops.getavailableocfunds(othercredithistorysums.cardid, othercredithistorysums.primarypatronid, <cfqueryparam value="#DollarRound(totalfees)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="#DollarRound(netdue)#" cfsqltype="CF_SQL_NUMERIC"> ,<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no"> <cfif IsDefined("otherfacreditlimit")>, <cfqueryparam value="#max(0, otherfacreditlimit)#" cfsqltype="cf_sql_numeric" list="no"></cfif>) as sumnet
		FROM     othercredithistorysums 
		where    primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">
		and      valid
		and      activated
		and      not holdforreview
		and      othercreditdata is not null

	
			and ((isfa IS true and current_date < faappexpiredate) OR isfa IS false)
	</cfquery><!--- <cfdump var="#getcards#"> --->

</cfif>
	<CFIF Isdefined("pickgiftcard")>
     <CFSET thecardnumber = trim(form.unreg_gc1) & trim(form.unreg_gc2) & trim(form.unreg_gc3) & trim(form.unreg_gc4)>



	<!--- do the look up; get balance and create display info --->
     <CFIF Isnumeric(thecardnumber) and len(thecardnumber) EQ 16>
               <cf_cryp type="en" string="#thecardnumber#" key="#skey#">
               <cfset othercreditdata = thecardnumber>




			<!--- returns zero for available funds ; NOT WORKING --->
               <cfquery datasource="#application.dopsds#" name="getCardData">
               SELECT   othercreditdesc,
                        cardid,
                        othercredittype,
                        isfa,
                        faapptype,
                        faappid,
                        acctid,
                        faappcurrent,
                        faloadacctid,
                        primarypatronid,
                        <!---
                        dops.getavailableocfunds( othercredithistorysums.cardid, othercredithistorysums.primarypatronid, <cfqueryparam value="#DollarRound(totalfees)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="#DollarRound(netdue)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no"> ) as sumnet
				    --->
                        dops.getavailableocfunds(othercredithistorysums.cardid, othercredithistorysums.primarypatronid, <cfqueryparam value="#DollarRound(totalfees)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="#DollarRound(netdue)#" cfsqltype="CF_SQL_NUMERIC">,<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">  <cfif IsDefined("otherfacreditlimit")>, <cfqueryparam value="#max(0, otherfacreditlimit)#" cfsqltype="cf_sql_numeric" list="no"></cfif>) as sumnet
               FROM     othercredithistorysums
               where    valid

               <cfif IsNumeric(OtherCreditData) and OtherCreditData lt 999999999999>
                    and   cardid = <cfqueryparam value="#OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
               <cfelse>
                    and   othercreditdata = <cfqueryparam value="#cryp.value#" cfsqltype="CF_SQL_VARCHAR">
               </cfif>
                    and   ((isfa IS true and current_date < faappexpiredate) OR isfa IS false)
          </cfquery><!--- <cfdump var="#getcarddata#"> --->




               <CFIF getCardData.recordcount EQ 0>
               <CFSET selectcardmessageerror = "Selected card does not exist, is no longer valid, or may have a balance of zero. Please use a different card. The number you entered was: #thecardnumber#.">
               <CFELSEIF getCardData.recordcount EQ 1 and form.MaxGCAmount GT getCardData.sumnet and getCardData.othercredittype neq 'V'>
               <CFSET selectcardmessageerror = "Allocated amount exceeds available funds. Card allocation for this transaction is #dollarformat(getCarddata.sumnet)#. Balances for registered gift cards (including amount available per household member) can found by clicking Gift Cards in the left-hand navigation menu.">
               <CFELSEIF getCardData.recordcount EQ 1>
               

			<CFIF form.gctype EQ 'unregisteredfetch'>
               	<CFSET gcpayment = min(nettopay,getCardData.sumnet)>
                    <CFSET MaxGCAmount = gcpayment>
                    
               <CFELSE>
               	<CFSET gcpayment = min(min(nettopay, MaxGCAmount), getCardData.sumnet)>
               </CFIF>

			



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
<!--- <cfdump var="#form#"> --->
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
<!--- START CLASS CONTENT --->

<!---
<cfif IsInSession(pid) is 1 or ShowInSession is 1>
<table width=730 border=0 cellpadding="1" cellspacing=0>
     <tr>
          <td class="pghdr" colspan=2><br>
               Class Registration - Checkout</td>
     </tr>
     <tr>
          <td><img src="../images/spacer.gif" width=1 height=300></td>
          <td class="bodytext_red" align=center valign=top><br>
               <br>
               <br>
               <br>
               <br>
               This account is currently being used at a facility or by phone. <br>
               Please wait until finished and try again.<BR>
               <input type="Button" class="form_submit" onClick="history.back()" value="Return to Class Listings"></td>
     </tr>
</table>
</td>
</tr>
</table>
</td>
</tr>
<cfinclude template="/portalINC/footer.cfm">
</table>
</body>
</html>
<cfabort>
</cfif>
--->

     <CFPARAM name="gcpayment" default="0">
     <CFPARAM name="newcardbalance" default="0">
     <CFPARAM name="theselectedcard" default="0">
     <CFPARAM name="theselectedcardbalance" default="0">
     <CFPARAM name="theselectedcardisfa" default="0">

<CFIF theselectedcard NEQ 0>
     <CFSET newgcbalance = theselectedcardbalance - nettopay - gcpayment>
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
     <CFLOOP list="#form.fieldnames#" index="i">
	<CFIF i NEQ "fieldnames" and i NEQ "othercreditused" and i NEQ "NetDue" and i neq "TotalFees" and findnocase("_gc",i) EQ 0 and i NEQ "MaxGCAmount" and i NEQ "gctype">
     <CFOUTPUT>
	<input type="hidden" name="#i#" value="#evaluate('form.#i#')#">
     </CFOUTPUT>
     </CFIF>
</CFLOOP>
     
</form>

<!--- display code --->
<form method="post" action="checkoutccinfo.cfm" name="class_sum" autocomplete="off">
     <input type="hidden" name="classregistrationtransaction" value="true">
     <table border="0" width=730 cellpadding="2" cellspacing="1">
     <TR>
          <td class="pghdr" colspan=8><br>
                    Sports League Registration - Checkout<br><hr color="##f58220" width=100% align="center" size="5px">
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
                                                                 <cfif IsDefined("getcards")>
                                                                      <CFLOOP query="getcards">
                                                                           <cf_cryp type="de" string="#getcards.othercreditdata#" key="#skey#">
                                                                           <option value="#trim(cryp.value)##numberformat( sumnet, "9999999.99" )#"  >#left(cryp.value,4)# #insert(" ",mid(cryp.value,5,8),4)# #right(cryp.value,4)#($#numberformat( sumnet, "99,999.99" )#)</option>
                                                                      </CFLOOP>
                                                                 </cfif>
                                                            </select></td>
                                                  </tr>
                                                  <tr>

                                                       <td><strong>Unregistered Card</strong></td>
                                                       <td><input type="text" id="unreg_gc1" name="unreg_gc1" size="4" maxlength="4" class="form_input" value="#form.unreg_gc1#" autocomplete="off" onkeyup="if(this.value.length==4) {document.getElementById('unreg_gc2').focus();}">
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
                                                            Use selected card to pay  $#trim(numberformat(gcpayment,"999,999.99"))# of the $#trim(numberformat(NetToPay,"999,999.99"))# due. Use buttons below to clear card or enter a different amount.

<CFIF gcpayment LT nettopay><br><br>Remaining balance of $#trim(numberformat(nettopay - gcpayment,"999,999.99"))# must be paid by credit/debit card.</CFIF> <CFIF famsg NEQ ""><br><br><strong>#famsg#</strong></CFIF></td>
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
                    <td align="right" width="1%"><input value="#numberformat(NetBalance, "999999.99")#" name="AvailableCredit" type="text" readonly style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
               </TR>
               <TR align="right">
                    <TD nowrap bgcolor="##eeeeee">Total Fees</TD>
                    <td align="right" width="1%"><input readonly value="#numberformat(TotalCost, "999999.99")#" type="Text" name="TotalFees" style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
               </TR>
               <TR align="right">
                    <TD bgcolor="##eeeeee">Credit Used</TD>
                    <TD><input value="#numberformat(creditused, "999999.99")#" name="CreditUsed" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
               </TR>
               <TR align="right">
                    <TD bgcolor="##eeeeee">Net Due</TD>
                    <TD><input value="#numberformat(NetToPay, "999999.99")#" name="NetDue" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
               </TR>
               <TR align="right">
                    <td valign="top" bgcolor="##99CCFF" align="center">
			<CFIF Isdefined("gcpayment") and gcpayment GT 0 and 0>
                              <b>Apply
                              $<input type="text" size="6"  name="newgcamount" value="#numberformat(gcpayment,'_.__')#" style="  font-size:10px;">
                              to this transaction.
                              <input type="button" value="Update Amount" style="font-size:10px;" onClick="updateGCamount();">
                              <input type="button" value="Clear Card" style="font-size:10px;" onClick="window.location='checkoutgiftcard.cfm';">
                              </b>
                         </CFIF>


                         <CFSET ThisOtherCreditAvailableLimit = 0></td>
                    <TD bgcolor="##99CCFF" valign="middle"><!---<cfif IsDefined("getCardData.othercreditdesc")>#getCardData.othercreditdesc#<cfelse>Card</cfif><br>Funds To Apply--->
                    	<CFIF Isdefined("gcpayment") and gcpayment GT 0>Gift Card</CFIF>
                         </TD>
                         <CFIF Isdefined("gcpayment") and gcpayment GT 0><CFSET thegcpay = gcpayment><CFELSE><CFSET thegcpay = gcpayment></CFIF>
                    <TD bgcolor="##99CCFF" valign="middle"><input type="Text" <cfif ThisOtherCreditAvailableLimit is 0> style="text-align: right; width: #moneywidth#px; font-size:10px;" readonly<cfelse> style="background-color:##FFFF99; text-align: right; width: #moneywidth#px; font-size:10px;" onChange="this.value=formatCurrency(this.value);calcfee()" </cfif> name="giftcarddebitamount" value="#numberformat(thegcpay,'99999999.99')#" class="form_input" ></TD>
               </TR>
               <TR align="right">
                    <td bgcolor="##FFFF99" ></td>
                    <td valign="middle" align="right" nowrap bgcolor="##FFFF99">Adjusted Net Due</td>
                    <td valign="middle" align="right" bgcolor="##FFFF99"><input value="#numberformat(NetToPay - gcpayment  ,"999,999.99")#" type="Text" readonly="yes" name="AdjustedNetDue" style="text-align: right; background: white; width: #moneywidth#px;" class="form_input"></td>
               </TR>
          </table>





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

     <CFLOOP list="#form.fieldnames#" index="i">
	<CFIF i NEQ "fieldnames" and i NEQ "othercreditused" and i NEQ "NetDue" and i neq "TotalFees" and findnocase("_gc",i) EQ 0 and i NEQ "MaxGCAmount" and i NEQ "gctype" and i neq "adjustednetdue" and i neq "AVAILABLECREDIT" and i neq "CREDITUSED">
     <CFOUTPUT>
	<input type="hidden" name="#i#" value="#evaluate('form.#i#')#">
     </CFOUTPUT>
     </CFIF>

</CFLOOP>
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


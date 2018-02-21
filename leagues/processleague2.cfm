<cfif 1 is 1>
	<CFINCLUDE template="/portalINC/familyassistance_functions.cfm">
</cfif>

<CFSILENT>

<!--- set to developer mode if IS pcs --->
<cfset IsInDevMode = 0>

<cfif Find(REMOTE_HOST, "'192.168.160.211', '192.168.160.97', '192.168.160.181', '192.168.160.180'") gt 0>
	<cfset IsInDevMode = 1>
</cfif>



<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
</cfif>
<cfset content = "contentds">
<cfparam name="primarypatronid" default="#cookie.uID#">
<cfparam name="huserid" default="0">
<cfparam name="SelectAppType" default="0">
<cfparam name="SelectFacility" default="AC">
<cfparam name="localfac" default="WWW">
<CFPARAM name="form.processaction" default="">
<cfset localnode = "W1">
</CFSILENT>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Sports League Registration</title>
	<link rel="stylesheet" href="/includes/thprdstyles.css">
	<SCRIPT>
		function formatCurrency(num) {
		num = num.toString().replace(/\$|\,/g,'');
		if(isNaN(num))
			num = "0";
			sign = (num == (num = Math.abs(num)));
			num = Math.floor(num*100+0.50000000001);
			cents = num%100;
			num = Math.floor(num/100).toString();
			if(cents<10)
				cents = "0" + cents;
				for (var i = 0; i < Math.floor((num.length-(1+i))/3); i++)
					num = num.substring(0,num.length-(4*i+3))+''+num.substring(num.length-(4*i+3));
			return (((sign)?'':'-') + '' + num + '.' + cents);
			}

	function fillcc() {
		//alert(document.f.registeredcard.options[document.f.registeredcard.options.selectedIndex].value);
		theccnum = document.f.registeredcard.options[document.f.registeredcard.options.selectedIndex].value;
		//alert(document.f.availablefundsloaded.value);
		//alert(theccnum);
		if (theccnum != "None") {
		c1 = theccnum.substring(0,4);
		c2 = theccnum.substring(4,8);
		c3 = theccnum.substring(8,12);
		c4 = theccnum.substring(12,16);
		document.f.unreg_gc1.value = c1;
		document.f.unreg_gc2.value = c2;
		document.f.unreg_gc3.value = c3;
		document.f.unreg_gc4.value = c4;
		document.f.registeredcard.options.selectedIndex = 0;
		//document.f.availablefundsloaded.value = true;
		}
		else {
		//document.f.unreg_gc1.value = "";
		//document.f.unreg_gc2.value = "";
		//document.f.unreg_gc3.value = "";
		//document.f.unreg_gc4.value = "";	
		}
	}

	function calcfee() {
		document.f.OtherCreditUsed.value=Math.min(Math.max(0, parseFloat(document.f.OtherCreditUsed.value)), parseFloat(document.f.NetDue.value));
		document.f.OtherCreditUsed.value=formatCurrency(Math.min(parseFloat(document.f.OtherCreditUsed.value), parseFloat(document.f.OtherCreditAvailable.value)));
		document.f.AdjustedNetDue.value=formatCurrency(parseFloat(document.f.NetDue.value) - parseFloat(document.f.OtherCreditUsed.value));
	}
	
	function noEnter(e) {
     var key;

     if(window.event)
          key = window.event.keyCode;     //IE
     else
          key = e.which;     //firefox

     if(key == 13) {
          alert('full stop');
          return false;
	 }
     else
          return false;
	}
</script>
	
</head>
<body leftmargin="0" topmargin="0">
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
		
		<td valign=top class="bodytext" width="100%">
		<!--- start content --->
		<table border="0" width="100%" cellpadding="1" cellspacing="0">

	
		
			<tr>
				<td  class="pghdr"><br>Sports League Registration Checkout</td>
			</tr>

			<tr>
				<td>
				<!--- start application specific code --->

<cfoutput>

<!--- open/verify open session: REQUIRED at this point --->
<CFSET checksession = sessioncheck(primarypatronid)>
<CFIF checksession.sessionID NEQ 0>
	<CFSET CurrentSessionID = checksession.sessionID>
<CFELSE>
	<CFSET CurrentSessionID = 0>
		Error determining session. <strong>Please log out and log back in</strong>. <a href="javascript:history.back();"><<</a> <a href="javascript:history.back();">Go back</a><br /> 
		<br>
		If the error persists, <a href="mailto:webadmin@thprd.org"><font color="red"><strong>please contact IT</strong></font></a> as soon as possible. <br />
		Please include your THPRD ID, Browser, computer operating system and the class ID.<br>Thank you for your assistance.<br />
	<CFINCLUDE template="/portalINC/sessionfailurenotify.cfm">
	<CFINCLUDE template="leaguefooter.cfm">
	<cfabort>
</cfif>

<cfquery datasource="#application.dopsdsro#" name="GetPatrons">
	SELECT   patronrelations.primarypatronid,
     	    patronrelations.secondarypatronid,
	         secondary.lastname,
	         secondary.firstname,
	         secondary.middlename,
	         secondary.gender,
	         patronrelations.faeligible,
	         patronrelations.sessionavailablefa,
	         0 as activethisinvoice
	FROM     patronrelations 
	         INNER JOIN patrons primarypatron ON patronrelations.primarypatronid=primarypatron.patronid
	         INNER JOIN patrons secondary ON patronrelations.secondarypatronid=secondary.patronid
	WHERE    patronrelations.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
     <!--- added 04/26/2016  CR must match query on index.cfm --->
     ORDER by patronrelations.secondarypatronid 
</cfquery>

<!--- makes sure form was posted with needed parameters --->
<CFIF NOT structkeyexists(form,"selectedpatrons")>
<BR><BR><strong>Missing patron(s).</strong><br>
<br><a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
<CFINCLUDE template="leaguefooter.cfm">
<cfabort>
</CFIF>

<cfset missingselection = 0>
<cfloop list="#form.selectedpatrons#" index="i">

	<cfset appstr = 'selectapptype' & i> 
	<cfset schoolstr = 'selectschool' & i> 

	<cfset appval = #evaluate('form.#appstr#')#>
	<cfset schval = #evaluate('form.#schoolstr#')#>

	<cfif appval eq 0 or schval eq 0>
		<BR><BR><strong>Missing school or league.</strong><br>
		<br><a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<CFINCLUDE template="leaguefooter.cfm">
		<cfabort>
	</cfif>
</cfloop>

<CFDUMP var="#form#">
<cfabort>

<!--- load account balance --->
<cfquery datasource="#application.dopsdsro#" name="GetStartingBalance">
	select dops.primaryaccountbalance(<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp) as b
</cfquery>

<cfset StartCredit = GetStartingBalance.b>
<cfset contentds = "contentds">
<cfparam name="primarypatronid" default="#primarypatronid#">
<cfparam name="huserid" default="0">
<cfparam name="patrons" default="0">
<cfparam name="ThisOtherCreditAvailableLimit" default="0">
<cfset selectdescription = "10">


<cfparam name="CardFAType" default="0">
<cfparam name="unreg_gc1" default="">
<cfparam name="unreg_gc2" default="">
<cfparam name="unreg_gc3" default="">
<cfparam name="unreg_gc4" default="">

<cfset othercreditdata = unreg_gc1 & unreg_gc2 & unreg_gc3 & unreg_gc4>

<cfparam name="RunningFALimit" default="0">
<cfparam name="RunningFALimit2" default="0">

<!--- make sure this in ascending order like the queries; 04.27.2016; possible fix for patron ID mismatch problem --->
<!--- we dont know if some browsers change the order of list values for form fields that have multiple instances --->
<!--- text sort will not work 
<CFSET selectshirt = listsort(selectshirt,"text")>
--->


<!--- based on the way this is written; i dont see anothe way --->
<cfif form.processaction NEQ "ProceedToProcess" or 1>

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
		and      dops.getocbalance(othercredithistorysums.cardid, <cfqueryparam value="#cookie.uid#" cfsqltype="CF_SQL_INTEGER">) > <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
	</cfquery>
	
	<cfset hadactivity = 0>

	<!--- MUST be the same as leaguefees.cfm --->
	<cfquery datasource="#application.contentdsro#" name="GetSchools1" >
		SELECT   th_schools.schoolname, th_schoolsmiddle.schoolname AS middle, 
		         th_schoolshigh.schoolname AS high, th_schoolfeeders.schoolid, 
		         th_schoolfeeders.feederms, th_schoolfeeders.feederhs, 0 as rn
		FROM     th_schoolfeeders th_schoolfeeders
		         INNER JOIN th_schools th_schools ON th_schoolfeeders.schoolid=th_schools.id
		         INNER JOIN th_schools th_schoolsmiddle ON th_schoolfeeders.feederms=th_schoolsmiddle.id
		         INNER JOIN th_schools th_schoolshigh ON th_schoolfeeders.feederhs=th_schoolshigh.id 
		WHERE    th_schoolfeeders.feederms > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER"> 
		AND      th_schoolfeeders.feederhs > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">  
		ORDER BY th_schools.schoolname, th_schoolshigh.schoolname, th_schoolsmiddle.schoolname
	</cfquery>
     	<cfloop query="GetSchools1">
          <cfset QuerySetCell(GetSchools1, "rn", 1000 + currentrow, currentrow)>
     	</cfloop>
     	<cfquery datasource="#application.contentdsro#" name="GetAppTypeLeagueFees">
		SELECT   facid,
		         typecode,
		         description,
		         fee,
		         offershirt,
		         assmtcheckdate,
		         maxqty,
		         acctid, (

		SELECT   coalesce( count(*), 0 )
		FROM     content.th_league_enrollments_view
		WHERE    th_league_enrollments_view.leaguetype = th_leaguetype.typecode 
		AND      th_league_enrollments_view.valid 
		AND      not th_league_enrollments_view.isvoided) as enrolledcount

		FROM     th_leaguetype 
		WHERE    facid = <cfqueryparam value="#SelectFacility#" cfsqltype="CF_SQL_VARCHAR">
		AND      available
		ORDER BY description
	</cfquery>
	
	<cfquery datasource="#application.contentdsro#" name="GetLeaguePatronShirtSizes">
		SELECT   sizecode, 
		sizedescription 
		FROM     th_shirtsize
		order by displayorder
	</cfquery>
	
	<!--- load final array --->
	<cfset FinalArray = ArrayNew(2)>
	
	<cfloop query="GetPatrons" >
		<cfset FinalArray[currentrow][1] = 0><!--- patronid --->
          	<cfset FinalArray[currentrow][1] = getPatrons.secondarypatronid>
		<cfset FinalArray[currentrow][2] = shistruct[getPatrons.secondarypatronid]><!--- shirt size --->
		<cfif structkeyexists(schstruct, getPatrons.secondarypatronid)>
			<cfset FinalArray[currentrow][3] = schstruct[getPatrons.secondarypatronid]><!--- school pathing code --->
		<cfelse>
			<cfset FinalArray[currentrow][3] = 0><!--- school pathing code --->
		</cfif>
		<cfset FinalArray[currentrow][4] = appstruct[getPatrons.secondarypatronid]><!--- activity code --->
          	<cfset FinalArray[currentrow][5] = "">
          	<!--- school pathing names --->
          	<cfset FinalArray[currentrow][6] = 0>
          	<!--- fee --->
          	<cfset FinalArray[currentrow][7] = "">
          	<!--- activity description --->
          	<cfset FinalArray[currentrow][8] = 0>
          	<!--- elementary school id --->
          	<cfset FinalArray[currentrow][9] = 0>
          	<!--- middle school id --->
          	<cfset FinalArray[currentrow][10] = 0>
          	<!--- high/option school id --->
          	<cfset FinalArray[currentrow][11] = 0>
          	<!--- type code --->
          
          	<cfloop query="GetSchools1">
               		<cfif FinalArray[GetPatrons.currentrow][3] is rn>
                    	<cfset FinalArray[GetPatrons.currentrow][5] = schoolname & " Elementary -> " & middle & " Middle -> " & high & " High">
                    	<cfset FinalArray[GetPatrons.currentrow][8] = schoolid>
                    	<cfset FinalArray[GetPatrons.currentrow][9] = feederms>
                    	<cfset FinalArray[GetPatrons.currentrow][10] = feederhs>
                    	<cfbreak>
               		</cfif>
          	</cfloop>

          	<cfloop query="GetAppTypeLeagueFees">
			<!--- lookup patron specific fee with new function --->
               		<CFQUERY name="getfee" datasource="#application.dopsdsro#">
               		select getyouthleagrate(#getPatrons.primarypatronid#, #getPatrons.secondarypatronid#, '#GetAppTypeLeagueFees.facid#',#GetAppTypeLeagueFees.typecode#, 'false') as val
               		</CFQUERY>
               		<CFSET thispatronfee = getfee.val>
			
               
			
			<cfif typecode is appstruct[getPatrons.secondarypatronid]>
                    	<!--- CHANGE 10.22.2014 <cfset FinalArray[GetPatrons.currentrow][6] = fee> --->
                    	<cfset FinalArray[GetPatrons.currentrow][6] = thispatronfee>
                    	<!--- activity fee --->
                    	<cfset FinalArray[GetPatrons.currentrow][7] = description>
                    	<!--- activity description --->
                    	<cfset FinalArray[GetPatrons.currentrow][11] = typecode>
                    	<cfset FinalArray[GetPatrons.currentrow][13] = acctid>
                    	<!--- acctid --->
                    	<cfbreak>
               		</cfif>
          	</cfloop>
     	</cfloop>
</cfif>

<cfdump var="#FinalArray#">





<cfif form.processaction EQ "LoadGiftCard" and OtherCreditData is not "">
	<cfset ocNum = replace(OtherCreditData," ","","all")>
	<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>

	<cfif ocNum is not "">
		<cf_cryp type="en" string="#ocNum#" key="#key#">
		<cfset enOtherCreditData = cryp.value>
		<cfinclude template="/portalINC/GetOtherCreditData.cfm">	

		<cfif GetCardData.recordcount is 1>

			<cfif GetCardData.faapptype is "">
				<cfset CardFAType = 0>
			<cfelse>
				<cfset CardFAType = GetCardData.faapptype>
			</cfif>

		</cfif>

		<cfif GetCardData.recordcount is not 1>
			<cfset CardErrorMsg = "Error in fetching Card ID or had insufficient funds or is invalid/not activated.">
		<cfelseif GetCardData.primarypatronid is not primarypatronid and GetCardData.primarypatronid is not "">
			<cfset CardErrorMsg = "Entered card is registered to another patron, thus cannot be used.">
		<cfelse>
			<cfset ThisOtherCreditAvailableLimit = GetCardData.sumnet>
		</cfif>

		<cfquery datasource="#application.dopsdsro#" name="LoadFABalance">
			select   dops.loadfabalance(<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">)
		</cfquery>

	<cfelse>
		<cfset CardErrorMsg = "Invalid card format.">
	</cfif>

</cfif>





<cfif IsDefined("othercreditused") and othercreditused gt 0 and OtherCreditData is not "">
	<cfset ocNum = replace(OtherCreditData," ","","all")>
	<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
	<cf_cryp type="en" string="#ocNum#" key="#key#">
	<cfset enOtherCreditData = cryp.value>
	<cfinclude template="/portalINC/GetOtherCreditData.cfm">

	<cfif GetCardData.recordcount is not 1>
		<BR><BR><strong>Error in fetching Card ID or is invalid/not activated/on hold.</strong>
		<br>
		<br><a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<CFINCLUDE template="leaguefooter.cfm">		
		<cfabort>
	</cfif>

	<cfif GetCardData.primarypatronid is not "" and GetCardData.primarypatronid is not primarypatronid>
		<BR><BR><strong>Specified Card is registered to another patron, thus cannot be used.</strong>	
		<br>
		<br><a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<CFINCLUDE template="leaguefooter.cfm">		
		<cfabort>
	</cfif>

	<cfset OtherCreditGLAcctID = GetCardData.acctid>
</cfif>


<CFIF form.processaction EQ "ProceedToProcess" AND (NOT structkeyexists(form,"readparentinformation") OR form.readparentinformation NEQ true)>
	Please acknowledge you have read the Parent Information and downloaded the Emergency/Medical Consent form by checking the appropriate checkbox. The Emergency/Medical Consent form must be returned to the Athletic Center in order to complete your registration.
	<BR><BR>
	<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
	<CFINCLUDE template="leaguefooter.cfm">	
	<cfabort>

</CFIF>

<cfif IsDefined("patronactivethisinvoice") and not IsDefined("CardErrorMsg") and form.processaction EQ "ProceedToProcess" and IsDefined("readparentinformation") and 1 is 1>

	<cfset GLCode = 7>
	<cfset ccExp = ccExpMonth & ccExpYear>
	<cfset ccNum = ccNum1 & ccNum2 & ccNum3 & ccNum4>

	<cfif dollarround(netdue - othercreditused) is not dollarround(adjustednetdue)>
		<BR><BR>
		<strong>Specified monies do not calculate as expected. Go back and try again.</strong>
		<BR><BR>
		<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<CFINCLUDE template="leaguefooter.cfm">	
		<cfabort>
	</cfif>

	<cfif AdjustedNetDue gt 0 and (ccExp is "" or ccNum is "" or ccv is "")>
		<strong>No credit card information was found. Go back and try again.</strong>
		<BR><BR>
		<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<CFINCLUDE template="leaguefooter.cfm">		
		<cfabort>
	</cfif>


	<cfif AvailableCredit is not StartCredit>
		<strong>Starting Credit did not match true account balance. Go back and try again.</strong>
		<BR><BR>
		<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<CFINCLUDE template="leaguefooter.cfm">	
		<cfabort>
	</cfif>

	<!--- check for existing enrollments --->
	<cfset alreadyenrolled = 0>

	<cfloop from="1" to="#ArrayLen(FinalArray)#" step="1" index="x">
		<cfset QtyChkArray[x][1] = FinalArray[x][11]>

		<cfif FinalArray[x][10] gt 0 and FinalArray[x][5] is not "" and FinalArray[x][7] is not "">
	
			<!--- insert enrollment data --->
			<cfquery datasource="#application.dopsds#" name="CheckForEnrollments">
				SELECT   th_league_enrollments.pk, patrons.firstname, 
				         th_leaguetype.description,
				         invoice.dt
				FROM     content.th_league_enrollments th_league_enrollments
				         INNER JOIN invoice invoice ON th_league_enrollments.invoicefacid=invoice.invoicefacid AND th_league_enrollments.invoicenumber=invoice.invoicenumber
				         INNER JOIN patrons patrons ON th_league_enrollments.patronid=patrons.patronid
				         INNER JOIN content.th_leaguetype th_leaguetype ON th_league_enrollments.leaguetype=th_leaguetype.typecode 
				WHERE    th_league_enrollments.patronid = <cfqueryparam value="#FinalArray[x][1]#" cfsqltype="CF_SQL_INTEGER"> 
				AND      th_league_enrollments.leaguetype = <cfqueryparam value="#FinalArray[x][11]#" cfsqltype="CF_SQL_INTEGER"> 
				AND      th_league_enrollments.elementary = <cfqueryparam value="#FinalArray[x][8]#" cfsqltype="CF_SQL_INTEGER"> 
				AND      th_league_enrollments.middle = <cfqueryparam value="#FinalArray[x][9]#" cfsqltype="CF_SQL_INTEGER"> 
				AND      th_league_enrollments.high = <cfqueryparam value="#FinalArray[x][10]#" cfsqltype="CF_SQL_INTEGER"> 
				AND      valid 
				AND      not invoice.isvoided
				limit    1
			</cfquery>

			<cfif CheckForEnrollments.recordcount is 1>
				<cfset alreadyenrolled = 1>
				<cfset FinalArray[x][1] = 0>
				<cfset FinalArray[x][2] = CheckForEnrollments.firstname>
				<cfset FinalArray[x][3] = CheckForEnrollments.description>
				<cfset FinalArray[x][4] = CheckForEnrollments.dt>
			</cfif>

		</cfif>

	</cfloop>

	<cfif 0>
		<cfdump var="#FinalArray#">
	</cfif>

	<cfif alreadyenrolled is 1>
		<BR><strong>One or more attempted enrollments were already found. 
		This may be due to the invoice already being processed, possibly caused by the refreshing your browser.
		</strong>
		<BR><BR>
		<strong>Offending enrollments:</strong><br>
		<br>

		<cfloop from="1" to="#ArrayLen(FinalArray)#" step="1" index="x">

			<cfif FinalArray[x][1] is 0>
				#FinalArray[x][2]# for #FinalArray[x][7]# (enrolled #dateformat(FinalArray[x][4],"mm/dd/yyyy")# #lcase(timeformat(FinalArray[x][4], "hh:mmtt"))#)<BR>
			</cfif>
	
		</cfloop>

		<BR><BR>
		<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
		<CFINCLUDE template="leaguefooter.cfm">		
		<cfabort>

	</cfif>



	<cftransaction isolation="REPEATABLE_READ" action="BEGIN">

		<cfquery name="LockInvoice" datasource="#application.dopsds#">
			select   facid
			from     dops.facilities
			where    facid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
			for      update
		</cfquery>

		<cfset ThisModule = "WWW">
		<cfset ActivityLine = 0>
		<cfset GLLineNo = 0>
		<cfset NextInvoice = GetNextInvoice()>


		<!--- verify starting credit --->
		<cfquery name="GetStartingAccountBalanceCheck" datasource="#application.dopsds#">
			select dops.primaryaccountbalance(<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)
		</cfquery>
	
		<cfif dollarRound(GetStartingAccountBalanceCheck.primaryaccountbalance) is not dollarRound(originalavailablecredit)>
			<BR><BR><strong>Starting account balance did not match true balance.</strong>
			<BR><BR>
			<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
			<CFINCLUDE template="leaguefooter.cfm">
			<cfabort>

		</cfif>


		<!--- ----------------- --->
		<!--- Other Credit used --->
		<!--- ----------------- --->
		<cfif othercreditused gt 0 and OtherCreditData is not 0>
			<!--- <cfset ocNum = replace(OtherCreditData," ","","all")>
			<cfset ocNum = REREPLACE(ocNum,"[^0-9]","","ALL")>
			<cf_cryp type="en" string="#ocNum#" key="#skey#">
			<cfset enOtherCreditData = cryp.value>
			<cfinclude template="/portalINC/GetOtherCreditData.cfm"> --->
			<cfset otherCreditGLAcctid = getCardData.acctid>
			<cfinclude template="/portalINC/OCCardUsagePrefix.cfm">

		</cfif>



		<!--- set to location of said file --->
		<cfif AdjustedNetDue gt 0>
			<!---cfinclude template="/Common/CheckCCValidity.cfm"--->
			
			<!--- START inline Credit Card Check --->			
			<cfif ccNum is "" or ccExp is "" or (not IsNumeric(ccv)) or len(ltrim(rtrim(ccv))) is not 3 or len(ltrim(rtrim(ccExp))) lt 4>
				<BR><BR><strong>Missing or invalid information for credit card was detected: </strong>
				<cfif ccNum is ""><BR><BR>Missing card data</cfif>
				<cfif ccExp is ""><BR><BR>Missing exp date</cfif>
				<cfif not IsNumeric(ccv) or len(ltrim(rtrim(ccv))) is not 3><BR><BR>CCV incorrect</cfif>
				<cfif len(ltrim(rtrim(ccExp))) lt 4><BR><BR>Expiration Date incorrect</cfif>
				<BR><BR>
				<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
				<CFINCLUDE template="leaguefooter.cfm">	
				<cfabort>
			</cfif>
			
			<!--- encrypt CC data if used --->
			<cfset ccExp = REPLACE(ccExp," ","","ALL")>
			<cfset ccExp = REREPLACE(ccExp,"[^0-9]","","ALL")>
			<cfset ccExp = left(ccExp,2) & "/" & right(ccExp,2)>
			<!--- check card type and number for validity --->
			<CF_mod10 ccType = "#ccType#" ccNum="#ccNum#" ccExp="#ccExp#">
			
			<cfif valid is 0>
				<BR><BR>
				<strong>The Credit Card data supplied is not valid. Please try again.</strong><BR>
				<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
				<CFINCLUDE template="leaguefooter.cfm">	
				<BR><BR><cfabort>
			</cfif>
			
			<!---	<cf_cryp	[ type = "{ en* | de }" ] (en=encrypt, de=decrypt; default is "en")
											string = "{ string to encrypt or decrypt }"
											key = "{ key to use for encrypt or decrypt }"
											[ return = "{ name a variable to return to the calling page as a structure, default is 'cryp' }" --->
			<cfset ccNum = REPLACE(ccNum," ","","ALL")>
			<cfset ccNum = REREPLACE(ccNum,"[^0-9]","","ALL")>
			<cfset ccExp = REPLACE(ccExp," ","","ALL")>
			<cfset ccExp = REREPLACE(ccExp,"[^0-9]","","ALL")>
			<cf_cryp type="en" string="#ccNum#" key="#key#">
			<cfset ccd = cryp.value>
			
			<cfif ccv is not "">
				<cf_cryp type="en" string="#ccv#" key="#key#">
				<cfset ccven = cryp.value>
			</cfif>			

			<!--- check for visas starting 4801 as they are not compatible with our payment system --->
			<cfif left(ccNum, 4) is "4801">
				<BR><BR>
				<strong style="color:##FF0000;">The credit card data supplied is not compatible with our payment system. We cannot process cards starting with '4801'.<BR><BR>
				<a href="javascript:history.go(-1);"><strong><< Please go back and select a different payment method.</strong></a>
				<CFINCLUDE template="leaguefooter.cfm">	
				<BR><BR><cfabort>
			</cfif>

			<!--- END inline Credit Card Check --->				
		</cfif>
	
		<cfif IsDefined("primarypatronid") and primarypatronid gt 0>
			<cfset thisds = GetDistrictStatus(primarypatronid)>
		</cfif>

		<cfset QtyChkArray = ArrayNew(2)>
		<cfset hadatleastoneenrollment = 0>
	
		<cfloop from="1" to="#ArrayLen(FinalArray)#" step="1" index="x">
			<cfset QtyChkArray[x][1] = FinalArray[x][11]>

			<cfif FinalArray[x][10] gt 0 and FinalArray[x][5] is not "" and FinalArray[x][7] is not "">
				<cfset tmp = "preferredcoach" & FinalArray[x][1]>
				<cfset preferredcoach = evaluate(tmp)>
				<cfset tmp = "comments" & FinalArray[x][1]>
				<cfset comments = evaluate(tmp)>
                    <cfset tmp = "preferredphone" & FinalArray[x][1]>
                    <cfset preferredphone = evaluate(tmp)>
                    <cfset tmp = "preferredemail" & FinalArray[x][1]>
                    <cfset preferredemail = evaluate(tmp)>
		
 			<!--- make sure contact phone is valid --->
			<cfif trim(preferredphone) EQ "" OR IsValid("telephone",preferredphone) EQ false>
				<BR><BR>
				<strong style="color:##FF0000;">Please enter a contact phone number for each league enrollment.<BR><BR>
				<a href="javascript:history.go(-1);"><strong><< Please go back try again.</strong></a>
				<CFINCLUDE template="leaguefooter.cfm">	
				<BR><BR><cfabort>
			</cfif>   
               
			<cfif trim(preferredemail) NEQ "" AND IsValid("email",preferredemail) EQ false>
				<BR><BR>
				<strong style="color:##FF0000;">Contact email is not valid for one or more league enrollments.<BR><BR>
				<a href="javascript:history.go(-1);"><strong><< Please go back and try again.</strong></a>
				<CFINCLUDE template="leaguefooter.cfm">	
				<BR><BR><cfabort>
			</cfif>      
          
				<!--- insert enrollment data --->
				<cfquery datasource="#application.dopsds#" name="InsertData">
					insert into content.th_league_enrollments
						(invoicefacid,
						invoicenumber,
						leaguetype,
						patronid,
						fee,
						shirtsize,
						elementary,
						middle,
						high,
						preferredcoach,
						comments,
						preferredcontactphone,
						preferredcontactemail,
                              mil,
                              ratemethod)
					values
						(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, -- invoicefacid,
						<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- invoicenumber,
						<cfqueryparam value="#FinalArray[x][11]#" cfsqltype="CF_SQL_INTEGER">, -- leaguetype,
						<cfqueryparam value="#FinalArray[x][1]#" cfsqltype="CF_SQL_INTEGER">, -- patronid,
						<cfqueryparam value="#FinalArray[x][6]#" cfsqltype="CF_SQL_MONEY">, -- fee,
						<cfqueryparam value="#FinalArray[x][2]#" cfsqltype="CF_SQL_VARCHAR">, -- shirtsize,
						<cfqueryparam value="#FinalArray[x][8]#" cfsqltype="CF_SQL_INTEGER">, -- elementary,
						<cfqueryparam value="#FinalArray[x][9]#" cfsqltype="CF_SQL_INTEGER">, -- middle,
						<cfqueryparam value="#FinalArray[x][10]#" cfsqltype="CF_SQL_INTEGER">, -- high
						<cfif preferredcoach is not ""><cfqueryparam value="#lTrim(rTrim(preferredcoach))#" cfsqltype="CF_SQL_VARCHAR"><cfelse>null</cfif>, -- preferred coach
						<cfif comments is not ""><cfqueryparam value="#lTrim(rTrim(comments))#" cfsqltype="CF_SQL_VARCHAR"><cfelse>null</cfif>, -- comments
						<cfqueryparam value="#preferredphone#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#preferredemail#" cfsqltype="CF_SQL_VARCHAR">,
                              			(dops.usemilrate( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#getPatrons.secondarypatronid#" cfsqltype="cf_sql_integer" list="no"> ) ),
						(dops.getyouthleagrate( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" >, <cfqueryparam value="#getPatrons.secondarypatronid#" cfsqltype="cf_sql_integer">, <cfqueryparam value="#GetAppTypeLeagueFees.facid#" cfsqltype="cf_sql_varchar" >,<cfqueryparam value="#GetAppTypeLeagueFees.typecode#" cfsqltype="cf_sql_integer" >, 'true') )
                              
                              
                              )
					;
					<cfset NextEC = GetNextEC()>
					<cfset GLLineNo = GLLineNo + 1>
		
					insert into GL
						(Credit,
						AcctID,
						InvoiceFacID,
						InvoiceNumber,
						EntryLine,
						ec,
						activity)
					values
						(<cfqueryparam value="#FinalArray[x][6]#" cfsqltype="CF_SQL_MONEY">,
						<cfqueryparam value="#FinalArray[x][13]#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="League Fees" cfsqltype="CF_SQL_VARCHAR">)
				</cfquery>

				<cfset hadatleastoneenrollment = 1>
			</cfif>
		</cfloop>

		<cfset TenderedCharge = AdjustedNetDue>

		<cfquery datasource="#application.dopsds#" name="InsertInvoice">
			insert into invoice
				(InvoiceFacID,
				InvoiceNumber,
				TotalFees,
				usedcredit,
				othercreditused,
				othercreditusedcardid,
				faappid,
				TenderedCC,
	
				<cfif ccNum is not "">
					CCA,
					CCED,
					CEW,
					ccType,
					CCV,
				</cfif>
	
				Node,
				userid,
				primarypatronid, 
				primarypatronlookup,
				addressid, 
				MAILINGADDRESSID,
				indistrict, 
				insufficientid,
				startingbalance,
				invoicetype)
			values
				(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --InvoiceFacID
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --InvoiceNumber
				<cfqueryparam value="#totalfees#" cfsqltype="CF_SQL_MONEY">, --TotalFees
				<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">, --Used Credit
				<cfqueryparam value="#othercreditused#" cfsqltype="CF_SQL_MONEY">, --othercreditused
	
				<cfif othercreditused gt 0>
					<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">, --othercreditusedcardid
				<cfelse>
					null, ----othercreditusedcardid
				</cfif>
				
				<cfif othercreditused gt 0 and GetCardData.faappid is not "">
					<cfqueryparam value="#GetCardData.faappid#" cfsqltype="CF_SQL_INTEGER">, --faappid
				<cfelse>
					null, --faappid
				</cfif>
				
				<cfqueryparam value="#TenderedCharge#" cfsqltype="CF_SQL_MONEY">, --TenderedCC
	
				<cfif ccNum is not "">
					<cfqueryparam value="#ccd#" cfsqltype="CF_SQL_VARCHAR">, --CCA
					<cfqueryparam value="#ccExp#" cfsqltype="CF_SQL_VARCHAR">, --CCED
					<cfqueryparam value="#right(ccNum,4)#" cfsqltype="CF_SQL_VARCHAR">, --CEW
					<cfqueryparam value="#left(ccNum,1)#" cfsqltype="CF_SQL_VARCHAR">, --ccType
					<cfqueryparam value="#ccven#" cfsqltype="CF_SQL_VARCHAR">, --CCV
				</cfif>
	
				<cfqueryparam value="#LocalNode#" cfsqltype="CF_SQL_VARCHAR">, --LocalNode
				<cfqueryparam value="#huserID#" cfsqltype="CF_SQL_INTEGER">, --huserID
				<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">, (
			
				select   patronlookup
				from     patrons
				where    patronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (
	
				select   addressid
				from     patronrelations
				where    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
				and      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (
	
				select   mailingaddressid
				from     patronrelations
				where    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
				and      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (
	
				SELECT   indistrict 
				FROM     patronrelations 
				WHERE    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
				AND      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (
	
				SELECT   patrons.insufficientid 
				FROM     patronrelations patronrelations
				         INNER JOIN patrons patrons ON patronrelations.secondarypatronid=patrons.patronid 
				WHERE    patronrelations.primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER"> 
				AND      patronrelations.secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (
	
				select   dops.primaryaccountbalance(<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)),
	
				<cfqueryparam value="-LEAG-" cfsqltype="CF_SQL_VARCHAR">)
			;	

			select invoice_relation_fill(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as inserted
		</cfquery>



		<cfif hadatleastoneenrollment is 0>
			<br>
			<strong style="background-color: Yellow;">It appears no enrollments were completed.
			This could be due to selection combinations not being correct.</strong>
			<BR><BR>
			<a href="javascript:history.go(-1);"><strong><< Go back and verify selections are correct.</strong></a>
			
			<CFINCLUDE template="leaguefooter.cfm">
			<cfabort>

		</cfif>

		<!--- check for enrollment qty violation. done here as invoice must be created for view. --->
		<cfloop from="1" to="#ArrayLen(FinalArray)#" step="1" index="x">

			<cfquery datasource="#application.dopsds#" name="CheckForQtyViolation">
				SELECT   patronid
				FROM     content.th_league_enrollments_view
				WHERE    th_league_enrollments_view.valid
				AND      not th_league_enrollments_view.isvoided
				AND      th_league_enrollments_view.leaguetype in (
				
				select   leaguetype
				from     content.th_league_enrollments_view v
				where    v.invoicefacid = <cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">
				and      v.invoicenumber = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">)
				
				and      (
				
				SELECT   count(*)
				FROM     content.th_league_enrollments_view v
				WHERE    th_league_enrollments_view.valid
				AND      not th_league_enrollments_view.isvoided
				AND      v.leaguetype = th_league_enrollments_view.typecode) > th_league_enrollments_view.maxqty
			</cfquery>

			<cfif CheckForQtyViolation.recordcount gt 0>
				<br>
				<strong style="background-color: Yellow;">Proposed operation exceeded maximum enrollment counts for one or more leagues.</strong>
				<BR><BR>
				<a href="javascript:history.go(-1);"><strong><< Go back, refresh page and remove offending enrollments as needed and try again.</strong></a>
				
				<CFINCLUDE template="leaguefooter.cfm">
				<cfabort>

			</cfif>

		</cfloop>





		<cfif InsertInvoice.inserted is 0>
			<strong>Could not insert active patrons for proposed invoice. Contact THPRD.</strong>
			<CFINCLUDE template="leaguefooter.cfm">
			<cfabort>
		</cfif>

		<!--- check for duplicates. has to be done AFTER invoice insertion since it uses invoice.isvoided as a param --->
		<cfquery datasource="#application.dopsds#" name="Check4Dups">
			SELECT   th_league_enrollments_view.patronid, 
			         th_league_enrollments_view.leaguedesc, 
			         th_league_enrollments_view.e_school, 
			         th_league_enrollments_view.m_school, 
			         th_league_enrollments_view.h_school, 
			         th_league_enrollments_view.lastname, 
			         th_league_enrollments_view.firstname, 
			         th_league_enrollments_view.middlename 
			FROM     content.th_league_enrollments_view th_league_enrollments_view
			         INNER JOIN invoice invoice ON th_league_enrollments_view.invoicefacid=invoice.invoicefacid AND th_league_enrollments_view.invoicenumber=invoice.invoicenumber 
			WHERE    th_league_enrollments_view.valid = true 
			AND      th_league_enrollments_view.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
			AND      invoice.isvoided = false 
			GROUP BY th_league_enrollments_view.e_school, th_league_enrollments_view.m_school, th_league_enrollments_view.h_school, th_league_enrollments_view.leaguedesc, th_league_enrollments_view.patronid, th_league_enrollments_view.lastname, th_league_enrollments_view.firstname, th_league_enrollments_view.middlename 
			HAVING   count(*) > <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
		</cfquery>

		<cfif Check4Dups.recordcount gt 0>
			<strong style="background-color: Yellow;">Duplicate patron / pathing / activity was found. All operations rolled back.</strong><BR><BR>
			#Check4Dups.lastname#, #Check4Dups.firstname#, #Check4Dups.leaguedesc#
			<BR><BR>
			<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
			<CFINCLUDE template="leaguefooter.cfm">
			<cfabort>
		</cfif>
		<!--- end check for duplictes --->


		<cfquery datasource="#application.dopsds#" name="updateactive">
			update  invoicerelations
			set
				activethisinvoice = true
			where   invoicefacid = <cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">
			and     invoicenumber = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">
			and     secondarypatronid in (<cfqueryparam value="#patronactivethisinvoice#" cfsqltype="CF_SQL_INTEGER" list="Yes" separator=",">)
			and     secondarypatronid != <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
		</cfquery>




		<!--- ----------- --->
		<!--- used credit --->
		<!--- ----------- --->
		<cfif CreditUsed greater than 0>

			<cfquery datasource="#application.dopsds#" name="GetGLDistCredit">
				select   AcctID
				from     GLMaster
				where    InternalRef = <cfqueryparam value="DC" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>

			<cfif GetGLDistCredit.RecordCount is not 1>
				<strong>Error in fetching account ID for District Credits. Contact THPRD.</strong>
				<CFINCLUDE template="leaguefooter.cfm">
				<cfabort>
			</cfif>

			<cfset KeepThisInvoice = 1>
			<cfset NextEC = GetNextEC()>
			<cfset ActivityLine = ActivityLine + 1>
	
			<cfquery datasource="#application.dopsds#" name="AddToActivity">
				insert into Activity
					(ActivityCode,
					PrimaryPatronID,
					PatronID,
					InvoiceFacID,
					InvoiceNumber,
					Debit,
					Credit,
					line,
					EC)
				values
					(<cfqueryparam value="CU" cfsqltype="CF_SQL_VARCHAR">,
					<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
					<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">,
					<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#ActivityLine#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">)
				;
	
				<cfset GLLineNo = GLLineNo + 1>

				insert into GL
					(Debit,
					AcctID,
					InvoiceFacID,
					InvoiceNumber,
					EntryLine,
					EC,
					activitytype,
					activity)
				values
					(<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">,
					<cfqueryparam value="#GetGLDistCredit.acctid#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
					<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="C" cfsqltype="CF_SQL_VARCHAR">,
					<cfqueryparam value="Credit" cfsqltype="CF_SQL_VARCHAR">)
			</cfquery>
	
		</cfif>
	


		<cfif othercreditused gt 0 and OtherCreditData is not "">
			<cfset dopsds = application.dopsds>
			<cfset SetOCUsage(LocalFac, NextInvoice)>

		</cfif>


		<!--- final check --->
		<cfinclude template="/portalINC/FinalChecks.cfm">


		<!--- rollback and display data if testing --->
		<cfif IsDefined("TestMode") or 0>
			<cfinclude template="/portalINC/displayallinvoicetables.cfm">
			<cfabort>
		</cfif>


	</cftransaction>

	<cfset str1 = localfac & "-" & nextinvoice>
	<CFSET CurrentInvoiceFac = localfac>
	<CFSET CurrentInvoiceNumber = nextinvoice>
	Registration complete. <a target="_blank" href="/portal/classes/class_summary_receipt.cfm?invoicelist=#CurrentInvoiceFac#-#CurrentInvoiceNumber#"><strong>Click here</strong></a> to view invoice. Your confirmation code is <strong>#CurrentInvoiceNumber#</strong>. The invoice will appear in your <strong>Invoice History</strong> in approximately 30 minutes.<br>
<br>
In order to complete registration, you must update <strong>Emergency Contact & Medical Information</strong> using the online tool found <a href="https://www.thprd.org/portal/history/ec.cfm"><strong>here</strong></a>.  
	
<!--- END APPLICATION --->
<CFINCLUDE template="leaguefooter.cfm">
<CFABORT>
</cfif>






<cfparam name="history" default="0">
<form name="f" method="POST" action="#cgi.script_name#">

<cfloop collection="#form#" index="thisfield">
	<input type="hidden" name="#thisfield#" value=#form[thisfield]#>
</cfloop>

<!---
<input name="selectshirt" value="#selectshirt#" type="hidden">
<input name="selectschool" value="#selectschool#" type="hidden">
<input name="SelectAppType" value="#SelectAppType#" type="hidden">
--->

<input name="primarypatronid" value="#primarypatronid#" type="hidden">
<cfset history = history + 1>
<input name="history" value="#history#" type="hidden">
<input name="OfferShirts" value="#OfferShirts#" type="hidden">

<cfset TotalFees = 0>
<cfset shirtsizeviolation = 0>
<cfset lineviolation = 0>

<cfif IsDefined("GetCardData.faapptype") and GetCardData.faapptype is 2>
	<cfset ThisOtherCreditAvailableLimit = 0>
</cfif>



<table border="0" width="100%" cellpadding="3" cellspacing="0">
	<TR>
		<TD class="blackheader">&nbsp;</TD>
		<TD class="blackheader">Name</TD>
		<TD class="blackheader">League</TD>
		<TD class="blackheader">Shirt</TD>
		<TD class="blackheader">School Pathing</TD>
		<TD class="blackheader">Fee</TD>
		<cfif IsDefined("GetCardData.faapptype") and GetCardData.faapptype is 2>
			<TD class="blackheader">GC<BR>Bal</TD>
		</cfif>
	</TR>
 	<cfset patronactivethisinvoice = 0>

	<cfloop query="GetPatrons">
		<cfset shirt = "">
		<cfset school = "">
		<cfset fee = 0>
		<cfset apptype = "">
		<cfset selectioncount = 0>
		<cfset shirtsizestr = "">
		<cfset foundshirtviolationthispatron = 0>

		<cfif FinalArray[GetPatrons.currentrow][5] is not "">
			<cfset selectioncount = selectioncount + 1>
		</cfif>

		<cfif FinalArray[GetPatrons.currentrow][7] is not "">
			<cfset selectioncount = selectioncount + 1>

			<cfloop query="GetLeaguePatronShirtSizes">
	
				<cfif FinalArray[Getpatrons.currentrow][2] is GetLeaguePatronShirtSizes.sizecode>
					<cfset shirtsizestr = sizedescription>
					<cfset shirttest = ListToArray(FinalArray[GetPatrons.currentrow][5], "->")>
					<cfbreak>
				</cfif>
	
			</cfloop>
	
			<cfset foundpathviolationthispatron = 0>
	
			<cfif shirtsizestr is not "">
				<cfset selectioncount = selectioncount + 1>
	
				<cfif FindNoCase("4th", FinalArray[GetPatrons.currentrow][7]) is 0 and FindNoCase("5th", FinalArray[GetPatrons.currentrow][7]) is 0 and left(FinalArray[GetPatrons.currentrow][2], 1) is "Y">
					<cfset foundshirtviolationthispatron = 1>
				</cfif>

			</cfif>
	
			<cfif selectioncount is 0 or selectioncount is 3>
				<cfset QuerySetCell(GetPatrons, "activethisinvoice", 1, GetPatrons.currentrow)>
			<cfelse>
				<cfset lineviolation = 1>
			</cfif>
	
			<cfif foundpathviolationthispatron is 1 or foundshirtviolationthispatron is 1>
				<cfset shirtsizeviolation = 1>
			</cfif>

			<cfset hadactivity = 1>

			<cfset rowstyle = "">
			<TR valign="top"  <cfif foundshirtviolationthispatron is 1 or foundpathviolationthispatron is 1>bgcolor="yellow"<cfelse></cfif>>
				<td valign="middle" align="center" class="#rowstyle#"><CFIF selectioncount EQ 3><input type="checkbox" checked></CFIF>&nbsp;</td>
				<TD  class="#rowstyle#" nowrap>#GetPatrons.lastname#, #GetPatrons.firstname#&nbsp;</TD>
				<TD class="#rowstyle#">#FinalArray[GetPatrons.currentrow][7]#&nbsp;</TD>
				<TD class="#rowstyle#">#shirtsizestr#&nbsp;
	
					<cfif shirtsizestr is not "">
						<cfset patronactivethisinvoice = patronactivethisinvoice & "," & secondarypatronid>
					</cfif>
	
				</TD>
				<TD class="#rowstyle#">#FinalArray[GetPatrons.currentrow][5]#&nbsp;</TD>
				<TD align="right" class="#rowstyle#"><cfif FinalArray[GetPatrons.currentrow][5] gt 0>#numberformat(FinalArray[GetPatrons.currentrow][6], "99,999.99")#</cfif>&nbsp;</TD>
	
				<cfif IsDefined("GetCardData.faapptype") and GetCardData.faapptype is 2 and selectioncount is 3 and faeligible is 1>
					<TD align="right" class="#rowstyle#">#numberformat(sessionavailablefa, "99,999.99")#&nbsp;</TD>
					<cfset ThisOtherCreditAvailableLimit = ThisOtherCreditAvailableLimit + sessionavailablefa>
				<cfelseif IsDefined("GetCardData.faapptype") and GetCardData.faapptype is 2>
					<TD class="#rowstyle#">&nbsp;</TD>
				</cfif>
	
			</TR>
	
			<cfset TotalFees = TotalFees + FinalArray[GetPatrons.currentrow][6]>



			<!--- check for enrollment qty violation: disable for next page process test --->	
			<cfif 1>

				<cfloop query="GetAppTypeLeagueFees">
		
					<cfif GetAppTypeLeagueFees.typecode[GetAppTypeLeagueFees.currentrow] is FinalArray[Getpatrons.currentrow][4]>
						<cfset QuerySetCell(GetAppTypeLeagueFees, "enrolledcount", GetAppTypeLeagueFees.enrolledcount[GetAppTypeLeagueFees.currentrow] + 1, GetAppTypeLeagueFees.currentrow)>
		
						<cfif GetAppTypeLeagueFees.enrolledcount[GetAppTypeLeagueFees.currentrow] gt GetAppTypeLeagueFees.maxqty[GetAppTypeLeagueFees.currentrow]>
							<TR>
								<TD></TD>
								<TD style="background-color: Yellow;" colspan="4" align="center"><strong>Maximum enrollment count of #GetAppTypeLeagueFees.maxqty[GetAppTypeLeagueFees.currentrow]# was exceeded for the enrollment of #GetPatrons.firstname#</strong></TD>
							</TR>
							<cfset foundqtyviolation = 1>
						</cfif>
		
						<cfbreak>
					</cfif>
		
				</cfloop>

			</cfif>


	
			<cfif shirtsizestr is not "">
				<TR>
					<TD colspan="7"  >
                         <table cellpadding="3" cellspacing="0">
                         	<tr>
                              <td align="center" style="background-color:##DDD;" nowrap>
                         
                         
                         Individuals may request a coach, however, the request is <u>NOT</u> guaranteed.  THPRD makes the final decision on player placement.<br>
                         <strong>Preferred Coach</strong>
					<input name="preferredcoach#secondarypatronid#" style="width: 100px;margin-top:3px; margin-bottom:3px;" maxlength="200" class="form_input">
					&nbsp;&nbsp;&nbsp;<strong>Comments</strong>
					<input name="comments#secondarypatronid#" style="width: 310px;" maxlength="2000" class="form_input"><br>
                         </td>
                              </tr>
                         </table>
                           
					</TD>
				</TR>
			</cfif>
	
<!--- get phone numbers and emails for household --->
<cfquery datasource="#application.dopsdsro#" name="houseEmails">
SELECT   loginemail
FROM     dops.patrons
where    loginemail is not null
and      patronid in (
 
SELECT   secondarypatronid
FROM     dops.patronrelations
WHERE    primarypatronid = #primarypatronid#)
 
group by patrons.loginemail
</cfquery>

<cfquery datasource="#application.dopsdsro#" name="housePhones">
SELECT   contactdata
FROM     dops.patroncontact
where    contacttype in ('H', 'W', 'C')
and      patronid in (
 
SELECT   secondarypatronid
FROM     dops.patronrelations
WHERE    primarypatronid = #primarypatronid#)
group by patroncontact.contactdata
</cfquery>
     
     		<tr>
               	<td colspan="7" align="center">
<table  id="alertboxyellow">
	<tr>
		<td valign="middle" align="left"  width="50%">Please let us now how you would like to receive communication from your coach. Nine digit phone number is required.</td>
     
		<td valign="middle" align="right"><strong>Phone</strong></td>
          <td valign="middle" align="left"><input type="text" size="15" name="preferredphone#secondarypatronid#" class="form_input"></td>
		<td>&nbsp;&nbsp;&nbsp;</td>
          <td valign="middle" align="right"><strong>Email</strong></td>
          <td valign="middle" align="left"><input type="text" size="25" name="preferredemail#secondarypatronid#" class="form_input"></td>
          <!---
         <select name="contactinfo#secondarypatronid#" class="form_input"><CFLOOP query="housePhones"><option value="p||#contactdata#">By phone: #contactdata#</option></CFLOOP>
          <CFLOOP query="houseEmails"><option value="e||#loginemail#">By email: #loginemail#</option></CFLOOP></select></td>
		--->
     </tr>	
 </table>         
       
                   </td>
               </tr>
     
			<CFIF selectioncount EQ 3><CFSET rowstyle = "solidborderbold"><CFELSE><CFSET rowstyle = "solidborder"></CFIF>
	
			<TR>
				<TD colspan="6" class="#rowstyle#" style="height:2px;"><b style="font-size:3px;">&nbsp;</b></TD>
			</TR>

		</cfif>

	</cfloop>



	<cfset stoppage = 0>
		<TR>
			<TD colspan="6">
				<cfif IsDefined("ErrorMsg")><cfset stoppage = 1><br><strong>#ErrorMsg#</strong></CFIF>
				<cfif hadactivity is 0><cfset stoppage = 1><br><strong style="background-color: Yellow;">No patrons were selected for any valid activity.</strong></CFIF>
				<cfif shirtsizeviolation is 1 and hadactivity is 1><cfset stoppage = 1><br><strong style="background-color: Yellow;">Shirt size / League mismatches were detected as highlighted above.</strong></CFIF>
				<cfif lineviolation is 1 and hadactivity is 1><cfset stoppage = 1><br><strong style="background-color: Yellow;">Shirt size / School / League selection mismatches were detected as highlighted above. All or no options for each patron must be specified. </strong></CFIF>
				<cfif IsDefined("foundqtyviolation")><cfset stoppage = 1><br><strong style="background-color: Yellow;">One or more maximum enrollment count limitations were detected as highlighted above. Remove offending enrollments or contact THPRD for assistance.</strong></CFIF>

				<CFIF stoppage EQ 1>
					<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
				</CFIF>

			</TD>
		</TR>
	</table>
	<CFIF stoppage EQ 1>
		
		<CFINCLUDE template="leaguefooter.cfm">
		<!---<CFDUMP var="#getPatrons#">--->
		<CFABORT>
	</CFIF>

<!--- start cart --->

<cfset t_oc = REREPLACE(OtherCreditData,"[^0-9]","","ALL") & "                    ">
<cfset t_oc = ltrim(rtrim(mid(t_oc, 1, 4) & " " & mid(t_oc, 5, 4) & " " & mid(t_oc, 9, 4) & " " & mid(t_oc, 13, 4)))>
<cfset moneywidth=70>
<cfset netfees=0>
<cfset creditused = max(0,min(StartCredit, TotalFees))>
<cfset NetDue = TotalFees - creditused>
<cfset netbalance = max(0, StartCredit - creditused)>
<input type="hidden" name="originalavailablecredit" value="#StartCredit#">
<br>
<table border="0">
<TR align="right">
	<td></td>
	<TD nowrap bgcolor="##eeeeee">Account Balance</TD>
	<td align="right" width="1%"><input value="#numberformat(StartCredit, "999999.99")#" name="AvailableCredit" type="text" readonly style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
</TR>
<TR align="right">
	<td></td>
	<TD nowrap bgcolor="##eeeeee">Total Fees</TD>
	<td align="right" width="1%"><input readonly value="#numberformat(TotalFees, "999999.99")#" type="Text" name="TotalFees" style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
</TR>
<TR align="right">
	<td></td>
	<TD bgcolor="##eeeeee">Credit Used</TD>
	<TD><input value="#numberformat(creditused, "999999.99")#" name="CreditUsed" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
</TR>
<TR align="right">
	<td></td>
	<TD bgcolor="##eeeeee">Net Due</TD>
	<TD><input value="#numberformat(NetDue, "999999.99")#" name="NetDue" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
</TR>
<TR align="right">
	<td valign="top" bgcolor="##99CCFF">
	<table width="100%" border="0">
		<tr>
			<td valign="top"><strong>Gift Card, Voucher Selection</strong><br><select name="registeredcard" class="form_input" onChange="fillcc();" style="margin-bottom:5px;" <CFIF ThisOtherCreditAvailableLimit NEQ 0>onclick="alert('Please clear the current card before selecting another.');blur();"</CFIF>>
				<option value="None" <CFIF ThisOtherCreditAvailableLimit NEQ 0>SELECTED</CFIF></option>
				<option value="None" <CFIF ThisOtherCreditAvailableLimit EQ 0>SELECTED</CFIF>><!---Select or Enter Card Number--->Giftcards Unavailable</option>
				<!---
				<cfif IsDefined("getcards")>
					<CFLOOP query="getcards">
						<cf_cryp type="de" string="#getcards.othercreditdata#" key="#skey#">
						<option value="#trim(cryp.value)#">#left(cryp.value,4)# #insert(" ",mid(cryp.value,5,8),4)# #right(cryp.value,4)# (#othercredittype#) ($ #numberformat(sumnet, "99,999.99")#)</option>
					</CFLOOP>
				</cfif>
				--->
			</select>
               <!---
			<CFIF ThisOtherCreditAvailableLimit NEQ 0><td width="95" rowspan="2" align="center" valign="middle"><strong>Available Funds<br>From This Card</strong><br><!---<cfif IsDefined("GetCardData.faapptype") and GetCardData.faapptype is 2>Applicable<cfelse>Available</cfif>---> $ <input name="OtherCreditAvailable"  readonly type="Text" style="text-align: right; width: #moneywidth#px;" value="#numberformat(ThisOtherCreditAvailableLimit, "99999.99")#" class="form_input"></td></CFIF>
			--->		
		</tr>
          
          
		<tr>
			<td >&nbsp;
			
               <!---
			<cfif ThisOtherCreditAvailableLimit is 0>
				<input type="text" name="unreg_gc1" size="4" maxlength="4" class="form_input" value="">&nbsp;
				<input type="text" name="unreg_gc2" size="4" maxlength="4" class="form_input" value="">&nbsp;
				<input type="text" name="unreg_gc3" size="4" maxlength="4" class="form_input" value="">&nbsp;
				<input type="text" name="unreg_gc4" size="4" maxlength="4" class="form_input" value="">&nbsp;&nbsp;&nbsp;
				<input type="button" name="LoadGiftCard" value="Get Available Funds" class="form_input" onClick="this.form.processaction.value='LoadGiftCard';this.form.submit();";>
				
				
				<cfelse>
				<input readonly type="text" name="unreg_gc1" size="4" maxlength="4" class="form_input" value="#unreg_gc1#">&nbsp;
				<input readonly type="text" name="unreg_gc2" size="4" maxlength="4" class="form_input" value="#unreg_gc2#">&nbsp;
				<input readonly type="text" name="unreg_gc3" size="4" maxlength="4" class="form_input" value="#unreg_gc3#">&nbsp;
				<input readonly type="text" name="unreg_gc4" size="4" maxlength="4" class="form_input" value="#unreg_gc4#">&nbsp;&nbsp;&nbsp;
				
				<input type="button" name="ClearGiftCard" value="Clear Card" class="form_input" onClick="this.form.processaction.value='ClearGiftCard';this.form.submit();">	
			</cfif>
               --->
			</td>
			
			
		</tr>
	
	</table>
	
		
	</td>
	<TD bgcolor="##99CCFF" valign="middle">&nbsp;<!---<cfif IsDefined("getCardData.othercreditdesc")>#getCardData.othercreditdesc#<cfelse>Card</cfif><br>Funds To Apply---> <!---<CFIF ThisOtherCreditAvailableLimit NEQ 0> Enter Amount From<br>Available Funds<br> To Apply</CFIF>--->
	</TD>
	<TD bgcolor="##99CCFF" valign="middle"><!---<input type="Text" <cfif ThisOtherCreditAvailableLimit is 0> style="text-align: right; width: #moneywidth#px;" readonly<cfelse> style="background-color:##FFFF99; text-align: right; width: #moneywidth#px;" onChange="this.value=formatCurrency(this.value);calcfee()"</cfif> name="OtherCreditUsed" value="0.00" class="form_input" >---><input type="hidden" name="OtherCreditUsed" value="0.00"></TD>
</TR>


<TR align="right">
	<td bgcolor="##FFFF99" >
	<table border="0" width="100%">
		<tr>
			<td valign="top"><strong>Credit Card</strong><br><select name="ccType" class="form_input">
			<option value="V">Visa</option>
			<option value="MC">MasterCard</option>
			<option value="DISC">Discover</option>
		</select>
		<input name="ccNum1" size="4" type="Text" maxlength="4" class="form_input"> <input name="ccNum2" size="4" type="Text" maxlength="4" class="form_input"> <input name="ccNum3" size="4" type="Text" maxlength="4" class="form_input"> <input name="ccNum4" size="4" type="Text" maxlength="4" class="form_input"></td>
			<td valign="top"><strong>Expires</strong><br>		<select name="ccExpMonth" class="form_input">
			<option value="01"></option>
	
			<cfloop from="1" to="12" step="1" index="q">
				<option value="#numberformat(q,"00")#" >#numberformat(q,"00")#</option>
			</cfloop>

		</select> 		<select name="ccExpYear" class="form_input">
			<option value="1965"></option>

			<cfloop from="0" to="9" step="1" index="q"><!--- allow 10 years ahead --->
				<option value="#year(now()) + q#">#year(now()) + q#
			</cfloop>

		</select></td>
			<td valign="top"><b><A HREF="javascript:void(window.open('/portal/ccv.html','ccvhelp','width=600,height=600,scrollbars=1,resizable=1'))">CCV</A></b><br>
		<input name="ccv" size="3" type="Text" maxlength="3" class="form_input"></td>
		</tr>
	</table>
	
	

		





		
		</td>
	<td valign="middle" align="right" nowrap bgcolor="##FFFF99">Adjusted Net Due</td>
	<td valign="middle" align="right" bgcolor="##FFFF99">
	<input value="#NumberFormat(netdue, '999999.99')#" type="Text" readonly="yes" name="AdjustedNetDue" style="text-align: right; background: white; width: #moneywidth#px;" class="form_input">
	</td>
</TR>
</table>

<!--- END CART; Still need submit --->

<table>
<TR>
	<TD colspan="3" align="center" class="solidborderbold" style="border-top-color:##000000;border-top-style:solid;border-top-width:1px;">

<div align="center">
<table width="90%">
<tr><td>

<br><b>Reminder</b><br>
After submitting payment, be sure to update <strong>Emergency Contact & Medical Information</strong> using the online tool found <a href="javascript:void(window.open('/portal/history/ec.cfm','ccvhelp','width=900,height=400,scrollbars=1,resizable=1'))"><strong>here</strong></a>. This information must be updated for each new season. Registration is not complete until this online form has been updated.<br>
<br>
<b>Note:</b> Please consult <strong>Parent Information Packet</strong> for upcoming important dates regarding team placement and player evaluations for competitive teams.


</td></tr>
</table>
<br>




<table width="90%" id="alertboxyellow">
	<tr>
		<td valign="top" align="center"><input type="Checkbox" name="readparentinformation" value="true"></td>
		<td>I hereby acknowledge that I have read the <strong>Parent Information Packet</strong> for the league I am registering for and will complete/update <strong>Emergency Contact & Medical Information</strong>. This online form must be updated for your registration to be complete; after submitting payment click the red box in the navigation menu.</td>
	</tr>
</table>
</div>

<br>






		<cfif IsDefined("CardErrorMsg")>
			<br><br>#CardErrorMsg#<br><br>
		<cfelse>
			<!--- <input type="Button" value="Return To Selection Page" hRef="javascript:;" onClick="javascript:history.back(#history#);return false"> --->
			<cfif IsInDevMode>
				<input name="TestMode" type="Checkbox" checked>Test Mode&nbsp;&nbsp;&nbsp;
			</cfif>
			<input type="hidden" name="processaction" value="">
			<input type="button" name="ProceedToProcess" value="Finish League Registration" class="form_input" style="background-color:##FFFF99;" onClick="this.form.processaction.value='ProceedToProcess';this.form.submit();";><br><br>
		</cfif>

	</TD>
</TR>
</table>

<input name="patronactivethisinvoice" value="#patronactivethisinvoice#" type="hidden">
<input name="OtherCreditAvailableLimit" type="hidden" value="#ThisOtherCreditAvailableLimit#">
<input name="OtherCreditIsFA" type="hidden" value="<cfif IsDefined("GetCardData.isfa")>#GetCardData.isfa#<cfelse>0</cfif>">
<input name="OtherCreditFALimit" type="hidden" value="#RunningFALimit#">
<input name="FAAppType" type="hidden" value="<cfif IsDefined("GetCardData.faapptype")>#GetCardData.faapptype#<cfelse>0</cfif>">
<input name="OtherCreditFALimit2" type="hidden" value="#RunningFALimit2#">

<cfif 1 is 2>
<table border="1">
			<tr>
				<td><strong>DEBUG:</strong><br>
		<!--- disable for production --->
			<A href="javascript:;" onClick="document.f.ccNum1.value='4111';document.f.ccNum2.value='1111';document.f.ccNum3.value='1111';document.f.ccNum4.value='1111';document.f.ccExpYear.selectedIndex=5;document.f.ccExpMonth.selectedIndex=6;document.f.ccv.value='123';calcfee();">fill cc data</A>
		
		<div align="right">
		ocavail <input name="OtherCreditAvailableLimit" type="text" value="#ThisOtherCreditAvailableLimit#"><br>
		isfa <input name="OtherCreditIsFA" type="text" value="<cfif IsDefined("GetCardData.isfa")>#GetCardData.isfa#<cfelse>0</cfif>"><br>
		fal <input name="OtherCreditFALimit" type="text" value="#RunningFALimit#"><br>
		fat <input name="FAAppType" type="text" value="<cfif IsDefined("GetCardData.faapptype")>#GetCardData.faapptype#<cfelse>0</cfif>"><br>
		fa2l <input name="OtherCreditFALimit2" type="text" value="#RunningFALimit2#"><br>
		patronactivethisinvoice <input name="patronactivethisinvoice" value="#patronactivethisinvoice#" type="text">
		</div></td>
			</tr>
</table>
</CFIF>
</form>
</cfoutput>

				<!--- end application specific code --->
<CFINCLUDE template="leaguefooter.cfm">

<!---
<CFDUMP var="#shirtarray#">
<CFDUMP var="#getpatrons#">
--->

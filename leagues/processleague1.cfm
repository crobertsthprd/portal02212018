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
				<td  class="pghdr"><br>Sports League Registration</td>
			</tr>

			<tr>
				<td>
				<!--- start application specific code --->

<cfoutput>

<!--- makes sure form was posted with needed parameters --->
<CFIF NOT structkeyexists(form,"selectshirt") OR NOT structkeyexists(form,"selectschool") OR NOT structkeyexists(form,"selectapptype")>
<BR><BR><strong>Missing parameters.</strong><br>
<br><a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
<CFINCLUDE template="leaguefooter.cfm">
<cfabort>
</CFIF>

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

<cfset selectshirt_t = REReplace(selectshirt, "[0-9][A-Z]/^,", "", "all")>
<cfset selectschool_t = REReplace(selectschool, "[0-9]^,", "", "all")>
<cfset SelectAppType_t = REReplace(SelectAppType, "[0-9]^,", "", "all")>


<cfif 1 is 2>
	<CFDUMP var="#form#">
	<cfdump var="#selectshirt_t#" label="shirtscore">
	<cfdump var="#selectschool_t#" label="schoolscore">
	<cfdump var="#SelectAppType_t#" label="appscore">
</cfif>

<cfset ShirtArray = ListToArray(selectshirt_t)>
<cfset SchoolArray = ListToArray(selectschool_t)>
<cfset AppArray = ListToArray(SelectAppType_t)>

<!--- setup struct to get app/shirt/school data for each patrons --->
<!--- sample string
<cfset form.SELECTAPPTYPE = '21873^0^0,73925^0^0,73929^0^0,73930^0^0,73931^0^0,73932^0^0,110803^384^0'>
<cfset form.SELECTSCHOOL = '0^0,0^0,0^0,0^0,0^0,0^0,110803^1008'>
<cfset form.SELECTSHIRT = '110803^NA,21873^N/A,73925^N/A,73929^N/A,73930^N/A,73931^NA,73932^NA'>

so finally should be 110803 => 384, 11083=>1008, and 11083=>'NA'

--->
<cfset appstruct = structnew()>
<cfset schstruct = structnew()>
<cfset shistruct = structnew()>

<cfloop from="1" to="#listlen(form.selectshirt)#" index="j">
	<cfset variable.shirtstr = listgetat(form.selectshirt, j, ',')>
	<cfset variable.schoolstr = listgetat(form.selectschool, j, ',')>
	<cfset variable.appstr = listgetat(form.selectapptype, j, ',')>

	<cfset variable.a = structinsert( shistruct, listgetat(variable.shirtstr, 1, '^'), listgetat(variable.shirtstr, 2, '^'), true )>
	<cfset variable.b = structinsert( appstruct, listgetat(variable.appstr, 1, '^'), listgetat(variable.appstr, 2, '^'), true )>
	<cfset variable.c = structinsert( schstruct, listgetat(variable.schoolstr, 1, '^'), listgetat(variable.schoolstr, 2, '^'), true )>
</cfloop>

<!--- check for need of assessment --->
<cfif ArrayLen(AppArray) gt 0>

	<cfloop from="1" to="#ArrayLen(AppArray)#" step="1" index="a">

		<cfif right(AppArray[a],2) is "-1">
			<strong>ERROR: One or more selected leagues require an assessment.</strong>
			<br><br>
			 <a href="javascript:history.back();"><< Go back</a> and verify all selected leagues are correct. If correct, you will need to purchase the indicated assessment.</strong>
			<cfabort>
		</cfif>

	</cfloop>

</cfif>



<!--- makes sure we unpacked the form ok --->
<cfif ArrayLen(ShirtArray) is not GetPatrons.recordcount or ArrayLen(SchoolArray) is not GetPatrons.recordcount or ArrayLen(AppArray) is not GetPatrons.recordcount>
	<BR><BR>
	<strong>Missing information. <a href="javascript:history.back();"><< Go back</a> and verify all selections are valid.</strong>
	<BR><BR>
	<CFINCLUDE template="leaguefooter.cfm">
	<cfabort>
</cfif>

<!--- debug block --->
<cfif 1 EQ 2>
	<cfdump var="#ShirtArray#" label="shirtscore">
	<cfdump var="#SchoolArray#" label="schoolscore">
	<cfdump var="#AppArray#" label="appscore">
</cfif>

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
		         acctid, --(
		0 as enrolledcount

		--SELECT   coalesce( count(*), 0 )
		--FROM     content.th_league_enrollments_view
		--WHERE    th_league_enrollments_view.leaguetype = th_leaguetype.typecode
		--AND      th_league_enrollments_view.valid
		--AND      not th_league_enrollments_view.isvoided) as enrolledcount

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

<!---cfdump var="#FinalArray#"--->
<cfparam name="history" default="0">
<form name="f" method="POST" action="#cgi.script_name#">
<input name="selectshirt" value="#selectshirt#" type="hidden">
<input name="selectschool" value="#selectschool#" type="hidden">
<input name="SelectAppType" value="#SelectAppType#" type="hidden">
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
<input value="#numberformat(StartCredit, "999999.99")#" name="AvailableCredit" type="hidden" readonly style="text-align: right; width: #moneywidth#px;" class="form_input">
<input readonly value="#numberformat(TotalFees, "999999.99")#" type="hidden" name="TotalFees" style="text-align: right; width: #moneywidth#px;" class="form_input">
<input value="#numberformat(creditused, "999999.99")#" name="CreditUsed" readonly type="hidden" style="text-align: right; width: #moneywidth#px;" class="form_input">
<input value="#numberformat(NetDue, "999999.99")#" name="NetDue" readonly type="hidden" style="text-align: right; width: #moneywidth#px;" class="form_input">

	<input value="#NumberFormat(netdue, '999999.99')#" type="hidden" readonly="yes" name="AdjustedNetDue" style="text-align: right; background: white; width: #moneywidth#px;" class="form_input">


<!--- END CART; Still need submit --->

<table>
<TR>
	<TD colspan="3" align="center" class="solidborderbold" >

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




<table width="90%" id="alertboxyellow" style="background-color:##FCC;">
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
			<input type="button" name="ProceedToProcess" value="Continue" class="form_input" style="background-color:##FFFF99;" onClick="this.form.action='checkoutstepone.cfm';this.form.processaction.value='ProceedToProcess';this.form.submit();";><br><br>
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

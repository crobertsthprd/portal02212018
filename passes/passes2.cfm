<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>

<cfoutput>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Pass Purchase Step 2</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="0" topmargin="0">

<form action="passes3.cfm" method="post">
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

	<!---<cfif displaymode is 'm'>--->
	<tr>
	<td colspan=11 class="pghdr"><br>Pass Purchase</td>
</tr>


<cfinclude template="functionscommon.cfm">

<cfset t = checkforclearsession( GetSession.sessionid, "PASS" )>

<cfif variables.t neq "">
	<TR>
		<TD colspan="99">#variables.t#</td>
	</tr>
	<cfabort>
</cfif>



<!--- determine pass mode --->
<cfif IsDefined("form.passaf")>
	<cfset passtype = "AF">
<cfelseif IsDefined("form.passgen")>
	<cfset passtype = "GEN">
<cfelseif IsDefined("form.passdlx")>
	<cfset passtype = "DLX">
<cfelse>
	<TR>
		<td colspan="99">Could determine calling parameters. Go back and try again.</td>
	</tr>
	<cfabort>
</cfif>
<!--- end determine pass mode --->

<input type="hidden" name="passtype" value="#variables.passtype#">



<!--- available passes --->
<cfquery datasource="#application.slavedopsds#" name="GetPassTypes">
	SELECT   PassType.passtype,
	         passtype.passdescription
	FROM     dops.PassRates,
	         dops.PassType
	WHERE    PassRates.PassType=PassType.PassType
	and      current_date between PassRates.passeffectivedate and PassRates.passexpiredate
	and      PassType.passtype = <cfqueryparam value="#variables.passtype#" cfsqltype="cf_sql_varchar" list="no">
</cfquery>

<cfif 0>
	<cfdump var="#GetPassTypes#">
</cfif>

<cfquery datasource="#application.slavedopsds#" name="GetThisSetTerms">
	select   passterm
	from     dops.passrates
	where    passtype = <cfqueryparam value="#variables.passtype#" cfsqltype="cf_sql_varchar" list="no">
	group by passterm
	order by passterm
</cfquery>

<CFIF GetPassTypes.passdescription EQ "Deluxe Pass" and 1>
<tr>
	<TD colspan="10" style="background-color:##FC0;"><strong>New Year Sale</strong>: Single and Couple Deluxe Passes are currently 20% off. Prices reflected below.</td>
</tr>
</CFIF>
<TR>
	<TD colspan="99" bgcolor="cccccc">#GetPassTypes.passdescription# Purchase</td>
</tr>
<TR valign="top">
	<TD nowrap>

		<cfif variables.passtype eq "AF">
			Select single member.
		<cfelse>
			Select desired members.
		</cfif>

		<BR>

		<cfloop query="gethousehold">
			<input <cfif variables.passtype eq "AF">type="radio"<cfelse>type="checkbox"</cfif> name="passmember" value="#gethousehold.patronid#" title="Check to include as a pass member">
			#gethousehold.lastname#,
			#gethousehold.firstname#
			(#gethousehold.years#y, #gethousehold.months#m)
			<BR>
		</cfloop>

	</td>
	<TD>
		Select Term:<BR>

		<cfloop query="GetThisSetTerms">
			<input name="passterm" value="#GetThisSetTerms.passterm#" type="radio" checked title="Select for a #GetThisSetTerms.passterm# month pass">#GetThisSetTerms.passterm# month<BR>
		</cfloop>

		<cfif not GetHousehold.indistrict>
			<BR>

			<cfquery datasource="#application.slavedopsds#" name="GetHasValidAssesment">
				select   dops.hasvalidassmt( <cfqueryparam value="#gethousehold.indistrict[1]#" cfsqltype="cf_sql_integer" list="no"> ) as v
			</cfquery>

			Assesment:

			<cfif GetHasValidAssesment.v>
				<input type="checkbox" name="useassessment">Use Assessment
			<cfelse>
				None found
			</cfif>

		</cfif>

	</td>
	<TD><BR><BR>
		<input type="submit" value="Continue" name="passmembers" title="Proceed to add pass/members">
		<input type="button" value="Cancel" onClick="history.go(-1)" title="Cancel operation">
	</td>
</tr>



<cfif not GetHousehold.indistrict>
	<TR>
		<td colspan="99" style="background-color: aqua;">Please note:
		If a valid assessment is present, you may opt to use it to reduce to cost of the pass.
		However, to be able to continue using said pass, a valid assessment must always be maintained.
		If no assessment is present or you choose to not use it, the fee will be higher but no assessment will be required for its usage.
		Select your choice above.
		</td>
	</tr>
</cfif>

</form>
<tr>
	<td colspan=11 class="pghdr"><br>Basic Rates</td>
</tr>

<tr>
	<TD colspan="99">(exact rate is computed once actual members are selected and pass placed in basket)</td>
</tr>



<TR>
	<td style="background-color: cccccc;"><strong>Individual<CFIF GetPassTypes.passdescription EQ "Deluxe Pass" and 0> - 20% off</CFIF></strong></td>
	<td style="background-color: cccccc;"><strong>Couple<CFIF GetPassTypes.passdescription EQ "Deluxe Pass" and 0> - 20% off</CFIF></strong></td>
	<td style="background-color: cccccc;"><strong>Family</strong></td>
</tr>

<cfquery dbtype="query" name="gethousehold1">
	select   patronid,
	         firstname,
	         relationtype
	from     gethousehold
	order by relationtype, patronid
</cfquery>

<cfquery dbtype="query" name="gethousehold2">
	select   patronid,
	         firstname,
	         relationtype
	from     gethousehold
	order by relationtype, patronid
</cfquery>

<cfset iframewidth = 195>
<tr>
	<TD style="width: 33%;">
		<iframe src="passrates.cfm?passtype=#variables.passtype#&passspan=I" style="height: 260px; width: #variables.iframewidth#px;"></iframe><!--- individual --->
	</td>
	<TD style="width: 33%;">
		<iframe src="passrates.cfm?passtype=#variables.passtype#&passspan=C<cfif variables.passtype eq 'AF'>&suppressspan=1</cfif>" style="height: 260px; width: #variables.iframewidth#px;"></iframe><!--- couple --->
	</td>
	<TD style="width: 33%;">
		<iframe src="passrates.cfm?passtype=#variables.passtype#&passspan=F" style="height: 260px; width: #variables.iframewidth#px;"></iframe><!--- family --->
	</td>
</tr>

</table>
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
<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>

<cfoutput>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Pass Purchase Step 1</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
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

	<!---<cfif displaymode is 'm'>--->









	<tr>
		<td colspan=99 class="pghdr"><br>Pass Purchase</td>
	</tr>

	<cfinclude template="functionscommon.cfm">

	<cfset t = checkforclearsession( GetSession.sessionid, "PASS" )>

	<cfif variables.t neq "">
		<TR>
			<TD colspan="99">#variables.t#</td>
		</tr>
		<cfabort>
	</cfif>

	<cfif IsDefined("url.remec")>

		<cfquery datasource="#application.dopsds#" name="Deletepass">
			delete from dops.sessionpasses
			WHERE  ec = <cfqueryparam value="#url.remec#" cfsqltype="cf_sql_integer" list="no">
			;

			delete from dops.sessionpassmembers
			WHERE  ec = <cfqueryparam value="#url.remec#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

	</cfif>

	<cfinclude template="passesinbasket.cfm">

	<cfif IsDefined("GetBasketPasses.recordcount") and GetBasketPasses.recordcount gt 0>
		<TR>
			<TD nowrap colspan="99" align="right">
				<BR>

				<form action="checkoutstepone.cfm" method="post">
				<input type="submit" value="Continue to Checkout" name="proceedtocheckout" title="Continue to Checkout">
				<input type="hidden" value="#GetSession.sessionid#" name="sid">
				<input type="hidden" value="#cookie.uid#" name="primarypatronid">
				</form>

			</td>
		</tr>
	</cfif>

	<TR>
		<TD colspan="99">

			<table width="650" border=0	cellpadding=3 cellspacing="0">
				<tr valign="bottom" bgcolor="cccccc">
					<TD>Patron</td>
					<TD>Age</td>
					<TD>Discounts</td>
				</tr>

				<!--- show household members --->
				<cfloop query="GetHousehold">
					<TR>
						<TD width="33%">#GetHousehold.lastname#, #GetHousehold.firstname#</td>
						<TD width="33%">#GetHousehold.years#y, #GetHousehold.months#m</td>
						<TD>
							<cfif GetHousehold.issenior>
								Sen&nbsp;
							</cfif>

							<cfif GetHousehold.ismil>
								Mil&nbsp;
							</cfif>

						</td>
					</tr>

				</cfloop>






<!--- available passes --->
<cfquery datasource="#application.slavedopsds#" name="GetPassTypes">
	SELECT   PassType.passtype,
	         passtype.passdescription
	FROM     dops.PassRates,
	         dops.PassType
	WHERE    PassRates.PassType=PassType.PassType
	AND      PassRates.passexpiredate >= current_date
	AND      PassRates.passeffectivedate <= current_date
	and      current_date between PassRates.passeffectivedate and PassRates.passexpiredate
	and      PassType.passtype in (
		<cfqueryparam value="AF" cfsqltype="cf_sql_varchar" list="no">,
		<cfqueryparam value="GEN" cfsqltype="cf_sql_varchar" list="no">,
		<cfqueryparam value="DLX" cfsqltype="cf_sql_varchar" list="no"> )
	group by PassType.passtype, passtype.passdescription
	ORDER BY position( PassType.passtype in <cfqueryparam value="AF-GEN-DLX" cfsqltype="cf_sql_varchar" list="no"> )
</cfquery>

<cfif 0>
	<cfdump var="#GetPassTypes#">
</cfif>



<TR>
	<TD colspan="99"><BR></td>
</tr>


<TR>
	<cfif GetBasketPasses.recordcount eq 0>
		<TD colspan="99" bgcolor="cccccc">Available Pass Types. Select which pass type you wish to purchase below.</td>
	<cfelse>
		<TD colspan="99" bgcolor="cccccc">Available Pass Types. Only one pass can be purchased at a time.</td>
	</cfif>

</tr>
<TR>
	<cfloop query="GetPassTypes">
		<TD style="border-left: 1px solid grey; border-right: 1px solid grey;">#GetPassTypes.passdescription#</td>
	</cfloop>
</tr>
<TR>
	<cfloop query="GetPassTypes">

		<cfquery datasource="#application.slavedopsds#" name="GetThisSetTerms">
			select   passterm
			from     dops.passrates
			where    passtype = <cfqueryparam value="#GetPassTypes.passtype#" cfsqltype="cf_sql_varchar" list="no">
			group by passterm
			order by passterm
		</cfquery>

		<TD valign="top" style="border: 1px solid grey;">
			<strong>Terms:</strong><BR>

			<cfloop query="GetThisSetTerms">
				#GetThisSetTerms.passterm# month

				<cfif GetPassTypes.passtype eq "AF">
					(20 uses)
				</cfif>

				<BR>
			</cfloop>

			<BR>

			<cfquery datasource="#application.slavedopsds#" name="GetThisSetSpans">
				SELECT   passspanlimit
				FROM     dops.passtype
				WHERE    passtype = <cfqueryparam value="#GetPassTypes.passtype#" cfsqltype="cf_sql_varchar" list="no">
			</cfquery>

			<strong>Memberships:</strong><BR>

			<cfif GetThisSetSpans.passspanlimit eq "F">
				Individual<BR>
				Couple<BR>
				Family
			<cfelseif GetThisSetSpans.passspanlimit eq "C">
				Individual<BR>
				Couple
			<cfelse>
				Individual
			</cfif>

		</td>
	</cfloop>

</tr>

<cfif not GetHousehold.indistrict>
	<TR>
		<td colspan="99" style="background-color: aqua;">Please note:
		Out-of-district households can purchase passes in one of two ways.
		If a valid assessment is present, you will have the option to utilize it to reduce to cost of the pass.
		However, to be able to continue using said pass, a valid assessment must always be maintained.
		If no assessment is present or you choose to not use it, the fee will be higher but no assessment will be required for its usage.
		</td>
	</tr>
</cfif>

<form action="passes2.cfm" method="post">
<TR>

<cfif GetBasketPasses.recordcount eq 0>

	<cfloop query="GetPassTypes">
		<TD>
			<input type="submit" value="#GetPassTypes.passdescription#" name="PASS#GetPassTypes.passtype#" style="width: 100%;" title="Select #GetPassTypes.passdescription#">
		</td>
	</cfloop>

</cfif>

</tr>
</form>


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

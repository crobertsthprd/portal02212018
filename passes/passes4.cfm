<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>

<cfoutput>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Pass Purchase Step 4</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="0" topmargin="0">

<cfif IsDefined("form.paymentsequence") and form.paymentsequence eq 2>
SUBMIT TO PROCESSOR!<br>
<form action="checkoutpassesbp_www2.cfm" method="post" name="f">

<CFELSE>
<form action="passes4.cfm" method="post" name="f">
</CFIF>
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







<!--- initiate OC funds for session --->
<cfif not IsDefined("form.PaymentSequence")>

	<cfquery datasource="#application.dopsds#" name="ClearSessionOCAmounts">
		update dops.sessionpassmembers
		set
			ocdist = <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
		where  sessionid = <cfqueryparam value="#form.sid#" cfsqltype="cf_sql_varchar" list="no">
	</cfquery>

</cfif>



<cfif IsDefined("form.paymentsequence") and form.paymentsequence eq 3>

	<cfif IsDefined("form.tenderedoc") and IsNumeric(form.tenderedoc)>

		<cfif form.tenderedoc gt form.tenderedocLimit or 0>
			<TR>
				<TD colspan="99">
					Excessive total amount from gift card was detected. (fees of #decimalformat( form.tenderedoc)# vs. card funds of #decimalformat( form.tenderedocLimit )#) Specifiy a smaller amount.
					<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
				</td>
			</tr>
			<cfabort>
		</cfif>

		<!--- allocation ocfunds : non-FA mode --->
		<cfset runningOCFunds = form.tenderedoc>

		<cfquery datasource="#application.dopsds#" name="GetBasketPassesForOC">
			SELECT   sessionpasses.passfee,
			         sessionpasses.ec
			FROM     dops.sessionpasses sessionpasses
			WHERE    sessionpasses.sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
			and      sessionpasses.isnewpass
			ORDER BY sessionpasses.ec
		</cfquery>

		<cfloop query="GetBasketPassesForOC">

			<cfquery datasource="#application.dopsds#" name="GetBasketPassMembersForOC">
				SELECT   sessionpassmembers.pk
				FROM     dops.sessionpassmembers sessionpassmembers
				WHERE    sessionpassmembers.ec = <cfqueryparam value="#GetBasketPassesForOC.ec#" cfsqltype="cf_sql_integer" list="no">
				ORDER BY pk
			</cfquery>

			<cfset s = min( GetBasketPassesForOC.passfee, variables.runningOCFunds )>

			<cfquery datasource="#application.dopsds#" name="StuffOC">
				update   dops.sessionpassmembers
				set
					ocdist = <cfqueryparam value="#variables.s#" cfsqltype="cf_sql_money" list="no">
				WHERE    sessionpassmembers.pk = <cfqueryparam value="#GetBasketPassMembersForOC.pk#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>

			<cfset runningOCFunds = variables.runningOCFunds - variables.s>
		</cfloop>

	<cfelseif IsDefined("form.OCFieldList") and form.OCFieldList neq "">
		<!--- allocation ocfunds : FA mode --->
		<cfset runningocsum = 0>

		<cfloop list="#form.OCFieldList#" delimiters="," index="l">
			<cfset rec = ListToArray( variables.l, "_" )>
			<cfset pk = evaluate( "#rec[2]#" )>
			<cfset s = max( 0, val( evaluate( "OCFunds_#variables.pk#" )))>

			<cfquery datasource="#application.dopsds#" name="StuffOCAmount">
				update dops.sessionpassmembers
				set
					ocdist = <cfqueryparam value="#variables.s#" cfsqltype="cf_sql_money" list="no">
				where  pk = <cfqueryparam value="#variables.pk#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>

			<cfset NetDue = form.NetDue - variables.s>
			<cfset runningocsum = variables.runningocsum + variables.s>
		</cfloop>

	</cfif>

	<cfquery datasource="#application.dopsds#" name="getOCAMounts">
		select  sum( ocdist ) as ocdistsum
		from    dops.sessionpassmembers
		where   sessionid = <cfqueryparam value="#form.sid#" cfsqltype="cf_sql_varchar" list="no">
	</cfquery>

	<cfset form.tenderedoc = val( getOCAMounts.ocdistsum )>
</cfif>







<cfif IsDefined("form.PaymentSequence") and form.PaymentSequence eq 4>
	<cfset errorstr = "">

	<cfif not IsNumeric( form.netdue ) or 0>
		<cfset errorstr = variables.errorstr & "Improper format for total net due was detected.">
	<cfelseif not IsNumeric( form.adjustednetdue ) or 0>
		<cfset errorstr = variables.errorstr & "Improper format for adjusted net due was detected.">
	</cfif>

	<cfif form.adjustednetdue gt 0>

		<cfif variables.StartCredit neq form.availablecredit or 0>
			<cfset errorstr = variables.errorstr & "Beginning account balance does not match.">
		<cfelseif len( trim( REReplace( form.ccNum, "[^0-9]", "", "all" ))) neq 16 or 0>
			<cfset errorstr = variables.errorstr & "Missing or incorrect format credit card number.">
		<cfelseif len( trim( REReplace( form.CCV, "[^0-9]", "", "all" ))) lt 3 or 0>
			<cfset errorstr = variables.errorstr & "Missing or incorrect format credit card CCV.">
		</cfif>

		<cfif variables.errorstr neq "">
			<TR>
				<TD colspan="99">
					#variables.errorstr#
					<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
				</td>
			</tr>
			<cfabort>
		</cfif>

	</cfif>

	<cfif 0>
		<cfdump var="#form#">
	</cfif>


	<!--- all good to go --->

	<cfinclude template="passfinish.cfm">
	<cfabort>
</cfif>



<cfinclude template="passesinbasket.cfm">










<!--- build calling page elements --->
<cfset hiddenfieldsdebug = 0><!--- makes all these fields text instead of hidden if 1 --->
<!---
<cfloop list="#form.fieldNames#" index="elementloop">

	<cfif lCase( elementloop ) neq "browserhistorydepth">
		<input name="#variables.elementloop#" value="#lTrim( rTrim( form[ variables.elementloop ] ) )#" type="<cfif variables.hiddenfieldsdebug>text<cfelse>hidden</cfif>"<cfif variables.hiddenfieldsdebug> title="#variables.elementloop#" readonly</cfif>>
	</cfif>

</cfloop>
--->
<!--- end build calling page elements --->

<tr>
	<td colspan="99">
		<!--- set payment block vars --->
		<cfset totalfees = variables.runningsum>
		<cfset disableenterkey = "">
		<cfset hidecreditcardpaymentfields = 0>
		<cfset useextensivemode = 0>
		<!--- end set payment block vars --->

		<cfset occalcpage = "passesoccalc.cfm">
		<cfinclude template="paymentblock.cfm">
	</td>
</tr>

</form>





		</tr>
	</table>
	</td>
</tr>

<tr>
	<td colspan="2" valign="top">hello</td>
</tr>

<cfinclude template="/portalINC/footer.cfm">

</table>
</body>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</html>
</cfoutput>

<CFDUMP var="#form#">
<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>

<cfoutput>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Pass Purchase Step 3</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="0" topmargin="0">

<form action="passes4.cfm" method="post">
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


<cfif not IsDefined("form.passmember")>
	<TR>
		<td colspan="99">No pass members were selected. Go back and try again.</td>
	</tr>
	<cfabort>
</cfif>


<!--- determine pass type --->
<cfif not IsDefined("form.passtype")>
	<TR>
		<td colspan="99">Could not determine pass type to process. Go back and try again.</td>
	</tr>
	<cfabort>
</cfif>
<!--- end determine pass type --->

<cfset memberarray = ListToArray( form.passmember, "," )>

<!--- check for valid selections --->
<cfif form.passtype eq "AF" and ArrayLen( memberarray ) neq 1>
	<TR>
		<td colspan="99">More than a single member was selected for pass. Go back and try again.</td>
	</tr>
	<cfabort>
</cfif>


<!--- end check for valid selections --->


<!--- dops.getpassrate( primary, passtype, passterm, assmtwasused, '{patronid list}' ) --->
<!--- determines span automatically based on passed patrons --->
<cfquery datasource="#application.dopsds#" name="GetThisRate">
	select   dops.getpassrate(
		<cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">,
		<cfqueryparam value="#form.passtype#" cfsqltype="cf_sql_varchar" list="no">,
		<cfqueryparam value="#form.passterm#" cfsqltype="cf_sql_smallint" list="no">,
		<cfqueryparam value="#IsDefined('form.useassessment')#" cfsqltype="cf_sql_bit" list="no">,
		'{ #form.passmember# }') as v
</cfquery>

<cfif GetThisRate.v lt 0>
	<TR>
		<td colspan="99">An error occured. Code #GetThisRate.v#. Go back and try again.</td>
	</tr>
	<cfabort>
</cfif>

<!--- verify not already in basket --->
<cfquery datasource="#application.dopsds#" name="GetThisPassExistance">
	SELECT   sessionpasses.pk
	FROM     dops.sessionpasses
	         INNER JOIN dops.sessionpassmembers ON sessionpasses.ec=sessionpassmembers.ec
	WHERE    sessionpasses.sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
	and      sessionpasses.passtype = <cfqueryparam value="#form.passtype#" cfsqltype="cf_sql_varchar" list="no">
	AND      sessionpassmembers.patronid in ( <cfqueryparam value="#form.passmember#" cfsqltype="cf_sql_integer" list="yes"> )
</cfquery>

<cfif GetThisPassExistance.recordcount gt 0>
	<TR>
		<td colspan="99">This patron has already been placed in basket for selected pass. Go back and try again.
          NOTE: If you currently have an active pass that has not expired we cannot process an online purchase for a new pass.
          Our apologies for this limitation. You may purchase a new pass in person at any recreation center.</td>
	</tr>
	<cfabort>
</cfif>
<!--- end verify not already in basket --->

<!--- verify purchased on previous invoice --->
<cfquery datasource="#application.dopsds#" name="GetThisPassExistance">
	SELECT   passes.passexpires,
	         extract( 'months' from age( passes.passexpires, current_date )) as months,
	         extract( 'days' from age( passes.passexpires, current_date )) as days
	FROM     dops.passes
	         INNER JOIN dops.passmembers ON passes.ec=passmembers.ec
	WHERE    passes.primarypatronid = <cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">
	and      passes.passtype = <cfqueryparam value="#form.passtype#" cfsqltype="cf_sql_varchar" list="no">
	and      passes.passexpires >= current_date
	and      passes.valid
	AND      passmembers.patronid in ( <cfqueryparam value="#form.passmember#" cfsqltype="cf_sql_integer" list="yes"> )
</cfquery>


<cfif GetThisPassExistance.recordcount gt 0>
	<TR>
		<td colspan="99">
			This patron is already associated with pass type.
			Expires on #dateformat( GetThisPassExistance.passexpires, "mm/dd/yyyy" )#
			(

			<cfif GetThisPassExistance.months gt 0>
				#GetThisPassExistance.months# months,
			</cfif>

			#GetThisPassExistance.days# days ).
			Go back and try again.
		</td>
	</tr>
	<cfabort>
</cfif>
<!--- end verify purchased on previous invoice --->

<cfquery datasource="#application.dopsds#" name="CheckForPassThisSession">
	SELECT   pk
	FROM     dops.sessionpasses
	WHERE    sessionpasses.sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
	and      isnewpass
</cfquery>

<cfif CheckForPassThisSession.recordcount eq 0>
	<!--- add new pass --->
	<cftransaction action="begin" isolation="repeatable_read">
	<cfset nextec = getnextec()>

	<cfquery datasource="#application.dopsds#" name="GetThisPassExistance">
		insert into dops.sessionpasses
			( isnewpass,
			passtype,
			passterm,
			passallocation,
			passspan,
			passfee,
			sessionid,
			passexpires,
			ec,
			assmtwasused )
		values
			( <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no">,
			<cfqueryparam value="#form.passtype#" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="#form.passterm#" cfsqltype="cf_sql_integer" list="no">,

			<cfif form.passtype eq "AF">
				<cfqueryparam value="20" cfsqltype="cf_sql_integer" list="no">,
			<cfelse>
				<cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">,
			</cfif>

			<cfif ArrayLen( memberarray ) eq 1>
				<cfqueryparam value="I" cfsqltype="cf_sql_char" maxlength="1" list="no">,
			<cfelseif ArrayLen( memberarray ) eq 2>
				<cfqueryparam value="C" cfsqltype="cf_sql_char" maxlength="1" list="no">,
			<cfelse>
				<cfqueryparam value="F" cfsqltype="cf_sql_char" maxlength="1" list="no">,
			</cfif>

			<cfqueryparam value="#GetThisRate.v#" cfsqltype="cf_sql_money" list="no">,
			<cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">,
			current_date + interval '#form.passterm# months',
			<cfqueryparam value="#variables.nextec#" cfsqltype="cf_sql_integer" list="no">,
			<cfqueryparam value="#IsDefined('form.useassessment')#" cfsqltype="cf_sql_bit" list="no"> )
			;

			<cfloop list="#form.passmember#" index="x" delimiters=",">
				insert into dops.sessionpassmembers
					( patronid,
					sessionid,
					ec,
					primarypatronid,
					passexpires2 )
				values(
					<cfqueryparam value="#variables.x#" cfsqltype="cf_sql_integer" list="no">,
					<cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">,
					<cfqueryparam value="#variables.nextec#" cfsqltype="cf_sql_integer" list="no">,
					<cfqueryparam value="#gethousehold.primarypatronid[1]#" cfsqltype="cf_sql_integer" list="no">,
					current_date + interval '#form.passterm# months' )
				;
			</cfloop>

	</cfquery>

	<cfif 0>
		<cfquery datasource="#application.dopsds#" name="GetInserted">
			select   *
			from     dops.sessionpasses
			where    sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
		</cfquery>
		<cfdump var="#GetInserted#">
		<cfquery datasource="#application.dopsds#" name="GetInserted">
			select   *
			from     dops.sessionpassmembers
			where    sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
		</cfquery>
		<cfdump var="#GetInserted#">
		<cfabort>
	</cfif>

	</cftransaction>

</cfif>

<cflocation url="passes.cfm">
<cfabort>

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
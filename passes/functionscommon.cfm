<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>






<cfquery datasource="#application.slavedopsds#" name="GetSession">
	SELECT   sessionid
	FROM     dops.sessionpatrons
	WHERE    primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
	and      relationtype = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
</cfquery>

<cfif GetSession.recordcount eq 0>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>

<cfset StartCredit = 0>

<cfif not IsDefined("form.primarypatronid")>
	<cfset form.primarypatronid = cookie.uid>
</cfif>

<cfif form.primarypatronid gt 0>

	<cfquery datasource="#application.slavedopsds#" name="getStartingBalance">
		select   invoicenet
		from     dops.invoicenet
		where    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
		and      not isvoided
		order by pk desc
		limit    1
	</cfquery>

	<cfif getStartingBalance.recordcount eq 1>
		<cfset StartCredit = getStartingBalance.invoicenet>
	</cfif>

</cfif>

<cfset currentsessionid = cookie.uid>

<cfquery datasource="#application.slavedopsds#" name="GetHousehold">
	SELECT   sessionpatrons.primarypatronid,
	         patrons.patronlookup,
	         sessionpatrons.relationtype,
	         patrons.lastname,
	         patrons.firstname,
	         patrons.middlename,
	         patrons.dob,
	         extract( 'years' from age( current_date, patrons.dob )) as years,
	         extract( 'months' from age( current_date, patrons.dob )) as months,
	         sessionpatrons.indistrict,
	         patrons.patroncomment,
	         patrons.verified,
	         patrons.patronid,
	         dops.isid( <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no"> ) as indistrict,
	         dops.usescrate( sessionpatrons.patronid::integer, current_date) as issenior,
	         dops.usemilrate( <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">, sessionpatrons.patronid::integer ) as ismil
	FROM     dops.sessionpatrons
	         inner join patrons on sessionpatrons.secondarypatronid=patrons.patronid
	WHERE    sessionpatrons.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
	AND      not patrons.inactive
	ORDER BY sessionpatrons.relationtype, upper(patrons.lastname), upper(patrons.firstname)
</cfquery>

<!--- get statuses --->
<cfquery datasource="#application.slavedopsds#" name="getdistrictstatus">
	select   dops.isid( <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no"> ) as v
</cfquery>

<cfif getdistrictstatus.v>
	<cfset assessmentstatus = true>
<cfelse>

	<cfquery datasource="#application.slavedopsds#" name="getassessmentstatus">
		select   dops.hasvalidassmt( <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no"> ) as v
	</cfquery>

	<cfset assessmentstatus = getassessmentstatus.v>
</cfif>
<!--- end get statuses --->






<cffunction name="DollarCeiling" output="Yes" returntype="numeric">
<cfargument name="val" required="No" type="numeric" default="0">
<cfreturn int( arguments.val * 100 + 0.99 ) / 100>
</cffunction>






<cffunction name="checkforclearsession" description="Returns result string if session record exists in specified app">
<cfargument name="sessionvar" type="string" required="true">
<cfargument name="apptype" type="string" required="true">
<!--- acceptable apptype values:
REG
ASSMT
PASS
-- add more as needed
 --->

<cfif ListFind( "REG,ASSMT,PASS", arguments.apptype ) eq 0>
	<cfreturn "Session status could not be determined. Go back and try again. Contact THPRD if assistance is needed.">
</cfif>
<!--- end acceptable apptype --->


<cfset var SessionCheck = "">

<!--- check for session lock - all modes --->
<cfquery datasource="#application.slavedopsds#" name="SessionCheck">
	SELECT   sessionid
	FROM     dops.sessionlock
	WHERE    sessionid = <cfqueryparam value="#arguments.sessionvar#" cfsqltype="cf_sql_varchar" list="no">
	limit    1
</cfquery>

<cfif SessionCheck.recordcount gt 0>
	<cfreturn "This session has either been transfered into THPRD or has expired. Contact THPRD if assistance is needed.">
</cfif>

<cfif arguments.apptype neq "REG">
	<!--- check for session classes --->
	<cfquery datasource="#application.slavedopsds#" name="SessionCheck">
		select   pk
		from     dops.reg
		where    sessionid = <cfqueryparam value="#arguments.sessionvar#" cfsqltype="cf_sql_varchar" list="no">
		limit    1
	</cfquery>

	<cfif SessionCheck.recordcount gt 0>
		<cfreturn "One or more classes were detected to be in shopping cart. Remove from cart or finish, then return here to continue.">
	</cfif>

</cfif>

<cfif arguments.apptype neq "ASSMT">
	<!--- check for session assessments --->
	<cfquery datasource="#application.slavedopsds#" name="SessionCheck">
		select   pk
		from     dops.sessionassessments
		where    sessionid = <cfqueryparam value="#arguments.sessionvar#" cfsqltype="cf_sql_varchar" list="no">
		limit    1
	</cfquery>

	<cfif SessionCheck.recordcount gt 0>
		<cfreturn "One or assessments were detected to be in shopping cart. Remove from cart or finish, then return here to continue.">
	</cfif>

</cfif>

<cfif arguments.apptype neq "PASS">
	<!--- check for session assessments --->
	<cfquery datasource="#application.slavedopsds#" name="SessionCheck">
		select   pk
		from     dops.sessionpasses
		where    sessionid = <cfqueryparam value="#arguments.sessionvar#" cfsqltype="cf_sql_varchar" list="no">
		limit    1
	</cfquery>

	<cfif SessionCheck.recordcount gt 0>
		<cfreturn "One or passes were detected to be in shopping cart. Remove from cart or finish, then return here to continue.">
	</cfif>

</cfif>

<cfreturn "">

</cffunction>

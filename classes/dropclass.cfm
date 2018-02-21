<!---// must confirm user is in WWW session before continuing //--->
<CFSET checksession = sessioncheck(primarypatronid)>
<CFPARAM name="variables.opencallflag" default="false">

<CFIF checksession.sessionID NEQ 0>
	<CFSET CurrentSessionID = checksession.sessionID>
<CFELSE>
	<CFSET CurrentSessionID = 0>
	<!--- generic alert page --->
	<CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(checksession.message)#">
	<CFABORT>
</CFIF>

<!--- do not allow changes to cart if in limbo
<cfquery name="CheckForOpenCall" datasource="#application.dopsds#">
	select dops.hasopencall( <cfqueryparam value="#opencall1.sessionid#" cfsqltype="cf_sql_varchar" list="no"> ) as call
</cfquery> --->

<cfif hasopencall( checksession.sessionID )>

<CFMAIL to="webadmin@thprd.org" from="webadmin@thprd.org" cc="dhayes@thprd.org" subject="Shopping Cart Locked: Open Call" type="html">
This was sent by processreg.cfm
<CFDUMP var="#form#">
<CFDUMP var="#cookie#">
<CFDUMP var="#checksession#">
</CFMAIL>

<cfset opencallflag = "true">

<CFSET dc="">

</cfif>


<!--- drop classes --->
<cfif IsDefined("dc") and dc is not "">
	<cfoutput>
	<cf_cryp type="de" string="#dc#" key="#skey#">
	<cfset dc_dropclass = cryp.value>

	<cftransaction action="BEGIN" isolation="REPEATABLE_READ">

		<!---<cfif SystemLock() is 1></cfif>--->
			<cfset tmp = ListToArray(dc_dropclass, "_")>

			<!--- delete if correct checksum and all other vars match--->
			<cfif tmp[1] + tmp[2] is tmp[3]><!---  and tmp[4] is currentsessionid --->

				<cfquery datasource="#application.dopsds#" name="InsertRegHistory">
					select dops.insertregproc(<cfqueryparam value="#tmp[1]#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="#tmp[2]#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="D" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="W1" cfsqltype="CF_SQL_VARCHAR">)
				</cfquery>

				<cfquery datasource="#application.dopsds#" name="DeleteRegistration">
				<!---delete  from activity
					where   primarypatronid = <cfqueryparam value="#tmp[1]#" cfsqltype="CF_SQL_INTEGER">
					and     regid = <cfqueryparam value="#tmp[2]#" cfsqltype="CF_SQL_INTEGER">
					and     invoicefacid is null
					and     invoicenumber is null
				;--->
					delete  from reg
					where   primarypatronid = <cfqueryparam value="#tmp[1]#" cfsqltype="CF_SQL_INTEGER">
					and     regid = <cfqueryparam value="#tmp[2]#" cfsqltype="CF_SQL_INTEGER">
					;
					delete  from reghistory
					where   primarypatronid = <cfqueryparam value="#tmp[1]#" cfsqltype="CF_SQL_INTEGER">
					and     regid = <cfqueryparam value="#tmp[2]#" cfsqltype="CF_SQL_INTEGER">
				<!---and     invoicefacid is null
				and     invoicenumber is null--->
				</cfquery>

				<cfset msg = "">
			<cfelse>
				<cfset msg = "Could not delete specified class">
				<cfset errormsg = 1>
			</cfif>

	</cftransaction>

	</cfoutput>

</cfif>

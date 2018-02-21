<!--- routine that checks for open call --->
<!--- check open call--->
<CFIF structkeyexists(cookie,"primarypatronid")>

	<CFIF structkeyexists(form,"donotcheckopencall") and form.donotcheckopencall EQ true>
		<CFSET didnotcheck = true>
	<CFELSE>
		<!--- get sessionid --->
		<CFQUERY name="getsession" datasource="#application.dopsds#">
		select dops.getsession(<CFQUERYPARAM cfsqltype="cf_sql_integer" value="#cookie.primarypatronid#">,3) as sessionID
		</CFQUERY>
		<!--- check open transaction --->
		<CFQUERY name="opencall" datasource="#application.dopsds#">
		select dops.hasopencall(<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#getsession.sessionID#"> ) as call
		</CFQUERY>

		<CFIF opencall.call EQ false>
			<CFSET temp = "ok">
		<CFELSE>
			<CFLOCATION url="../index.cfm?msg=951&ref=inc.checkopencall">
		<CFABORT>
		</CFIF>
     </CFIF>

<CFELSE>
<!--- can not authenticate log out --->
	<cflocation url="../index.cfm?msg=3&ref=inc.checkopencall">
</CFIF>
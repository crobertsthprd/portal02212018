<cfif 2 is 2 and cgi.script_name is not "/tasks/sitestatus.cfm">
	<cfinclude template="portaldown.cfm">
	<cfabort>
</cfif>

<CFFUNCTION name="sessioncatch" output="no" returntype="string">
	<CFARGUMENT name="PrimaryPatronID" required="yes" type="string">
	<CFSET var getSessionID = "">
	<CFSET var message = "">
	<CFSET var apachelogline = "">
	
	<CFQUERY name="getSessionID" datasource="#application.dopsds#">
	select   sessionid as thesession, facid 
	from     sessionpatrons
	where    patronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
	and      relationtype = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
	and sessionid IS NOT NULL
	limit    1
	</CFQUERY>
	
	<CFIF getSessionID.recordcount GT 0 and getSession.facid EQ 'WWW'>
		<cfset CurrentSessionID = getSessionID.thesession>
	<CFELSE>
		<CFIF getSessionID.recordcount GT 0 and getSessionID.facid NEQ 'WWW'>
			<CFSET message = "This account is current in session with a phone operator at #getSessionID.facID#">
			<CFSET apachelogline = "fac#getSessionID.facID#">
		<CFELSE>
			<CFSET message = "Error determining session.">
			<CFSET apachelogline = "nosession">
		</CFIF>
	
<CFMAIL to="webadmin@thprd.org" from="webadmin@thprd.org" subject="WWW Portal Session Catch" type="html">
#message#<br />
Server Address: #cgi.server_addr#<br />

The patronID passed in the query is: #PrimaryPatronID#.<br />
The patron IP address is: #cgi.remote_addr#.<br />

<CFDUMP var="#form#">

<CFDUMP var="#cookie#">

<CFDUMP var="#getSessionID#">

</CFMAIL>
		<CFHTTP url="https://www.thprd.org/portal/sessioncatch.cfm?ipaddress=#cgi.remote_addr#&log=#apachelogline#"></CFHTTP>
	
		<CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(message)#">
</CFIF>

</CFFUNCTION>
<!--- reset user vars to pre-login state --->
<!--- <cfinclude template="includes/invoice_functions.cfm"> --->


<cfif structKeyExists(cookie, "uID") and cookie.uID gt 0>
	<cftransaction action="BEGIN" isolation="REPEATABLE_READ">
		<CFQUERY name="closeAll" datasource="#application.dopsds#">
			select dops.webclosehousehold(#cookie.uID#) as closeResp
		</CFQUERY>
		
          <!----
		<CFSET patrondatafromfunction = Patrondata(cookie.uID)>
          <CFPARAM name="patrondatafromfunction.pmtfailure" default="false">
		<CFIF patrondatafromfunction.pmtfailure EQ true>
          	<CFSET url.logoutmsg = "951">
		--->
		<CFIF closeall.closeResp EQ true>
			<CFSET url.logoutmsg = "true">
		<CFELSE>
			<CFSET url.logoutmsg = "Session still active">
		</CFIF>
 	</cftransaction>
	<CFIF structKeyExists(url,"sessioncatch")>
		<CFSET url.logoutmsg = url.sessioncatch>
	</CFIF>
</CFIF>	

<!---
<CFQUERY name="deleteclientvar" datasource="cfclient">
	delete from cdata where cfid = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#client.cfid#:#client.cftoken#">;
     delete from cglobal where cfid = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#client.cfid#:#client.cftoken#">
</CFQUERY>
--->
<CFPARAM name="url.logoutmsg" default="true">
<cfcookie name="loggedin" value="pending">
<cfcookie name="ufname" value="" expires="now"><!--- first name --->
<cfcookie name="ulname" value="" expires="now"><!--- last name --->
<cfcookie name="ulogin" value="" expires="now"><!--- user ID --->
<cfcookie name="uID" value="" expires="now"><!--- patron ID --->
<cfcookie name="ds" value="" expires="now"><!--- district status --->

<cfcookie name="uemail" value="" expires="now">

<cfcookie name="insession" value="" expires="now">


<cfcookie name="cfid"  expires="now">
<cfcookie name="cftoken"  expires="now">



<cfset temp2 = structclear(cookie)>



<!---<CFLOOP list="#structkeylist(cookie);--->

<!--- kill session 
<cfset temp = structclear(session)>--->

<CFSET url.msg=4>





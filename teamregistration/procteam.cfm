<cfset application.dopsds = "dopsds">
<CFPARAM name="url.t" default="0">
<CFPARAM name="url.d" default="0">
<CFPARAM name="url.l" default="0">

<cfoutput>

<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
</cfif>

<CFINCLUDE template="/portalINC/checkopencall.cfm">
<!---cfinclude template="/common/functions.cfm" 06122017 --->
<cfinclude template="/common/checkformelements.cfm">
<cfset sessionvars = getprimarysessiondata(cookie.uid, "TEAM")>

<cfif ( sessionvars.sessionid eq "NONE" or sessionvars.facid neq "WWW" )>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<CFSET variables.thisModule = "TEAM">
<CFSET variables.collisionMsg = "Activities not related to Team Registration were detected.">
<!--- NOTE: no session tables exist for team registration, therefore sessionvars.module must be "NONE" --->
<!--- standard code to determine if there are other items in basket // need to keep track of district credit // assumes closed cfoutput--->
<cfif variables.sessionvars.module neq "NONE" and variables.sessionvars.module neq variables.thisModule>
	<CFSAVECONTENT variable="message">
	<cfoutput>#variables.collisionMsg#<BR>
	#sessionvars.modulecomments#<cfif 0>#sessionvars.module#</cfif>
	</cfoutput>
	</CFSAVECONTENT>
	<cfset form.patronlookup = "">
	<cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>

<cfif not IsDefined("form.go1")>

     <cfsavecontent variable="content">
	
     <br>
     
     Enter team data to process:
	<form method="post" action="procteam.cfm" name="team">
	<input name="currentsessionid" type="hidden" value="#sessionvars.sessionid#">
	<!--- clear next 3 values for real or other testing --->
	<input name="teamid" type="text" value="#url.t#">
	<input name="divisionid" type="text" value="#url.d#">
	<input name="leagueid" type="text" value="#url.l#">
     <input name="go1" type="hidden" value="Continue">
	<input  type="submit" value="Continue">
	</form>
     
     
     <CFIF url.t NEQ 0 AND url.d NEQ 0 AND url.l NEQ 0>
     	<SCRIPT>document.team.submit();</script>
     </CFIF>
     <!---<SCRIPT>document.team.submit();</script>--->
     </cfsavecontent>
	<cfinclude template="layout_getleague.cfm">
	<cfabort>
</cfif>



<cfif 0>
	<cfdump var="#form#">
</cfif>

<cfquery datasource="#application.dopsds#ro" name="GetTeam">
	SELECT   *
	FROM     dops.trteamview
	WHERE    teamid = <cfqueryparam value="#form.teamid#" cfsqltype="cf_sql_integer" list="no">
	and      divisionid = <cfqueryparam value="#form.divisionid#" cfsqltype="cf_sql_integer" list="no">
	and      leagueid = <cfqueryparam value="#form.leagueid#" cfsqltype="cf_sql_integer" list="no">
</cfquery>



<cfif GetTeam.recordcount eq 0>
	<cfsavecontent variable="content">
	Specified team was not found. Please log into <a href="https://www.thprd.org/teamregistration/"><strong>team registration manager</strong></a> before attempting payment.
     </cfsavecontent>
     <cfinclude template="layout_getleague.cfm">
	<cfabort>
	<cfelseif GetTeam.invoicefacid neq "">
	<cfsavecontent variable="content">
	Specified team was already paid on invoice #GetTeam.invoicefacid#-#GetTeam.invoicenumber#.
     </cfsavecontent>
     <cfinclude template="layout_getleague.cfm">
	<cfabort>
</cfif>

<cfif 0>
	<cfdump var="#GetTeam#" format="text">
</cfif>


<cfsavecontent variable="content">
	
     <br>

Welcome to team registraton payment system. First step, select number of host cards if applicable.<br><br>

<form action="procteam2.cfm" method="post">

<!---
<!--- manage session cookie. needs to be present and match thru system. --->
<cfif IsDefined("cookie.TEAMSESSIONID")>
	<!--- set to cookie sessionid --->
	<input type="hidden" name="currentsessionid" value="#cookie.TEAMSESSIONID#">
<cfelse>
	<!--- create new sessionid and cookie. remove cookie when done. --->
	<cfset tmpsessionid = CreateUUID()>
	<input type="hidden" name="currentsessionid" value="#variables.tmpsessionid#">
	<cfcookie
		name = "TEAMSESSIONID"
		expires = "never"
		secure = "yes"
		value = "#variables.tmpsessionid#">
</cfif>
<!--- end manage session cookie. --->
--->

<input name="currentsessionid" type="hidden" value="#form.currentsessionid#">
<input type="hidden" name="teamid" value="#form.teamid#">
<input type="hidden" name="divisionid" value="#form.divisionid#">
<input type="hidden" name="leagueid" value="#form.leagueid#">

<table>
	<TR>
     	
		<TD >Team ID</TD>
          <td width="50"></td>
		<TD align="right">#form.teamid#</TD>
	</TR>
	<TR>
     	
		<TD>Team Name</TD>
          <td width="50"></td>
		<TD align="right">#GetTeam.teamname#</TD>
	</TR>
	<TR>
     	
		<TD>Fee</TD>
          <td width="50"></td>
		<TD align="right">#decimalformat( GetTeam.leaguefees )#</TD>
	</TR>
	<TR>
     	
		<TD>Plus ghost cards @ #decimalformat( GetTeam.ghostcardfee )# ea</TD>
          <td width="50"></td>
		<TD align="right">
			<select name="ghostcardcount">
				<cfloop from="0" to="#GetTeam.availableghostcards#" step="1" index="g">
					<option value="#variables.g#">#variables.g# </option>
				</cfloop>
			</select>
		</TD>
	</TR>
	<TR>
		<TD colspan="3" align="center">
			<br><input type="submit" value="Continue">
		</TD>
	</TR>
</table>
</form>
</cfsavecontent>
<cfinclude template="layout_getleague.cfm">
</cfoutput>

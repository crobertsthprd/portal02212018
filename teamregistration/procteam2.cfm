<cfset application.dopsds = "dopsds">

<cfoutput>

<CFQUERY name="hasopencall" datasource="#application.dopsds#ro">
	select dops.hasopencall(<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.currentsessionID#"> ) as hasopencall
</CFQUERY>
<cfif hasopencall.hasopencall>
	<CFSAVECONTENT variable="message">
	Has open call.
	</CFSAVECONTENT>
	<cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>

<!---cfinclude template="/common/functions.cfm" 06122017 --->
<cfinclude template="/common/functionsfp.cfm">
<cfinclude template="/common/checkformelements.cfm">

<!--- descope so we can handle URL params --->
<cfquery datasource="#application.dopsds#ro" name="GetTeam">
	SELECT   *
	FROM     dops.trteamview
	WHERE    teamid = <cfqueryparam value="#form.teamid#" cfsqltype="cf_sql_integer" list="no">
	and      divisionid = <cfqueryparam value="#form.divisionid#" cfsqltype="cf_sql_integer" list="no">
	and      leagueid = <cfqueryparam value="#form.leagueid#" cfsqltype="cf_sql_integer" list="no">
</cfquery>

<cfif 0>
	<cfdump var="#GetTeam#" format="text">
</cfif>

<cfif GetTeam.recordcount eq 0>
	<CFSAVECONTENT variable="content">
	Specified team was not found.
	</CFSAVECONTENT>
<cfelseif GetTeam.invoicefacid neq "">
	<CFSAVECONTENT variable="content">
	Specified team was already paid on invoice #GetTeam.invoicefacid#-#GetTeam.invoicenumber#.
     </CFSAVECONTENT>
     <cfinclude template="layout_getleague.cfm">
	<cfabort>
</cfif>


<CFSAVECONTENT variable="content">

     <br>

Please confirm your team info and payment details.<br><br>


<form action="checkoutstepone.cfm" method="post">
<input name="currentsessionid" type="hidden" value="#form.currentsessionid#">
<input name="ghostcardcount" type="hidden" value="#form.ghostcardcount#">
<input type="hidden" name="teamid" value="#form.teamid#">
<input type="hidden" name="divisionid" value="#form.divisionid#">
<input type="hidden" name="leagueid" value="#form.leagueid#">

<cfset startingBalance = GetAccountBalance( cookie.uID )>
<cfset totalFees = GetTeam.leaguefees + GetTeam.ghostcardfee * form.ghostcardcount>
<cfset districtCreditUsed = min( variables.totalFees, variables.startingBalance)>
<cfset amountDue = variables.totalFees - variables.districtCreditUsed>
<input type="hidden" name="startingBalance" value="#decimalformat( variables.startingBalance )#">
<input type="hidden" name="totalFees" value="#decimalformat( variables.totalFees )#">
<input type="hidden" name="districtCreditUsed" value="#decimalformat( variables.districtCreditUsed )#">
<input type="hidden" name="amountDue" value="#decimalformat( variables.amountDue )#">
<input type="hidden" name="otherCreditUsed" value="0.00">
<input type="hidden" name="otherCreditCardID" value="0">
<input type="hidden" name="netDue" value="#decimalformat( variables.amountDue )#">

<table>
	<TR>
		<TD>Team ID</TD>
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
		<TD align="right">#decimalformat( GetTeam.ghostcardfee * form.ghostcardcount )#</TD>
	</TR>
    	<TR>
		<TD COLSPAN="3" align="center"><br></TD>
	</TR>
	<TR>
		<TD align="right"><strong>Total</strong></TD>
          <td width="50"></td>
		<TD align="right" style="border-top: 1px solid Grey;">#decimalformat( GetTeam.leaguefees + GetTeam.ghostcardfee * form.ghostcardcount )#</TD>
	</TR>
	<TR>
		<TD COLSPAN="3" align="center"><br><input type="submit" name="go1" style="width: 155px;" value="Start Checkout"></TD>
	</TR>
</table>

</form>
</CFSAVECONTENT>
<cfinclude template="layout_getleague.cfm">
</cfoutput>

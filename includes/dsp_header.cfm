<CFIF NOT Isdefined("cookie.firstname")>
<CFLOCATION url="/portal/index.cfm?msg=55" addtoken="yes">
</CFIF>

<CFOUTPUT>

<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td  valign="middle"><img src="/portal/images/logothprd2013smallheader.gif"><br />
          <img src="/portal/images/spacer.gif" width="42" height="1" />
          <strong style="background-color:##001346;color:##ffffff;margin-bottom:2px;padding:2px;">myTHPRD - Online Registration</strong>
          
          <CFTRY>
<CFIF structkeyexists(cookie,"expirationdate") and datecompare(cookie.expirationdate,dateadd('d',30,now())) LT 0>
<br /><font color="red"><strong>NOTICE: Your THPRD Card expires on #dateformat(cookie.expirationdate,'mm/dd/yyyy')#.<br />Please renew at any of the district's recreation centers.</strong></font>
</CFIF>
<CFCATCH><CFSET temp="1"></CFCATCH>
</CFTRY></td>
<td align="right" valign="middle">
          <span class="lgnusr">Logged in as <strong>#cookie.firstname# #cookie.lastname#</strong><br />
          Card Number: <strong>#cookie.login#</strong><br />
		<CFIF structkeyexists(cookie,"expirationdate")>Card Expiration: <strong>#dateformat(cookie.expirationdate,"mm/dd/yyyy")#</strong><br></CFIF>
<CFIF structkeyexists(cookie,"districtstatus")>Status: <strong>#cookie.ds#</strong></CFIF></span>
</td>

</tr>
	<tr>
		<td colspan="2" bgcolor="##000000"><img src="#request.imagedir#/spacer.gif" width="1" height="1" border="0" alt=""></td>
	</tr>

</table>
</CFOUTPUT>
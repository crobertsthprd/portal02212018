<CFIF NOT Isdefined("cookie.ufname")>
<CFLOCATION url="/portal/index.cfm?msg=21">
</CFIF>
<CFOUTPUT>

<table width="100%" border="0" cellpadding="0" cellspacing="0">
	<tr>
		<td  valign="middle"><span class="pghdr">myTHPRD Registration Portal</span><CFTRY>
<CFIF Isdefined("cookie.expirationdate") and datecompare(cookie.expirationdate,dateadd('d',30,now())) LT 0>
<br /><font color="red"><strong>NOTICE: Your THPRD Card expires on #dateformat(cookie.expirationdate,'mm/dd/yyyy')#.<br />Please renew at any of the district's recreation centers.</strong></font>
</CFIF>
<CFCATCH><CFSET temp="1"></CFCATCH>
</CFTRY></td>
		<td align="right" valign="middle" style="font-weight:normal;"><span class="lgnusr">Logged in as <strong>#cookie.ufname# #cookie.ulname#</strong></span><br />Card Number: <strong>#cookie.ulogin#</strong><CFIF Isdefined("cookie.expirationdate")><br />
Card Expiration: <strong>#dateformat(cookie.expirationdate,"mm/dd/yyyy")#</strong></CFIF>
<CFIF Isdefined("cookie.ds")><br>
Status: <strong>#cookie.ds#</strong> <CFIF Isdefined("currentsessionid")>| SessionID: #currentsessionid#</CFIF></CFIF><br />
</td>

<!---
<cfif IsDefined("cookie.uid")>
<BR>
<span class="lgnusr">Account Balance: <strong>#dollarformat(GetAccountBalance(cookie.uID))#</strong></span>
</cfif>
--->
</tr>
	<tr>
		<td colspan="2" bgcolor="##000000"><img src="#request.imagedir#/spacer.gif" width="1" height="1" border="0" alt=""></td>
	</tr>
</table>
</CFOUTPUT>

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>


<cfoutput>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Subscription Information</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="0" topmargin="0">



<cfif IsDefined("AcctMode")>
	<input name="AcctMode" type="hidden" value="1">
</cfif>

<table border="0" cellpadding="0" cellspacing="0" width="750">
  <tr>
   <td valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
		
		<td colspan=2 class="pghdr">
			<!--- start header --->
			<CFINCLUDE template="/portalINC/dsp_header.cfm">
			<!--- end header --->
		</td>
			
		<tr>
		
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="/siteimages/spacer.gif" width="130" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap class="lgnusr"><br>
			<!--- start nav --->
			<cfinclude template="/portalINC/admin_nav_history.cfm">
			<!--- end nav --->
			</td>
			</tr>		
			</table>		
		</td>
		
		<td valign=top class="bodytext" width="100%">
		<!--- start content --->
		<table border="0" width="100%" cellpadding="1" cellspacing="0">

	
	<tr>
	<td colspan=11 class="pghdr"><br>E-Subscriptions</td>
	</tr>
	<TR>
		<TD colspan="11">
<CFIF cgi.server_name EQ "dev-www.thprd.org">	 	
Welcome to THPRD E-Subscriptions. Please use your the form below to indicate which THPRD e-newsletters you would like to receive.<br>
<br>
Your e-mail address and personal information is safe with us. We will not share it with anyone else. We may use it occasionally to provide you with information about THPRD programs, activities and events. If at any time you no longer wish to receive such information, you may unsubscribe by following the simple instructions that come with it. We'll remove your e-mail address immediately and subscription account information immediately. If you wish to opt out of all newsletters and other notices simply check the unsubscribe all. Thank you. <br>
	<br>
	<form action="#cgi.script_name#" method="post">
<table>
	
	<tr>
		<td valign="top"><strong>Please send me:</strong> </td>
		<td><input type="checkbox" name="publication" value="District Newsletter" checked> District Newsletter<br>
		<input type="checkbox" name="publication" value="Special Events" checked> Special Events<br>
		<input type="checkbox" name="publication" value="Natural Resources" checked> Natural Resources<br>
		<input type="checkbox" name="publication" value="Classs & Activities" checked> Classs & Activities<br><br>
		</td>
	</tr>
	<tr>
		<td bgcolor="##FFFFCC" valign="middle"><strong>Remove</strong></td>
		<td bgcolor="##FFFFCC" valign="middle"><input type="checkbox" name="remove"> I do not wish to receive any electronic news from THRPD. Please remove me from all such lists.
		</td>
	</tr>
	<tr>
		<td>&nbsp;</td>
		<td ><br><input type="submit" class="form_input" value="Update E-Subscriptions">&nbsp;&nbsp;&nbsp;<input type="button" name="privacy" value="Privacy Policy & Disclaimer" class="form_input">
		</td>
	</tr>
</table>
</form>
<CFELSE>
Coming Soon.		
</CFIF>
			
			
		</TD>

		</tr>
		</table>   
   </td>
  </tr>
  <tr>
   <td colspan="2" valign="top">&nbsp;</td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">

</table>
</body>
</html>
</cfoutput>

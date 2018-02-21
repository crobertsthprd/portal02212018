
<CFPARAM name="confirmmessage" default="">



<cfif structKeyExists(form, "email")>
	<CFQUERY name="lookup" datasource="#application.reg_dsn#">
		select patronlookup from patrons
		where loginemail = '#form.email#'
	</CFQUERY>
	<CFIF lookup.recordcount EQ 1>
<CFMAIL from="Tualatin Hills Park District <webadmin@thprd.org>" to="#form.email#" subject="THPRD ID Lookup">

Dear Patron,

Your THPRD ID is #lookup.patronlookup#

Please click here for more information:
http://www.thprd.org/activities/howtoreg.cfm

If you have any questions, please call (503) 645-6433.
</CFMAIL>
		<CFSET confirmmessage = "Your THPRD ID has been emailed to you.">
	<CFELSE>
		<CFSET confirmmessage = "We could not locate a unique ID associated with the email address #form.email#.">
	</CFIF>
	
</CFIF>

<html>
<head>
<title>Reset Password</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<script language="javascript">
	function validate() {
		if (document.findpw.pID.value == '') { // alert for no ID entered
			alert('Please enter THPRD Card ID.');
			document.findpw.pID.focus();
			return false;
		}	
		return true;
	}	
</script>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<cfoutput>
<body onLoad="document.findpw.pID.focus();">
<form name="mailID" method="post" action="idexplain.cfm">
		<table width="250" cellpadding=1 border=0 cellspacing="0" bgcolor="00000">
			<tr>
			<td valign=top>
				<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="002277">
				<tr>
				<td class="lgnhdr" align=center colspan=3><br><strong>Problem Logging In?</strong><br><br></td>
				</tr>
				<tr>
				<td ><img src="/siteimages/spacer.gif" width="20" height="1" border="0" alt=""></td>
				<td class="lgntext" width=100%>You need to use your current THPRD ID, found on your THPRD card, to login. This ID takes the following format: 3 uppercase letters followed by 6 digits folowed by 1 uppercase letter; for example <strong>SMI090162D</strong> is in the correct format. To protect your privacy and personal information we no longer utilize social security numbers or legacy numbers like A00012345.<br><br>If you do not know your THPRD ID, please call your local recreation center; a <a href="javascript:void(0);" onClick="window.open('http://www.thprd.org/contact/directory.cfm','new', 'scrollbars=yes, toolbars=yes');"  style="text-decoration:underline; color:FFFFCC;"><strong>directory</strong></a> can be found here.<br><br>
				You can also have your current ID sent to you by entering the email address associated with your online account.<br>
				<br><CFIF confirmmessage NEQ ""><font color="yellow"><b>#confirmmessage#</b></font><br><br></CFIF>
				<strong>Email:</strong> <input type="text" name="email" class="form_input" size="15">&nbsp;&nbsp;&nbsp;<input type="submit" value="Send" class="form_input"><br><br>
				</td>
				<td ><img src="/siteimages/spacer.gif" width="20" height="1" border="0" alt=""></td>
				</tr>
				</table>
			</td>
			</tr>
		</table>
	</form>
	</cfoutput>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>


</html>

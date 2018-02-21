<html>
<head>
<title>Reset Password</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<script language="javascript">
	function validate() {
		if (document.sendmypw.un.value == '') { // alert for no email entered
			alert('Please enter your email address.');
			document.sendmypw.un.focus();
			return false;
		}	
		return true;
	}	
</script>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<cfoutput>
<body>
<cfif not isdefined('sendpw')>
	<cfif not isdefined('findPW')>
		<cflocation url="findpw.cfm">
		<cfabort>
	</cfif>
	<cfquery name="qCheckAccount" datasource="#application.reg_dsn#">
		select primarypatronID, pwhint, patronlookup
		from patroninfo
		where (patronlookup = '#ucase(form.pID)#' or oldid = '#ucase(form.pID)#')
		and detachdate is null
	</cfquery>
	<cfif qCheckAccount.recordcount gt 0>
		<form name="sendmypw" method="post" action="#cgi.request_uri#" onSubmit="return validate();" >
		<table width="250" cellpadding=1 border=0 cellspacing="0" bgcolor="00000">
			<tr>
			<td valign=top>
				<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="0048d0">
				<tr>
				<td class="lgnhdr" align=center colspan=2><br><strong>Reset Password</strong><br>
				Security question answers are case sensitive.<br><br></td>
				</tr>
				<tr>
				<td rowspan=3><img src="images/spacer.gif" width="20" height="1" border="0" alt=""></td>
				<td class="lgntext" width=100%>Password Question:<br>
				<cfswitch expression="#qCheckAccount.pwhint#">
					<cfcase value="1"><strong>What is your favorite color?</strong></cfcase>
					<cfcase value="2"><strong>What is your favorite food?</strong></cfcase>
					<cfcase value="3"><strong>What is the name of your first pet?</strong></cfcase>
					<cfcase value="4"><strong>Who was your childhood hero?</strong></cfcase>
					<cfcase value="5"><strong>What is your favorite hobby?</strong></cfcase>
					<cfcase value="6"><strong>What is your favorite sports team?</strong></cfcase>
					<cfcase value="7"><strong>What was your high school mascot?</strong></cfcase>
					<cfcase value="8"><strong>What make was your first car or bike?</strong></cfcase>
					<cfcase value="9"><strong>What was the name of your first school?</strong></cfcase>
				</cfswitch>
				<br><input type="text" name="pAnswer" class="form_input" size=35 maxlength="50"><br></td>
				<td rowspan=3><img src="images/spacer.gif" width="20" height="1" border="0" alt=""></td>
				</tr>
				<tr>
				<td><br><input type="submit" name="sendpw" class="form_submit" value="Reset Password"><br></td>
				</tr>
				</table>
			</td>
			</tr>
		</table>
		<input type="hidden" name="patronlookup" value="#qCheckAccount.patronlookup#">
		<input type="hidden" name="pID" value="#qCheckAccount.primarypatronID#">
	</form>
	<cfelse>
		<cfset msg = "No patron found with the THPRD Card ID entered.">
		<table width="250" cellpadding=1 border=0 cellspacing="0" bgcolor="00000">
			<tr>
			<td valign=top>
				<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="0048d0">
				<tr>
				<td class="lgnhdr" align=center><br><strong>Reset Password</strong><br><br></td>
				</tr>
				<tr>
				<td class="lgntext" width=100% nowrap align=center>#msg#<br><br><br><a href="javascript:history.back();" style="text-decoration:none; color:FFFFFF ">Go Back</a><br><br></td>
				</tr>
				</table>
			</td>
			</tr>
		</table>
		<cfabort>
	</cfif>
<cfelse>
	<cfquery name="qCheckPW" datasource="#application.reg_dsn#" maxrows=1>
		select gender, firstname, loginemail
		from patroninfo
		where (patronlookup = '#ucase(form.patronlookup)#' or oldid = '#ucase(form.patronlookup)#')
		and pwanswer = '#hash(form.pAnswer)#'
		order by relationtype
	</cfquery>
	<cfif qCheckPW.recordcount eq 1>
		<CFIF findnocase("@",qCheckPW.loginemail) EQ 0 OR findnocase(".",qCheckPW.loginemail) EQ 0>
			<cfset msg = "Your email does not appear to be valid and we are unable to send to that address. Please contact <a href='mailto:webadmin@thprd.org'>webadmin@thprd.org</a> for assistance.">
		<CFELSE>
			<cfset pw = hash(lcase(qCheckPW.firstname&'-'&qCheckPW.gender&'-'&form.pAnswer))>
			<cftransaction>
				<cfquery name="qCreateAccount" datasource="#application.reg_dsn#">
					update patrons 
					set password = '#pw#', logindt = null
					where (patronlookup = '#ucase(form.patronlookup)#' or oldid = '#ucase(form.patronlookup)#')
					</cfquery>
			</cftransaction>
			<!--- send message --->
			<cfmail to="#qCheckPW.loginemail#" from="webadmin@thprd.org" subject="Information regarding your account" type="html">
			<font face=arial size=2>
			<strong>Dear Patron</strong>,<br><br>
			Your password for the THPRD Online Services has been reset.
			<br><br>
				Your login ID is the same as the ID on the THPRD card used to create this account.<br><br>
				Your temporary password was reset to the following:<br>
				#lcase(qCheckPW.firstname)#-#lcase(qCheckPW.gender)#-#lcase(form.pAnswer)# <br><br>
				When first logging-in, the password will have to be changed to protect your account.<br><br>Please click here for more information:<br>
				<a href="http://www.thprd.org/activities/howtoregister.cfm">http://www.thprd.org/activities/howtoregister.cfm</a><br><br>
				If you have any questions, please call (503) 645-6433.
			</font>
			</cfmail>
			<cfset msg = "Your password has been reset and emailed.">
		</CFIF>
	<cfelse>
		<cfset msg = "Sorry, that answer is incorrect...">
	</cfif>
		<table width="250" cellpadding=1 border=0 cellspacing="0" bgcolor="00000">
			<tr>
			<td valign=top>
				<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="0048d0">
				<tr>
				<td class="lgnhdr" align=center><br><strong>Reset Password</strong><br><br></td>
				</tr>
				<tr>
				<td class="lgntext" width=100% nowrap align=center>#msg#
					<cfif msg contains 'answer is incorrect'>
						<br><br><br><a href="javascript:history.back();" class="lgntext">Go Back</a><br><br>
					<cfelse>
						<br><br><br><a href="javascript:window.close();" class="lgntext">Close Window</a>&nbsp;&nbsp;&nbsp;<br><br>			
					</cfif>			
				</td>
				</tr>
				</table>
			</td>
			</tr>
		</table>
		<cfabort>
</cfif>
</body>
</cfoutput>

</html>

<cfif not isdefined('findPW')>
	<cflocation url="findpw.cfm">
</cfif><html>
<head>
<title>Reset Password</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<cfoutput>
<body>
<cfquery name="qCheckPW" datasource="#application.reg_dsn#">
	select primarypatronID, pwhint, patronlookup, loginemail, firstname, gender, loginstatus
	from patroninfo
	where (patronlookup = '#ucase(form.pID)#' or oldid = '#ucase(form.pID)#')
	and detachdate is null
</cfquery>


<cfif qCheckPW.recordcount EQ 1>
	<CFSET theEmail = trim(listfirst(qCheckPW.loginemail,";"))>
	
	<CFIF qCheckPW.loginstatus EQ 0>
			<cfset msg = "<strong style='color:orange;'>Web Access Not Configured</strong> - Please close this window and click the <strong style='color:yellow;'>I'm New</strong> link on the portal login page to set up the online portion of your THPRD account.">
	<CFELSEIF NOT IsValid("email",listfirst(trim(theEmail)))>
			<cfset msg = "Your email does not appear to be valid and we are unable to send to that address. Please contact <a href='mailto:webadmin@thprd.org'>webadmin@thprd.org</a> for assistance.">
	<CFELSE>
		<CFSET prehashpw = lcase('#qCheckPW.firstname#-#qCheckPW.gender#-#right(application.IDmaker.randomUUID().toString(), 4)#')>
		<cfset pw = hash(prehashpw)>
		<cftransaction>
			<cfquery name="qCreateAccount" datasource="#application.reg_dsn#">
				update patrons 
				set password = '#trim(pw)#', logindt = null
				where (patronlookup = '#ucase(form.pID)#' or oldid = '#ucase(form.pID)#')
				</cfquery>
		</cftransaction>
		<!--- send message --->
		<cfmail to="#theEmail#" from="Tualatin Hills Park District <webadmin@thprd.org>" subject="Information regarding your account" type="html">
		<font face=arial size=2>
		<strong>Dear Patron</strong>,<br><br>
		Your password for the THPRD Online Services has been reset.
		<br><br>
			Your login ID is the same as the ID on the THPRD card used to create this account.<br><br>
			Your temporary password was reset to the following:<br>
			#prehashpw# <br><br>
			When first logging-in, the password will have to be changed to protect your account.<br><br>Please click here for more information:<br>
			<a href="http://www.thprd.org/activities/howtoregister.cfm">http://www.thprd.org/activities/howtoregister.cfm</a><br><br>
			If you have any questions, please call (503) 645-6433.
		</font>
		</cfmail>
		<cfset msg = "Your password has been reset and sent<br> to the email address associated<br> with your online account.">
	</CFIF>	
<cfelse>
	<cfset msg = "No patron found with the THPRD Card ID entered.">
</CFIF>
	<table width="250" cellpadding=1 border=0 cellspacing="0" bgcolor="000000">
		<tr>
		<td valign=top>
			<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="002277">
			<tr>
			<td class="lgnhdr" align=center><br><strong>Reset Password</strong><br><br></td>
			</tr>
			<tr>
			<td class="lgntext" width=100%  align=center>#msg#
				<cfif msg contains 'answer is incorrect'>
					<br><br><a href="javascript:history.back();" class="lgntext">Go Back</a><br><br>
				<cfelse>
					<br><br><a href="javascript:window.close();" class="lgntext">Close Window</a>	
				</cfif>			
			</td>
			</tr>
			</table>
		</td>
		</tr>
	</table>


</body>
</cfoutput>

</html>

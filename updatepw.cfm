<cfoutput>
<html>
<head>
<title>Please Change Password...</title>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<cfif not isdefined('updatepw')>
	<cfif cookie.loggedin is 'yes'>
		<cfquery name="qCheckLogin" datasource="#application.reg_dsn#">
			select primarypatronID,loginemail
			from patroninfo 
			where patronlookup = '#cookie.ulogin#'
		</cfquery>
	</cfif>
	<body bgcolor="ffffff" topmargin="0" leftmargin="0"  onload="document.updatepw.pw1.focus();">
	<script language="javascript">
		function validate() {
			if (document.updatepw.pw1.value == '') { // alert for no pw1 entered
				alert('Please enter your new password.');
				document.updatepw.pw1.focus();
				return false;
			}
			if (document.updatepw.pw2.value == '') { // alert for no pw2 entered
				alert('Please confirm your new password.');
				document.updatepw.pw2.focus();
				return false;
			}
			if (document.updatepw.pw1.value != document.updatepw.pw2.value) { // alert for pw not matching
				alert('Passwords do not match.');
				document.updatepw.pw1.focus();
				return false;
			}
			return confirm('Password will be case-sensitive.\nClick OK to continue.');
			if (confirm) {
				return true;
			}
		}	
	</script>
<table border="0" cellpadding="0" cellspacing="0" width="750">
  
	<tr>
   <td  colspan="3" valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
		<td>&nbsp;</td>
		<td colspan=2 class="pghdr"><br>Activity Registration Portal</td>
		</tr>		
		<tr>
		<td><img src="images/spacer.gif" width="5" height="400" border="0" alt=""></td>
		<!--- <td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="images/spacer.gif" width="170" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap><br>
			<!--- <a href="javascript:void(0);" class="sidenav">Link 1</a><br> --->
			</td>
			</tr>		
			</table>		
		</td>
		<td valign=top><img src="images/spacer.gif" width="5" height="300" border="0" alt=""></td> --->
		<td valign=top class="bodytext" width="100%" align=center>
		<br><br><br>
	
			<form name="updatepw" method="post" action="/portal/updatepw.cfm" onSubmit="return validate();" >
			<table width="250" cellpadding=1 border=0 cellspacing="0" bgcolor="00000" align=center>
			<tr>
			<td valign=top>
				<table width=100% border=0 cellpadding=1 cellspacing=0 bgcolor="002277">
				<tr>
				<td class="lgnhdr" align=center colspan=3><br><strong>Change Password</strong><br><span class="lgntext">Please change password for your security..</span><br><br></td>
				</tr>
				<tr>
				<td rowspan=3><img src="images/spacer.gif" width="20" height="1" border="0" alt=""></td>
				<td class="lgntext" width=100%><strong>New Password</strong><br><input type="password" name="pw1" class="form_input" size=25><br></td>
				<td rowspan=3><img src="images/spacer.gif" width="20" height="1" border="0" alt=""></td>
				</tr>
				<tr>
				<td class="lgntext" width=100%><br><strong>Confirm Password</strong><br><input type="password" name="pw2" class="form_input" size=25><br></td>		
				</tr>
				<tr>
				<td><br><input type="submit" name="updatepw" class="form_submit" value="Continue"><br><br></td>
				</tr>
				</table>
			</td>
			</tr>
			</table>
			<input type="hidden" name="patronID" value="#qCheckLogin.primarypatronID#">
			<input type="hidden" name="patronemail" value="#qCheckLogin.loginemail#">
			</form>
		</td>
		</tr>
		</table>   
   </td>
   <td><img src="images/spacer.gif" width="1" height="128" border="0" alt=""></td>   
  </tr>
  <tr>
   <td colspan="3" valign="top"><img src="images/spacer.gif" width="1" height="11" border="0" alt=""></td>

  </tr>
<cfinclude template="/portalINC/footer.cfm">  
</table>			
</body>
<cfelse>
	<cfquery name="qUpdatePW" datasource="#application.reg_dsn#">
	update patrons
	set password = '#hash(form.pw1)#', logindt = '#dateformat(now(),'yyyy-mm-dd')# #timeformat(now(),'HH:mm:ss')#'
	where patronlookup = '#cookie.ulogin#'
	</cfquery>


<CFIF trim(form.patronemail) NEQ "" AND findnocase("@",form.patronemail) GT 0>
<CFMAIL to="#form.patronemail#" from="webadmin@thprd.org" subject="THPRD Online Registration: Password Modification">
Hello,

We just wanted to let you know that we have updated your password.
The change was made #dateformat(now(),"dddd mmmm d, yyyy")# at #timeformat(now(),"hh:mm:ss tt")#.

Thanks,
THPRD Online Registration
	</CFMAIL>
</CFIF>

<!--- expire all the cookies --->
<cfcookie name="loggedin" value="pending">
<!--- <cfcookie name="applist" value="" expires="now"> list of user applications --->
<!--- <cfcookie name="toollist" value="" expires="now"> list of user tools --->
<cfcookie name="ufname" value="" expires="now"><!--- first name --->
<cfcookie name="ulname" value="" expires="now"><!--- last name --->
<cfcookie name="ulogin" value="" expires="now"><!--- user ID --->
<cfcookie name="uID" value="" expires="now"><!--- patron ID --->
<cfcookie name="ds" value="" expires="now"><!--- district status --->
<cfcookie name="assmtpicks" value="" expires="now"><!--- assessment picks --->
<cfcookie name="expirationdate" value="" expires="now">
<cfcookie name="uemail" value="" expires="now">
<cfcookie name="authenticate" value="" expires="now">
<cfcookie name="insession" value="" expires="now">
<cfcookie name="sessionid" value="" expires="now">

	<cflocation url="index.cfm?msg=77">
	<cfabort>
</cfif>
</html>
</cfoutput>

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
	<form name="findpw" method="post" action="sendpwnew.cfm" onSubmit="return validate();" >
		<table width="250" cellpadding=1 border=0 cellspacing="0" bgcolor="000000">
			<tr>
			<td valign=top>
				<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="002277">
				<tr>
				<td class="lgnhdr" align=center colspan=3><br><strong>Reset Password</strong><br><br></td>
				</tr>
				<tr>
				<td rowspan=3><img src="/siteimages/spacer.gif" width="20" height="1" border="0" alt=""></td>
				<td class="lgntext" width=100%><strong>THPRD Card ID</strong><br><input type="text" name="pID" class="form_input" size=25><br></td>
				<td rowspan=3><img src="/siteimages/spacer.gif" width="20" height="1" border="0" alt=""></td>
				</tr>
				<tr>
				<td><br><input type="submit" name="findpw" class="form_submit" value="Continue"><br><br></td>
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

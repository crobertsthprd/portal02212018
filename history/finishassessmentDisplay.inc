<!--- start output --->
<CFOUTPUT>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">

<html>
<head>
	<title>Patron Information</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>

<body leftmargin="0" topmargin="0">
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
				</tr>
				<tr>
					<td valign=top>
						<table border=0 cellpadding=2 cellspacing=0>
							<tr>
								<td><img src="images/spacer.gif" width="130" height="1" border="0" alt=""></td>
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
						<table border="0" width="100%" cellpadding="4" cellspacing="0">
						<!--- start content --->
							<TR>
								<TD colspan="11">
								<table width="100%" border="0" cellpadding=1 cellspacing=0>
									<TR>
										<TD class="pghdr">Purchase Assessments</TD>
									</TR>
									<!--- display transaction result --->
									<tr>
										<td><br><CFIF Isdefined("errormessage")>
												<font color="red"><b>#errormessage#</b></font>
											<CFELSE>
												#confirmmessage#
											</CFIF>
						<!--- end content --->
						</table>
					</td>
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
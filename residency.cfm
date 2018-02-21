
<html>
<head>
<title>Tualatin Hills Park and Recreation District </title>
<cfoutput>
<meta http-equiv="Content-Type" content="text/html;">
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" >
<table border="0" cellpadding="0" cellspacing="0" width="750">
  
	<tr>
   <td valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
		<td>&nbsp;</td>
		<td class="orangebig" align=center><img src="/portal/images/logothprd2013.gif"><br>Welcome to the myTHPRD Online Activity Registration System</td>
		</tr>		
		<tr>
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="images/spacer.gif" width="150" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap><br>
			<cfinclude template="/portalINC/admin_nav_login.cfm">
			</td>
			</tr>		
			</table>		
		</td>
		<td valign=top class="bodytext"><br>
			<table width=600 border=0 cellpadding="2" cellspacing="0">
			
			<tr>
			<td colspan=2 class="bodytext">
			<CFSCRIPT>
			pageID = 782;
			page = application.contentpickerportal.pageDetails(pageID,"L","false");
			</CFSCRIPT>
			#page.content#
			<br><br>
			</td>
			</tr>

		</table>   
   </td>
   <td><img src="images/spacer.gif" width="1" height="128" border="0" alt=""></td>   
  </tr>
  <tr>
   <td  valign="top"><p></p></td>
   <td><img src="images/spacer.gif" width="1" height="11" border="0" alt=""></td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">
</cfoutput>
</table>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>

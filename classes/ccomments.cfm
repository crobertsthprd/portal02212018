<!--- switch to slave? --->
<cfquery name="qGetComments" datasource="#application.reg_dsn#">
	SELECT  ClassComments
	FROM  Classes
	WHERE uniqueID = #cID#
</cfquery>

<cfoutput>
<html>
<head>
	<title>View Class Comments</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
	<!--- <CFINCLUDE TEMPLATE="/Thirst/Header.cfm"> --->
</head>

<body topmargin="0" leftmargin="0" marginheight="0">
<TABLE WIDTH="382" cellpadding=1 cellspacing=0>
<tr bgcolor="0048d0">
<td align=center style="color:white;" class="bodytext" colspan=2><strong>View Class Comments</strong></td>
</tr>
<tr>
<td colspan="2" align="right"><img src="#application.webimages#/print.gif" border="0" onMouseup="javascript:window.print();" alt="Print Search Help">&nbsp;<img src="#application.webimages#/close.gif" border="0" onMouseup="javascript:window.close();" alt="Close Window"></td>
</tr>
<TR>
<td>&nbsp;&nbsp;</td>
<TD>
#qGetComments.classComments#
<BR><BR></TD>
</TR>

</TABLE>
</body>
</html>
</cfoutput>
<cfquery name="qGetComments" datasource="#application.reg_dsn#">
	SELECT  classtext
	FROM  Classes
	WHERE uniqueID = #cID#
</cfquery>
<cfparam name="keywords" default="">
<cfset keywordlist = listchangedelims(keywords,' ',',')>
<cfset KeyStringArray = ListToArray(keywordlist," ")>

<cfset newclasstext = qGetComments.classtext>
<cfif keywords is not ''>
	<cfset tempkw = "">
	<cfloop from="1" to="#arraylen(KeyStringArray)#" index="keyword">
		<cfif tempkw is not KeyStringArray[keyword]>
			<cfset newclasstext = replacenocase(newclasstext,'#KeyStringArray[keyword]#','<span class="bodytext_red">#ucase(KeyStringArray[keyword])#</span>','all')>
		</cfif>
		<cfset tempkw = KeyStringArray[keyword]>
	</cfloop>
</cfif>
<cfoutput>
<html>
<head>
	<title>View Class Description</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
	<!--- <CFINCLUDE TEMPLATE="/Thirst/Header.cfm"> --->
</head>

<body topmargin="0" leftmargin="0" marginheight="0">
<TABLE WIDTH="100%" cellpadding=1 cellspacing=0 align="center">
<tr bgcolor="0048d0">
<td align=center style="color:white;" class="bodytext" colspan=2><strong>View Class Description</strong></td>
</tr>
<tr>
<td colspan="2" align="right"><img src="/webimages/print.gif" border="0" onMouseup="javascript:window.print();" alt="Print Search Help">&nbsp;<img src="/webimages/close.gif" border="0" onMouseup="javascript:window.close();" alt="Close Window"></td>
</tr>
<TR>
<td>&nbsp;&nbsp;</td>
<TD class="bodytext">
#newclasstext#
<BR><BR>
<!---
<strong>ID</strong> - In-District Prices<br>

<strong>OD</strong> - Out of District Prices
--->
</TD>
</TR>

</TABLE>
</body>
</html>
</cfoutput>

<cfparam name="QueryClasses" default="">
<CFCONTENT reset="yes" />
<html>
<head>
<title>Tualatin Hills Park and Recreation District</title>

<meta http-equiv="Content-Type" content="text/html;">
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
<table border="0" cellpadding="0" cellspacing="0" width="750">
  
	  <tr>
	   <td colspan="36"><img name="indexcfm_r2_c1" src="/siteimages/main4.jpg" border="0"></td>
	   <td><img src="/siteimages/spacer.gif" width="1" height="100" border="0" alt=""></td>
	  </tr>
  
	
	<tr>
   <td colspan="36" valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
		<td><img src="/siteimages/spacer.gif" width="5" height="300" border="0" alt=""></td>
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="/siteimages/spacer.gif" width="5" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap><br></td>
			</tr>		
			</table>		
		</td>
		<td valign=top><img src="/siteimages/spacer.gif" width="5" height="300" border="0" alt=""></td>
		<td valign=top colspan=2 align=center class="bodytext" width="100%">
		<br>
		<!--- looks for content - displays check back msg if current content not available --->
		<p></p><br>
		<br><br>We're sorry, but an error has occurred on the page you were trying to view.<br><br>
		An email has been sent to the web administrator. You may return to the previous page by
		<a href="javascript:history.go(-1)">clicking here</a>.
		</td>	
		</tr>
		</table>   
   </td>
   <td><img src="/siteimages/spacer.gif" width="1" height="128" border="0" alt=""></td>   
  </tr>
  <tr>
   <td colspan="36" valign="top"><p></p></td>
   <td><img src="/siteimages/spacer.gif" width="1" height="11" border="0" alt=""></td>
  </tr><cfinclude template="/portalINC/footer.cfm">

</table>
</body>
</html>

<!---// Added cfflush so users dont have to wait for the email to be sent before they see their page //--->
<cfflush>
<cfsilent>
	
<cfmail to="webadmin@thprd.org,dhayes@thprd.org" cc="bli@thprd.org" from="webadmin@thprd.org" subject="Error on Website" type="html">
<font size="2" face="Arial, Helvetica, sans-serif">
Error Information<br>
--------------------<br><br>

Erroring Page<br>
-------------<br>
#error.Template#<br><br>

Date of Error<br>
-------------<br>
#dateformat(error.datetime,'mm/dd/yyyy')# - #timeformat(error.DateTime,'hh:mm tt')#<br><br>

Browser<br>
-------------<br>
#error.Browser#<br><br>

Error Details<br>
-------------<br>
User IP: #cgi.REMOTE_ADDR#<br><br>

#error.Diagnostics#<br><br>
#ARGUMENTS.Exception.RootCause#<br><br>

Server Details<br>
--------------<br>
Server IP: #cgi.SERVER_ADDR#<br>
Server Name: #cgi.server_name#<br>
<br>
Request Method: #cgi.REQUEST_METHOD#<br>
<br>
Referring Page: #cgi.HTTP_REFERER#<br>
Query String: #cgi.QUERY_STRING#<br>
<br>
<CFIF Isdefined("cookie.login")>
PatronID = #cookie.login#<br>
<br>
</CFIF>
<hr>
<CFDUMP var="#variables#">

<CFIF Isdefined("form")>
<hr>
<CFDUMP var="#form#">
</CFIF>

<CFIF Isdefined("url")>
<hr>
<CFDUMP var="#url#">
</CFIF>

TimeStamp: <cfif IsDefined("Error.DateTime")>#Error.DateTime#</cfif>
ValidationHeader: <cfif IsDefined("Error.ValidationHeader")>#Error.ValidationHeader#</cfif>
InvalidFields: <cfif IsDefined("Error.InvalidFields")>#Error.InvalidFields#</cfif>
ValidationFooter: <cfif IsDefined("Error.ValidationFooter")>#Error.ValidationFooter#</cfif>
Message: <cfif IsDefined("Error.message")>#error.message#</cfif>
RootCause: <cfif IsDefined("Error.rootCause")>#error.rootCause#</cfif>
Type: <cfif IsDefined("error.type")>#error.type#</cfif>

<cfif IsDefined("DebugText")>Debug Text: #DebugText#</cfif>

This message was sent by #cgi.script_name#.

</font>
</cfmail>  
<CFLOG file="error" application="yes" text="#error.Template# - #error.Diagnostics# (#error.Browser#)">


</cfsilent>
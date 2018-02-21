<CFPARAM name="url.action" default="">
<CFPARAM name="url.portalstatus" default="open">

<CFIF url.action EQ "logout">
	<CFINCLUDE template="/portalINC/logout.cfm">
</CFIF>
<!--- clear all cookies --->
<CFSET cookie.loggedin = "pending">
<html>
<head>
<title>Tualatin Hills Park and Recreation District - myTHPRD Registration Portal</title>
<cfoutput>
<meta http-equiv="Content-Type" content="text/html;">

<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0">
<table border="0" cellpadding="0" cellspacing="0" width="750">
<!--- CFSET undermax = checksessioncount()> --->
<CFSET undermax =  true>

<!--- NOT USED // Alagad change - set this to cache its value, as this is pretty much a list of static message responses 
<cfquery name="qGetMessage" datasource="#application.dsn#" cachedwithin="#createTimeSpan(0,1,0,0)#">
	select   m_status, m_message
	from     th_messages
	where m_id = 2
</cfquery>
//--->


  <tr>
   <td valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
		<td>&nbsp;</td>
		<td class="orangebig" align=center><br>Welcome to the Tualatin Hills Park and Recreation District<br>Online Activity Registration System</td>
		</tr>		
		<tr>
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="/siteimages/spacer.gif" width="150" height="1" border="0" alt=""></td>
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
			<strong>File Unavailable</strong><br>
<br>We're sorry, the page you are looking for<CFIF structkeyexists(url,"page")>, <CFOUTPUT>#url.page#</CFOUTPUT>,</CFIF> either does not exist or is unavailable. Please make sure you have entered the correct URL. 
An email has been sent to the web administrator. <CFOUTPUT>#cgi.server_name#</CFOUTPUT><br><br>
<a href="javascript:history.go(-1);"><< Go Back</a>
			
			</td>
			</tr>
			
				
			
			</td>
			</tr>
			</table>
		</td>
		
   <td><img src="/siteimages/spacer.gif" width="1" height="128" border="0" alt=""></td>   
  </tr>
  <tr>
   <td valign="top"><p></p></td>
   <td><img src="/siteimages/spacer.gif" width="1" height="11" border="0" alt=""></td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">
</cfoutput>
</table>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>

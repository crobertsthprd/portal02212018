<cfoutput>
<cfparam name="footercolor" default="##666666">
  <tr>
  <td colspan="3" align="center" class="greentext" valign="middle" bgcolor="##dddddd">
  <cfif cgi.script_name does not contain '/portal/index.cfm'>
  <strong>To protect your account, please <a href="/portal/index.cfm?action=logout" class="lgnmsg">logout</a> when you are finished.</strong>
  </cfif>
	
	</td>
  </tr>
  <tr>
   <td bgcolor="#footercolor#" colspan="3" align="center" valign="middle" class="navtext" height="23" >
   
   <a class="navtext" href="mailto:webadmin@thprd.org">Web Support</a>&nbsp;&nbsp;|&nbsp;&nbsp;
   <a href="http://www.thprd.org/about/privacy.cfm" class="navtext" target="_blank">Privacy Policy</a>&nbsp;&nbsp;|&nbsp;&nbsp;
   <a href="http://www.thprd.org/contact/directory.cfm" class="navtext" target="_blank">Facility Directory</a>
   </td>
  
  </tr>
    <CFIF cgi.remote_addr EQ application.webmasterIP and structkeyexists(cookie,"uID") and cookie.uID NEQ "">
  <CFQUERY name="getSessionID" datasource="#application.dopsds#">
select   sessiondt,lastactivitydt,primarypatronid
from     sessionpatrons
where    patronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
and      relationtype = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
and sessionid IS NOT NULL
limit    1
</CFQUERY>

  <tr><td colspan="3"><CFDUMP var="#getSessionID#"></td></tr>
  </CFIF>
</cfoutput>
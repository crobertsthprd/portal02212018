<cfoutput>
<cfparam name="footercolor" default="0048d0">
  <tr>
  <td colspan="3" align="right" class="greentext" valign="middle">
  <cfif cgi.script_name does not contain '/portal/index.cfm'>
  <strong>To protect your account, please <cfif cgi.script_name contains '/classes'><a href="/portal/index.cfm?action=logout" class="lgnmsg"><cfelse><a href="/portal/index.cfm?action=logout" class="lgnmsg"></cfif>logout</a> when you are finished.</strong>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
  </cfif>
  	<!--- removed for testing 
	<script src="https://siteseal.thawte.com/cgi/server/thawte_seal_generator.exe"></script>
	--->
	</td>
  </tr>
  <tr>
   <td bgcolor="#footercolor#" colspan="3" align="center" valign="middle" class="navtext" height="23" >
   <cfif cgi.script_name contains '/classes' or cgi.script_name contains '/history'><a href="../main.cfm" class="navtext"><strong>Main Menu</strong></a>&nbsp;&nbsp;|&nbsp;&nbsp;</cfif>
   <a class="navtext" href="mailto:webadmin@thprd.org">Webmaster</a>&nbsp;&nbsp;|&nbsp;&nbsp;
   <a href="http://www.thprd.org/about/privacy.cfm" class="navtext" target="_blank">Privacy Policy</a>&nbsp;&nbsp;|&nbsp;&nbsp;
   <a href="http://www.thprd.org/contact/directory.cfm" class="navtext" target="_blank">Facility Directory</a>
   </td>
  
  </tr>
</cfoutput>
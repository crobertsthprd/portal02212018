<cfoutput>
<cfparam name="footercolor" default="666666">
<CFPARAM name="QueryClasses.dbtime" default="">
  <tr>
  <td colspan="2" class="greentext" style="text-align:center;vertical-align:middle;background:##dddddd">
  <cfif cgi.script_name does not contain '/portal/index.cfm'>
  <strong>To protect your account, please <a href="/portal/index.cfm?action=logout" class="lgnmsg">logout</a> when you are finished.</strong>
  </cfif>
	
	</td>
  </tr>
  <tr>
   <td  colspan="2"  class="navtext" style="text-align:center;vertical-align:middle;height:22px;background:###footercolor#" >
   <cfif cgi.script_name contains '/classes' or cgi.script_name contains '/history'><a href="../main.cfm" class="navtext"><strong>Main Menu</strong></a>&nbsp;&nbsp;|&nbsp;&nbsp;</cfif>
   <a class="navtext" href="mailto:webadmin@thprd.org">Web Support</a>&nbsp;&nbsp;|&nbsp;&nbsp;
   <a href="http://www.thprd.org/about/privacy.cfm" class="navtext" target="_blank">Privacy Policy</a>&nbsp;&nbsp;|&nbsp;&nbsp;
   <a href="http://www.thprd.org/contact/directory.cfm" class="navtext" target="_blank">Facility Directory</a>&nbsp;&nbsp;|&nbsp;&nbsp;
   <a class="navtext" href="javascript:location.reload(true)">Refresh Page</a>
   <CFIF QueryClasses.dbtime NEQ "">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<b style="background-color:##FF9;color:##333;padding:1px;">Current Time: #timeformat(queryclasses.dbtime,"hh:mm tt")#</CFIF>


   </td>
  
  </tr>
    
    
    <tr>
  <td colspan="2">

  </td>
  </tr>
  
</cfoutput>
<cfoutput>
<!---
<span class="lgnusr">Logged in as <strong>#cookie.ufname# #cookie.ulname#</strong><br>
(#cookie.ulogin#)
<br>
Status: <strong>#cookie.ds#</strong><br><br></span>
--->



<!--- <cfif UseNewCodeMethod is 0>
	<span class="sideblack">#listlen(session.uniqueIDclasslist)# class(es) in </span><cfif listlen(session.uniqueIDclasslist) gt 0><A HREF="javascript:void(window.open('../classes/mylist.cfm','','width=650,height=200,statusbar=0,scrollbars=1,resizable=0'))" class="lgnbig"><strong>basket</strong></a><cfelse><span class="sideblack">basket</span></cfif><br>
	<cfif listlen(session.uniqueIDclasslist) gt 0>
	<a href="classbasket.cfm" class="lgnbig"><strong>Check Out</strong></a><br>
	</cfif><br>
</cfif> --->


     

<br />
<!--- start nav --->
<CFINCLUDE template="navlinks.cfm">
<!--- end nav --->




<A HREF="javascript:void(window.open('/portal/searchhelp.cfm?c=5','','width=518,height=355,statusbar=0,scrollbars=1,resizable=0'))" class="lgnbig"><strong>Registration Help</strong></A><br />
<strong class="lgnbig">Video Walkthroughs</strong><br />

 <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=2','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" class="lgnmsg">&nbsp;&bull; Class Search & Checkout</a> <br />
 <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=3','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" class="lgnmsg">&nbsp;&bull; Advanced Search Options</a> <br />
<br>
<a href="../updatepw.cfm" class="sidenav">Change Password</a><br>
<a href="/portal/index.cfm?action=logout" class="sidenav">Logout</a><br><br>
<!---
<a href="https://www.surveymonkey.com/s/2014THPRDWEBSURVEY" class="lgnbig" target="_blank"><strong>Take Our 2014 Survey</strong></a><br>
--->
</cfoutput>
<br />
<!--- <script src="https://siteseal.thawte.com/cgi/server/thawte_seal_generator.exe"></script> --->


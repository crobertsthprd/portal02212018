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

<a href="index.cfm?r=#now()#" class="sidenav">Class Search/<BR>Shopping Cart</a><br><br />
<a href="../main.cfm?DisplayMode=M&t=#datepart('s',now())#" class="sidenav">myTHPRD Homepage</a><br>
<a href="../history/patronhistory.cfm?DisplayMode=M&t=#datepart('s',now())#" class="sidenav">My Household</a><br>
<a href="../history/patronhistory.cfm?DisplayMode=R&t=#datepart('s',now())#" class="sidenav">Current Registrations</a><br>
<a href="../history/dropin.cfm" class="sidenav">Drop-In History</a><br>
<a href="../history/patronhistory.cfm?DisplayMode=I&t=#datepart('s',now())#" class="sidenav">Invoice History</a><br>
<a href="../history/patronhistory.cfm?DisplayMode=P&t=#datepart('s',now())#" class="sidenav">Pass Status</a><br>
<cfif cookie.ds is 'Out of District'>
<a href="../history/patronhistory.cfm?DisplayMode=A&t=#datepart('s',now())#" class="sidenav">Assessments</a><br>
</cfif>
<!---<a href="../history/esubscribe.cfm" class="sidenav">E-Subscriptions</span><br>
<a target="_blank" href="https://www.thprd.org/store/giftcard_home.cfm" class="sidenav">Gift Cards</a><br>--->
<a href="../history/giftcards.cfm" class="sidenav">Gift Cards</a><br>
<a href="/portal/leagues/index.cfm" class="sidenav">Sports League<br />&nbsp;&nbsp;&nbsp;Registration</a><br />
<a href="../history/paybalance.cfm?DisplayMode=A" class="sidenav">Pay Balance</a><br><br />


<table cellpadding="2">
	<tr>
		<td bgcolor="##CC0000">
<a href="/portal/history/ec.cfm" class="sidenav"><font color="white">Emergency Contact &<br />&nbsp;&nbsp;&nbsp;Medical Information</font></a>
</td>
	</tr>
</table>
<br />

<a href="http://www.thprd.org/activities/activityguide.cfm" class="sidenav" target="_blank"><strong>Activities Guide</strong></a><br><br />





<A HREF="javascript:void(window.open('/portal/searchhelp.cfm?c=5','','width=518,height=355,statusbar=0,scrollbars=1,resizable=0'))" class="lgnbig"><strong>Registration Help</strong></A><br />
<strong class="lgnbig">Video Walkthroughs</strong><br />

 <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=2','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" class="lgnmsg">&nbsp;&bull; Class Search & Checkout</a> <br />
 <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=3','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" class="lgnmsg">&nbsp;&bull; Advanced Search Options</a> <br />
<br>
<a href="../updatepw.cfm" class="sidenav">Change Password</a><br>
<a href="/portal/index.cfm?action=logout" class="sidenav">Logout</a><br><br>
<a href="javascript:void(0);" onclick="window.open('http://www.thprd.org/includes/survey.cfm?sID=22','survey22','width=491,height=515,toolbars=no,scrollbars=yes,noresize');"class="lgnbig"><strong>Take Our Survey</strong></a><br>
</cfoutput>
<br />
<!--- <script src="https://siteseal.thawte.com/cgi/server/thawte_seal_generator.exe"></script> --->


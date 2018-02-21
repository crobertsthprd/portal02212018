<CFPARAM name="form.wwwclassid" default="">
<CFPARAM name="form.teamid" default="">
<CFPARAM name="form.deluxepass" default="">

<cfif structKeyExists(form, "pID")>
	<CFINCLUDE template="/portalINC/login.cfm">
	<!--- will redirect to class searcg results if classid is passed in --->
     <CFIF form.wwwclassid NEQ "">
     	<!--- redirect to classID search --->
     	<CFLOCATION url = "/portal/classes/queryclasses.cfm?classlist=#form.wwwclassid#">
     </CFIF>
     <CFIF form.teamid NEQ "">
     	<CFLOCATION url = "/portal/teamregistration/procteam.cfm?t=#form.teamid#&d=#form.divisionid#&l=#form.leagueid#">
     </CFIF>
     <CFIF form.deluxepass NEQ "">
     	<CFLOCATION url = "/portal/passes/passes.cfm">
     </CFIF>
     <!--- check to see if there is a deferral/waitlist/balance dur --->
     <CFQUERY name="open" datasource="dopsds">
	SELECT   *
	FROM     dops.getprimaryregstatus( <CFQUERYPARAM cfsqltype="cf_sql_integer" value="#cookie.primarypatronid#"> )
     WHERE HASBALANCEDUE OR ISBEINGCONVERTED OR ISDEFERRED
	</CFQUERY>
     <CFIF listfind(application.developerip,cgi.remote_addr) AND 1 eq 2>
     	<CFDUMP var="#open#">
          <CFABORT>
     <CFELSE>
    	 	<CFIF open.recordcount GT 0>

               <CFLOCATION url = "/portal/regbaldue/regbaldue1.cfm?curr=true">

          </CFIF>
     </CFIF>
</CFIF>


<cfif NOT structkeyexists(cookie,"loggedin") >
	<cflocation url="index.cfm?msg=888&page=main">
	<cfabort>
</cfif>



<!--- check for internal session --->

<cfif 0>
	<CFDUMP var="#application#">
</cfif>




<cfset sessionvars = getprimarysessiondata( cookie.primarypatronid )>

<cfif sessionvars.facid neq "WWW">
	<cfset msg = "This account is currently in session with an operator at #sessionvars.facname#">
	<!---<cflocation url="/portal/index.cfm?action=logout&sessioncatch=#URLEncodedFormat(variables.msg)#">--->
	
     <CFDUMP var="#sessionvars#">
     
     <cfabort>
</cfif>
<!--- end check for internal session --->



<html>
<head>
<title>Tualatin Hills Park and Recreation District - myTHPRD Registration Portal</title>
<meta http-equiv="Content-Type" content="text/html;">
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
<cfoutput>
<table border="0" cellpadding="0" cellspacing="0" width="750">
  <tr>
   <td valign=top>
   		<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
			<td colspan=2 class="pghdr">
			<!--- start header --->
			<CFINCLUDE template="/portalINC/dsp_header.cfm">
			<!--- end header --->
			</td>
		</tr>
		<tr>
			<td valign=top>
				<table border=0 cellpadding=2 cellspacing=0>
					<tr>
						<td><img src="images/spacer.gif" width="130" height="1" border="0" alt=""></td>
					</tr>
					<tr>
						<td valign=top nowrap class="lgnusr">
						<!--- start nav --->
						<cfinclude template="/portalINC/admin_nav.cfm">
						<!--- end nav --->
						</td>
					</tr>
				</table>
			</td>
			<td valign=top class="bodytext" width="100%">
		<!--- start content --->

          

          <!--- OPEN friday!--->

          <table>
          <tr>
          <td>
          <br>
          <!---
          <h1>Help us serve you better</h1>

To help the THPRD Board of Directors effectively communicate matters of interest to park district residents, please consider taking a <a href="https://www.surveymonkey.com/r/6YJF8V9" target="_blank">brief survey</a>. Not only will you help your elected representatives understand how to keep you informed, you could win a $50 THPRD gift card!
<br><br>
<a href="https://www.surveymonkey.com/r/6YJF8V9" target="_blank" style="font-size:1.3em;color:white;background-color:blue;padding:3px;"><strong>Click here to take the survey.</strong></a><br>
<br>
Or to be reminded about this survey next week, please enter your email:<br>
<br>
<CFIF structkeyexists(form,"remindme")>




          <CFMAIL to="emcclell@thprd.org"  subject="Request to remind patron about Board of Directors survey" type="html" from="webadmin@thprd.org">

          Name: #form.patronname#<br>
          Email: #form.patronemail#<br>

          </CFMAIL>












          <strong style="background-color:##6C3;padding:3px;color:white">Thanks #cookie.ufname#! We will email you a reminder about the survey next week.</strong>


          </div>

          <CFELSE>

          <form action="<CFOUTPUT>#cgi.script_name#</CFOUTPUT>" method="post">
          <input type="hidden" name="remindme" value="true">
          <input type="hidden" name="account" value="#cookie.ulogin#">
          <br>
          <div align="center">
          <table cellpadding="3" style="border:##ccc 1px solid;padding:10px;">
          <tr>
          <td><strong>Name</strong></td>
          <td><input type="text" name="patronName" value="#cookie.ufname# #cookie.ulname#"></td>
          </tr>
          <tr>
          <td><strong>Email</strong></td>
          <td><input type="text" name="patronEmail" value=""></td>
          </tr>
          <tr>
          <td colspan="2" align="center"><br><input type="submit" value="Remind Me"></td>
          </tr>
          </table>
          </div>
          </form>
          </CFIF>

--->

<!---
<div style="background-color:##FF9;border-width:1px;border-color:##000;border-style:solid;padding:5px">Thanks for registering for THPRD fall activities. If you have a moment, please fill out <a href="https://www.surveymonkey.com/r/7PVZHYJ"><strong>this brief survey</strong></a>. As a thank you, you will have a chance to win a $50 gift card to THPRD. <a href="https://www.surveymonkey.com/r/7PVZHYJ"><strong>2017 Fall Registration Survey</strong></a></div>
--->

<h1>Online class registration</h1>

		<div style="border-left-width:1px;border-left-style:dashed;border-left-color:##000000;padding-left:5px;border-top-width:1px;border-top-style:dashed;border-top-color:##000000;padding-top:5px;border-bottom-width:1px;border-bottom-style:dashed;border-bottom-color:##000000;padding-bottom:5px;background-color:##ffffcc;border-right-width:1px;border-right-style:dashed;border-right-color:##000000;padding-right:5px;width:90%;">
         Once your class is in your shopping cart, your spot is reserved!  Just complete your payment within #application.sessionInterval#.  Due to high volume, you may experience a delay in credit card processing during peak registration.
          </div>
		<br>
		<font face=Arial style="font-size:14px;"><strong>Welcome to your online portal for THPRD class registration and activity information!</strong></font> <br>
		<br>In this section of our website, you can:<br><br>

          <table width="90%" border="0">
          <tr>
          <td valign="top" width="50%"><ul style="margin-bottom:0px;padding-bottom:0px;">
			<li><font face=Arial>Search and register for classes & activities</font></li>
			<li><font face=Arial>View current registrations</font></li>
			<li><font face=Arial>View/Print invoices</font></li>
			<li><font face=Arial>View history of Drop-In activity</font></li></ul></td>
          <td valign="top" width="50%">
          	<ul style="margin-bottom:0px;padding-bottom:0px;">
               <li><font face=Arial>View remaining balance of fitness pass(es)</font></li>
			<li><font face=Arial>Check assessment status</font></li>
			<li><font face=Arial>View/Update contact information</font></li>
			<li><font face=Arial>Pay balance on registrations with deposits</font></li>
		</ul>
		</td>
          </tr>
          </table>






<cfset reportds = "dopsdsro">



<cfquery datasource="#variables.reportds#" name="getOpSessions">
	SELECT   sessiondata.sessionid,
	         sessiondata.opdescription,
	         sessiondata.opmode,
	         sessiondata.totalfee,
	         invoicetype.typedescription,
	         sessiondata.dt,
	         sessiondata.comments,
	         sessiondata.patroncomments,
	         sessiondata.email,
	         facilities.name
	FROM     dops.invoicetype invoicetype
	         INNER JOIN dops.sessiondata sessiondata ON invoicetype.typecode=sessiondata.opmode
	         INNER JOIN dops.facilities facilities ON sessiondata.facid=facilities.facid
	where    sessiondata.valid
	and      sessiondata.invoicefacid is null
	and      sessiondata.invoicenumber is null
	and      sessiondata.primarypatronid = <cfqueryparam value="#cookie.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
	order by dt
</cfquery>

<cfif getOpSessions.recordcount gt 0>
	<BR><BR>
	<table width="100%" style="border: ##e6e6e6 solid 1px;">
		<TR>
			<TD colspan="6" align="center" style="border: ##e6e6e6 solid 1px; font-size: 12px; font-weight: 700;">Pending Operations</TD>
		</TR>
		<TR class="DataHeader" align="left">
			<TD>Facility</TD>
			<TD>Description</TD>
			<TD>Issue Date/Time</TD>
			<TD>Comments</TD>
			<TD align="right">Fee</TD>
			<TD style="padding-left: 10px;">Operation</TD>
		</tr>

		<cfloop query="getOpSessions">
			<cfset e = AESencrypt( getOpSessions.sessionid )>
			<!---<cfset e="">--->
			<TR valign="top">
				<TD nowrap>#getOpSessions.name#</TD>
				<TD nowrap title="#getOpSessions.typedescription#">#getOpSessions.opdescription#</TD>
				<TD nowrap>#lCase( datetimeformat( getOpSessions.dt, "mm/dd/yyyy hh:nn:sstt" ) )#</TD>
				<TD>#getOpSessions.comments#</TD>
				<TD align="right">#decimalformat( getOpSessions.totalfee )#</TD>
				<TD style="padding-left: 10px;"><A href="https://www.thprd.org/gpi/ad.cfm?e=#variables.e#&adc=1" target="_blank">Proceed</A></TD>
			</tr>

			<cfif getOpSessions.patroncomments neq "">
				<TR>
					<TD colspan="6">#getOpSessions.patroncomments#</TD>
				</TR>
			</cfif>

		</cfloop>

		<TR>
			<TD colspan="6">&nbsp;</TD>
		</TR>
		<TR>
			<TD colspan="6">Each link above will launch its own window. When finished, return here to log out.</TD>
		</TR>
		<!---<tr>
			<TD colspan="99">
				To process, log out and refer to email that was sent to complete.
			</TD>
		</tr>--->
	</table>
</cfif>








          <h2>Class Deposits</h2>
                              Some classes - including many summer camps - will have an option to pay deposit only instead of the entire registration fee. On the class search results page beneath the
                              list of family members, one will find deposit only pricing details for these classes. <br><br>

                              Please reference this <a href="/portal/images/deposit.jpg"><strong>screen view</strong></a>. This is a mockup of what you find on the <a href="/portal/classes"><strong>class search results page</strong></a>.<br><br>

                              To pay the deposit instead of the full fee, use the class search tool to identify classes by your search criteria. For each class, select the family member(s) for the class that you wish to enroll.
                              Next check '<strong>Enroll as deposit only</strong>' in the orange box. Finally click the
                              Enroll Selected Patron(s) button to move the classes into your shopping cart. Remember that at this point the class is reserved so you can continue browsing for other classes.
                              <br><br>Deposits are non-transferable and non-refundable.





          <!---
		<br>
		<font face=Arial style="font-size:14px;"><strong>Welcome to your online portal for THPRD class registration and activity information!</strong></font> <br>
		<br>In this section of our website, you can:</font>

          <table width="90%">
          <tr>
          <td valign="top" width="50%"><ul>
			<li><font face=Arial>Search and register for classes & activities</font></li>
			<li><font face=Arial>View current registrations</font></li>
			<li><font face=Arial>View/Print invoices</font></li>
			<li><font face=Arial>View history of Drop-In activity</font></li></ul></td>
          <td valign="top" width="50%"><ul><li><font face=Arial>View remaining balance of fitness pass(es)</font></li>
			<li><font face=Arial>Check assessment status</font></li>
			<li><font face=Arial>View/Update contact information</font></li>
			<li><font face=Arial>Pay balance on registrations with deposits</font></li>
		</ul>
		</td>
          </tr>
          </table>
          --->


<h2>Cancellation and Refund Policies</h2>

<h3>Classes</h3>
<ul style="margin-top:0px;padding-top:0px;">

<li>To receive a refund, you'll need to cancel at least five days before the class begins.</li>
<li>If you cancel fewer than five days before the class starts, your refund will be in the form of a THPRD gift card.</li>
<li>If you cancel more than twice in a term (per registrant), a cancellation fee may be assessed.</li>
</ul>

<h3>Camps</h3>
<ul style="margin-top:0px;padding-top:0px;">

<li>Each camp requires a non-refundable deposit of $30 per week; deposits are non-transferable and non-refundable.</li>
<li>A camp must be canceled at least 14 days in advance to ensure refund (minus deposit).</li>
</ul>
               <a href="http://www.thprd.org/activities/registration" target="_blank"> >> Click here to read complete policy.</a>




          <br>
          <!---
          <div style="border-left-width:1px;border-left-style:dashed;border-left-color:##000000;padding-left:5px;border-top-width:1px;border-top-style:dashed;border-top-color:##000000;padding-top:5px;border-bottom-width:1px;border-bottom-style:dashed;border-bottom-color:##000000;padding-bottom:5px;background-color:##FF6;;border-right-width:1px;border-right-style:dashed;border-right-color:##000000;padding-right:5px;width:90%;">
         <strong><u>2014 Website Survey</u></strong><br>THPRD would like to know what you think are the strengths and weaknesses of the current park district website. We are interested in your comments on the full site. Please take a moment to complete <a href="https://www.surveymonkey.com/s/2014THPRDWEBSURVEY" target="_new"><strong>this brief survey</strong></a>. We greatly appreciate your feedback.<br>
<ul>
<li><a href="https://www.surveymonkey.com/s/2014THPRDWEBSURVEY" target="_new"><strong>Click here to take survey</strong></a>
</ul>
          </div>
          <br>--->
		<!---img height=160 alt="" hspace=5 src="photos/outside4.jpg" width=250 align=right vspace=5 border=0--->



			<!---
		<div style="border-left-width:1px;border-left-style:dashed;border-left-color:##000000;padding-left:5px;border-top-width:1px;border-top-style:dashed;border-top-color:##000000;padding-top:5px;border-bottom-width:1px;border-bottom-style:dashed;border-bottom-color:##000000;padding-bottom:5px;background-color:##eeeeee;border-right-width:1px;border-right-style:dashed;border-right-color:##000000;padding-right:5px;width:90%;background:##FFF"></div>--->

<!---
      <strong>Reigistration highlights:</strong>

		<ul>

			<LI>To reserve an available class, select household members to enroll then click "Enroll Selected Patrons" button</li>
			<LI>A shopping cart showing your selected classes will appear above your class search results.</li>
			<LI>To complete the registration process click "Checkout" beneath your shopping cart.</li>
			<LI>Selected classes will be held for #lcase(application.sessionInterval)#, even if you lose your connection.</font></li>
			<LI>If you lose your connection, you may re-connect or speak to an operator during that #lcase(application.sessionInterval)# period to complete the registration/checkout process.</li>
			<li><b><font color="red">Once you have put a class in your basket by clicking the enroll button, the class is reserved on your behalf. Slow processing will NOT cause you to lose a class.</font></b></li>

			<!---<li>Please view our instructional videos: <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=2','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" ><strong>Class Search & Checkout</strong></a> and <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=3','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" ><strong>Advanced Search Options</strong></a></li>--->
		</ul>



		<BR>
--->



		<!---
		<p><strong><font color="red">Notice:</font></strong> The registration portal utilizes first-party cookies. Please confirm your browser security settings permit setting first-party cookies.</p>--->

		<CFIF cgi.server_name EQ "dev-www.thprd.org" and 1 is 1><br>
			<table cellpadding="0" cellspacing="0" border="0" width="99%">
				<tr>
					<td id="alertboxyellow">
						<b>E-Subscriptions</b><br>
						Your e-mail address and personal information is safe with us.
						We will not share it with anyone else.
						We may use it occasionally to provide you with information about THPRD programs, activities and events.
						If at any time you no longer wish to receive such information, you may unsubscribe by following the simple instructions that come with each email.
						We'll remove your e-mail address immediately. Thank you. You may unsubscribe from all THPRD subscription remove your address from all THPRD distribution lists by checking the 'Unsubscribe' button below.
						If at any time you wish to change your subscription preferences click 'E-Subscriptions' in the left hand column.<br><br>
						<div align="center">
						<input type="button" name="unsubscribe" value="Unsubscribe" class="form_input" onClick="confirm('Please unsubscribe me from all THPRD publications and remove my email address from all THPRD distribution lists.');">&nbsp;&nbsp;&nbsp;<input type="button" name="privacy" value="Privacy Policy & Disclaimer" class="form_input">
						</div>
					</td>
				</tr>
			</table>
		</CFIF>

<h2>Suggestions</h2>
In the future, we plan to add additional features to make your online experience with THPRD even better. Please don't hesitate to let us know of ways to improve this system! Have questions or suggestions? Drop us a line <a href="mailto:webadmin@thprd.org" class="lgnmsg"><strong>here</strong></a>.
		<!--- end content --->



		</td>
		</tr>
		</table>
   </td>
  </tr>
  <tr>
   <td colspan="2" valign="top">&nbsp;</td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">

</table>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">

<!---
<SCRIPT>
alert("Once your class is in your shopping cart, your spot is reserved! Just complete your payment within 48 hours. Due to high volume, you may experience a delay in credit card processing during peak registration.");
</SCRIPT>
--->

</body>
</html>
</cfoutput>

<CFIF listfind(application.developerIP,cgi.remote_addr) GT 0>
Developer IP : <CFOUTPUT>#application.developerIP#<br>
Status : #listfind(application.developerIP,cgi.remote_addr)#<br>
Remote: #cgi.remote_addr#<br></CFOUTPUT>
Session INFO: <br>
<CFDUMP var="#getOpSessions#">
<CFQUERY name="open" datasource="dopsds">
SELECT   *
FROM     dops.getprimaryregstatus( <CFQUERYPARAM cfsqltype="cf_sql_integer" value="#cookie.primarypatronid#"> )
</CFQUERY>
HERE:
<CFDUMP var="#open#">

</CFIF>

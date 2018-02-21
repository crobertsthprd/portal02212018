
<html>
<head>
<title>Create New Account</title>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<script language="javascript">
	function validate() {
		if (document.createmyaccount.pID.value == '') { // alert for no id entered
			alert('Please enter THPRD Card ID.');
			document.createmyaccount.pID.focus();
			return false;
		}	
		if (document.createmyaccount.pwhint.selectedIndex == 0) { // alert for no hint selected
			alert('Please choose a password hint.');
			document.createmyaccount.pID.focus();
			return false;
		}	
		if (document.createmyaccount.pAnswer.value == '') { // alert for no answer entered
			alert('Please enter password hint answer.');
			document.createmyaccount.pID.focus();
			return false;
		}
		if (document.createmyaccount.pEmail.value == '') { // alert for no email entered
			alert('Please enter a valid email address.');
			document.createmyaccount.pID.focus();
			return false;
		}
		if (document.createmyaccount.pEmail.value.indexOf ('@',0) == -1 ||
		document.createmyaccount.pEmail.value.indexOf ('.',0) == -1) {
		alert ("\n The Email field requires a \"@\" and a \".\"be used. \n\nPlease re-enter your Email address.")
		document.createmyaccount.pEmail.select();
		document.createmyaccount.pEmail.focus();
		return false;
		}		
		if (document.createmyaccount.pEmail.value != document.createmyaccount.pEmailconfirm.value)
		{
		alert("Email address does not match confirmation.");
		return false;
		}	
			
		return confirm('Please confirm information is correct.');
		if (confirm) {
			return true;
		}
		
	}	
</script>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<cfoutput>
<body topmargin="9" leftmargin="0" marginheight="9" marginwidth="0" onLoad="document.createmyaccount.pID.focus();">
<cfif NOT structkeyexists(form,'pID')>
	<form name="createmyaccount" method="post" action="#cgi.request_uri#" onSubmit="return validate();" >
		<table width="390" cellpadding=1 border=0 cellspacing="0" bgcolor="00000" align=center>
			<tr>
			<td valign=top>
				<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="002277">
				<tr>
				<td class="lgnhdr" align=center colspan=2><br><strong>Create My Web Account</strong><br><br></td>
				</tr>
				<tr>
				<td rowspan=3><img src="images/spacer.gif" width="30" height="300" border="0" alt=""></td>
				<td valign=top width=100%>
					<table border=0 cellpadding=1 cellspacing="0" width=100%>
					<tr>
					<td class="lgntext" valign="top">
						<strong>THPRD Card ID <span class="lgnmsg">*</span> </strong><br><input type="text" name="pID" class="form_input" size=25 maxlength="50"><br>
					</td>
					</tr>
					<tr>
					<td class="lgntext" valign="top"><br>
						<strong>Hint Question</strong><br>
						<select name="pwhint" class="form_input">
						<option selected>Please select...</option>
						<option value="2">What is your favorite food?</option>
						<option value="3">What is the name of your first pet?</option>
						<option value="4">Who was your childhood hero?</option>
						<option value="5">What is your favorite hobby?</option>
						<option value="6">What is your favorite sports team?</option>
						<option value="7">What was your high school mascot?</option>
						<option value="8">What make was your first car or bike?</option>
						<option value="9">What was the name of your first school?</option>
						</select>
						<br>
					</td>
					</tr>
					<tr>
					<td class="lgntext" valign="top"><br>
						<strong>Hint answer</strong><br><input type="text" name="pAnswer" class="form_input" size=35 maxlength=20><br>
						(20 character maximum; alphanumeric characters only)
					</td>
					</tr>
					<tr>
					<td class="lgntext" valign="top"><br>
						<strong>Email address</strong><br><input type="text" name="pEmail" class="form_input" size=40 maxlength=50><br>
						
					</td>
					</tr>
					<tr>
					<td class="lgntext" valign="top"><br>
						<strong>Confirm email</strong><br><input type="text" name="pEmailconfirm" class="form_input" size=40 maxlength=50><br>
                              (THPRD will use this email address for lost passwords, class invoices, and occasional district announcements. You may opt out of district emails on the My Household page.)
					</td>
					</tr>
									<tr>
					<td class="lgntext" valign="top"><br>
						<input type="checkbox" name="newsletter" class="form_input" > <strong>Subscribe to Tualatin Hills Today Newsletter</strong><br>The Tualatin Hills Today is a monthly email newsletter highlighting events and public meetings taking place in the district. 
					</td>
					</tr>
					<tr>
					<td class="lgntext" valign="top" align=center><br><strong>A temporary password will be automatically generated<br>and emailed to the address specified.</strong><br>
					</td>
					</tr>
					
					<tr>
					<td class="lgntext" valign="top">
						<br><input type="submit" name="createaccount" class="form_submit" value="Create My Account">
						<div align="right"><strong><span class="lgnmsg">*</span></strong> - Located on your THPRD Card</div>
					</td>
					</tr>
					</table>
				</td>
				<td rowspan=3><img src="images/spacer.gif" width="15" height="300" border="0" alt=""></td>
				</tr>
				</table>
			</td>
			</tr>
		</table>
	</form>
<cfelse>
      <!--- check email address first --->
      <!-- test -->
	 <CFIF IsValid("email",trim(form.pEmail))>
      	

      <cfquery name="qCheckAccount" datasource="#application.reg_dsn#">
		select primarypatronid, patronlookup, logindt, firstname, gender, loginstatus,lastname
		from patroninfo
		where (patronlookup = '#trim(ucase(form.pID))#' or oldid = '#trim(ucase(form.pID))#')
		and detachdate is null
	</cfquery>
	<cfif qCheckAccount.recordcount gt 0>

		<cfif qCheckAccount.loginstatus is '0'><!--- account has not yet been set up for online registration --->
			<!--- create account --->
			<cfset pw = hash(lcase(qCheckAccount.firstname&'-'&qCheckAccount.gender&'-'&form.pAnswer))>
			<cftransaction>
				<cfquery name="qCreateAccount" datasource="#application.reg_dsn#">
					update patrons 
					set password = '#pw#', loginstatus = '1', loginemail = '#trim(form.pEmail)#', pwhint = '#form.pwhint#', pwanswer = '#hash(lcase(form.pAnswer))#'
					where patronlookup = '#qCheckAccount.patronlookup#'
				</cfquery>
			</cftransaction>
			
			<!--- send message --->
			<CFIF structkeyexists(form,"newsletter")>
			
               
               <!--- OFFLINE
			<CFIF application.serverAddress NEQ application.devIP>

<cfset myCM = createObject("component","wwwcom.campaignmonitor2.subscribers").init(key) />
<Cfset name = "#qCheckAccount.firstname# #qCheckAccount.lastname#">
<cfset listID = "f6a0f0d1669ba4fb0a222acab20dadb9">
<cfset email = "#form.pEmail#">
<CFSET customfields = arraynew(1)>
<CFSET customfields[1] = arraynew(1)>
<CFSET customfields[1][1] = "PrimaryPatronID">
<CFSET customfields[1][2] = "#qCheckAccount.primarypatronid#">
<CFSET customfields[2] = arraynew(1)>
<CFSET customfields[2][1] = "First Name">
<CFSET customfields[2][2] = "#qCheckAccount.firstname#">
<CFSET customfields[3] = arraynew(1)>
<CFSET customfields[3][1] = "Last Name">
<CFSET customfields[3][2] = "#qCheckAccount.lastname#">
<CFSET customfields[4] = arraynew(1)>
<CFSET customfields[4][1] = "Tualatin Hills Today">
<CFSET customfields[4][2] = "yes">
<CFSCRIPT>
//response = myCM.AddSubscriberCustomFields(listID,email,name,customfields);
response = myCM.add_subscriber(listID,email,name);
</CFSCRIPT>
			<CFELSE>
				<CFSET message="Development Server; e-subscriptions offline.">
			</CFIF>
		--->
			
			<cfmail to="e-subscriptions@thprd.org" bcc="webadmin@thprd.org" from="Tualatin Hills Park District <e-subscriptions@thprd.org>" subject="Tualatin Hills Daily New Subscriber Request" type="html">
The following patron has just created an online account.<br>
<br>
#qCheckAccount.firstname# #qCheckAccount.lastname#<br>
Patron Lookup: #qCheckAccount.patronlookup#<br>
Patron PrimaryID: #qCheckAccount.primarypatronid#<br>
Email Address: #form.pEmail#<br>
<br>
This patron indicated they would like to subscribe to Tualatin Hills today.<br>
We have attempted to subscribe the patron. Here is the result:<br><br>


			
			</CFMAIL>
			</CFIF>
			
			<!--- send message --->
			<cfmail to="#form.pEmail#" from="Tualatin Hills Park District <webadmin@thprd.org>" subject="Welcome to THPRD Online Registration" type="html">
			<font face=arial size=2>
			<strong>Dear Patron</strong>,<br><br>
			Your account for the THPRD Online Services has been created.
			<br><br>
			Your login ID is the same as the ID on the THPRD card used to create this account.<br><br>
			Your temporary password is:
			<strong>#lcase("#qCheckAccount.firstname#-#qCheckAccount.gender#-#form.pAnswer#")#</strong><br><br>
			<!---
			<br><br>
			<strong>firstname-gender-answer to password hint</strong><br><br>
			For example, if the <strong>person assigned the THPRD ID number</strong> you used (yourself or maybe a spouse) is a male named Roger with a favorite color of <font color="0000FF">blue</font>,
			the temporary password would be roger-m-blue <strong>(all lower case, with dashes)</strong>.  If the answer to your hint 
			question contains spaces, enter those as well.<br><br>
			--->
			When first logging-in, the password will have to be changed to protect your account.<br><br>Please click here for more information:<br>
			<a href="http://www.thprd.org/activities/howtoregister.cfm">http://www.thprd.org/activities/howtoregister.cfm</a><br><br>
			<CFIF Isdefined("form.newsletter")>
			You have also been subscribed to Tualatin Hills Today. Please configure your email to 'trust' mail sent from e-subscriptions@thprd.org; otherwise it may end up in your junk mail folder.<br>
			<br>
			</CFIF>
			If you have any questions, please call (503) 645-6433.
			
			Thanks,
			THPRD
			</font>
			</cfmail>
			
			<cfset msg = "Your account has been set-up and your temporary password is: #lcase('#qCheckAccount.firstname#-#qCheckAccount.gender#-#form.pAnswer#')#. The temporary password has also been emailed to you.">
		<cfelse>
			<cfset msg = "An account has previously been created.">
		</cfif>
	<cfelse>
		<cfset msg = "No patron found with the THPRD ID entered.">
	</cfif>
     
     <CFELSE>
      	<cfset msg = "The email you entered is not valid.">
     </CFIF>
      
	<table width="390" cellpadding=1 border=0 cellspacing="0" bgcolor="00000" align=center>
	<tr>
	<td valign=top>
		<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="0048d0">

		<tr>
		<td rowspan=2><img src="images/spacer.gif" width="30" height="300" border="0" alt=""></td>
				
		<td class="lgnhdr" align=center valign="top"><br><strong>New Account Status</strong></td>
		<td rowspan=2><img src="images/spacer.gif" width="15" height="300" border="0" alt=""></td>
          </tr>
          <tr>
          <td valign=top width="100%" align="center">
			<table border=0 cellpadding=1 cellspacing="0" width=100%>
			<tr>
			<td class="lgntext" valign="top" align="center"><strong>#msg#</strong><br>
			<cfif msg contains 'No Patron Found' OR msg contains 'not valid'>
				<br><br><a href="javascript:history.back();" class="lgntext"><< Go Back</a><br><br>
			<cfelse>
				<br><br><a href="javascript:window.close();" class="lgntext">Close Window</a>&nbsp;&nbsp;&nbsp;<br><br>			
			</cfif>			
			</td>
			</tr>
			</table>
		</td>
		
		</tr>
		</table>
	</td>
	</tr>
</table>	


</cfif>
</cfoutput>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>


</html>

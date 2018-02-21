<CFPARAM name="url.action" default="">

<CFIF url.action EQ "logout">
	<CFINCLUDE template="/portalINC/logout.cfm">
</CFIF>
<!--- clear all cookies --->
<CFSET cookie.loggedin = "pending">
<html>
<head>
<title>Tualatin Hills Park and Recreation District</title>
<cfoutput>
<meta http-equiv="Content-Type" content="text/html;">
<script language="javascript">
	function validate() {
		if (document.patronlogin.pID.value == '') { // alert for no username entered
			alert('Please enter your THPRD Card ID.');
			document.patronlogin.pID.focus();
			return false;
		}	
		if (document.patronlogin.pw.value == '') { // alert for no pw entered
			alert('Please enter your password.');
			document.patronlogin.pw.focus();
			return false;
		}
		//alert("hello");
		return true;
	}	
</script>
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
			We are excited to offer you the opportunity to register for a variety of recreational activities 24 hours a day, 7 days a week.  If you are new to THPRD programs, please take a moment to review our registration, enrollment, cancellation and refund policies by selecting the links provided.
			<br><br>
			Everyone is welcome to browse our classes.  To register for an activity you will need to have a current THPRD Residency Card.  If you have previously taken classes with THPRD, you probably already have one, please check to see that it has not expired.  To apply for or renew your Residency Card you will need to visit your nearest THPRD facility.
			<br>(See <a href="residency.cfm">Residency Information</a> for more details).
			<br><br>
			The Park District offers In-District residents earlier registration dates and discounted class fees.  Out-of-District residents are required to pay an annual assessment fee to register and participate in THPRD programs.
			<br>(See <a href="regpolicy.cfm">Registration Policy</a> for more details).
			<br><br>
			<!---div align="center" style="border-left-width:1px;border-left-style:dashed;border-left-color:##000000;padding-left:5px;border-top-width:1px;border-top-style:dashed;border-top-color:##000000;padding-top:5px;border-bottom-width:1px;border-bottom-style:dashed;border-bottom-color:##000000;padding-bottom:5px;background-color:##ffffdd;border-right-width:1px;border-right-style:dashed;border-right-color:##000000;padding-right:5px;width:95%;">

      <strong>The class selection process has been updated. Please note changes and instructions after log-in.</strong><br>
	  You may also view these instructional videos: <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=2','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" ><strong>Class Search & Checkout</strong></a> and <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=3','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" ><strong>Advanced Search Options</strong>.
	  </div><br>--->
			</td>
			</tr>
			<tr>
			<td class="bodytext" valign=top>
			<strong>ONLINE REGISTRATION - GETTING STARTED</strong><br>
			<span class="redtext">*</span><strong>Fall registration starting times are:</strong><br>
			In-District - <span class="redtext">9:00 a.m., Saturday, Jan. 9, 2010</span><br> 
			Out-of-District - <span class="redtext">8:30 a.m., Friday, Jan. 16, 2010</span><br>
			<br>
			<strong>Login & Password</strong><br>
			If this is your first time registering online, click on 'I'm New' to create your web account.  Enter the required information and press the 'Create My Account' button. <span class="redtext">(Please use a unique email for each account)</span>.
			A temporary password will be automatically generated and emailed to your specified email address.<br><br> 
			If you are returning to the site and have forgotten your password, click on 'Forgot Password'.
			Enter the required information and your password will be reset and emailed to you.<br><br>
			
			For information on registering via <strong>phone, fax, or in-person</strong>, <br>please click <a href="http://www.thprd.org/activities/howtoregister.cfm" target="_blank"><strong>here</strong></a>.<br><br>
			
			<strong>Browser Security Settings & Cookies</strong><br>
			The registration portal utilizes first-party cookies. Please confirm your browser security settings
			permit setting first-party cookies.
		
			</td>
			<td valign=top>
				<form name="patronlogin" method="post" action="main.cfm" onSubmit="return validate();" >
					<table width="250" cellpadding=1 border=0 cellspacing="0" bgcolor="00000" align=center>
						<tr>
						<td valign=top >
							
							
							<table width=100% border=0 cellpadding=2 cellspacing=0 bgcolor="0048d0">
							<tr>
							<td class="lgnhdr" align=center colspan=2><br><strong>Login to My THPRD<cfif application.productionserver EQ false> - DEV</cfif></strong><br><br> </td>
							</tr>

							<!---
							<CFIF datecompare(now(),'June 9, 2007') LT 0>
								<tr>
									<td colspan=2 align="center">
								<table>
									<tr>
										<td  class="lgntext_yellow"><strong>NOTICE: Due to scheduled maintenance online registration will be unavailable from 8:30 AM To 9:30 AM Wednesday Jan. 9, 2008.<br><br></strong></td>
									</tr>
								</table>
									</td>
								</tr>
							</CFIF>
							---> 
							
							<cfif structKeyExists(url, "msg")>
							<cfoutput>
												
							<tr>
							<td class="lgntext" align=center colspan=2>
							
							<strong>
							<cfswitch expression="#url.msg#">
								<cfcase value="1">
								Your account has been locked
								</cfcase>
								<cfcase value="2">
								Invalid username/password<br>
								</cfcase>
								<cfcase value="4">
								You have been logged out.
								<cfif structKeyExists(url, "logoutmsg") AND url.logoutmsg NEQ "true">
								<BR>#url.logoutmsg#
								</CFIF>
								</cfcase>
								<cfcase value="10">
								Please visit a facility<br>to prove residency status
								</cfcase>
								<cfcase value="11">
								Your THPRD Card is expired
								</cfcase>
								<cfcase value="12">
								Please login with primary<br>
								patron card number
								</cfcase>
								<cfcase value="13">
								Account is currently unavailable.<br>
								Please contact accounting for assistance.
								</cfcase>
								<cfcase value="20">
								Form is not posting. Please check browser settings.<br>
								</cfcase>
								<cfcase value="21">
								Session expired or transferred to THPRD operator - Please log in again<br>
								</cfcase>
								<cfcase value="77">
								Password Updated - Please log in again<br>
								</cfcase>
								<cfcase value="901">
								<CFPARAM name="url.msgtext" default="Unable to Create Session">
								<!---#url.msgtext#--->Your account is currently unavailable.<br>
								 Please try again later.<br>
								</cfcase>
								<cfcase value="888">
								Unable to authenticate credentials.
								<CFMAIL to="webadmin@thprd.org" subject="Secure Login Failure: Unable to authenticate credentials." from="webadmin@thprd.org" type="html">
									<CFDUMP var="#cookie#">
									<CFDUMP var="#form#">
									<CFDUMP var="#cgi#">
								</CFMAIL>
								</cfcase>							
								  
								
								<cfdefaultcase>
								
								</cfdefaultcase>
							</cfswitch>
							</strong>
							<br><br></td>
							</tr>
							</cfoutput>
							</cfif>
							<cfif undermax EQ true> 
								<tr>
								<td rowspan=3><img src="/siteimages/spacer.gif" width="35" height="1" border="0" alt=""></td>
								<td class="lgntext" width=100%><strong>THPRD Card ID</strong>:<br><input type="text" name="pID" class="form_input"><br></td>
								</tr>
								<tr>
								<td class="lgntext" width=100%><strong>Password</strong>
								:<br><input type="password" name="pw" class="form_input" maxlength="200"><br></td>
								</tr>
								  
								<tr>
								<td><input type="submit" name="login" class="form_submit" value="Login"><br></td>
								</tr>

							<cfelse>
								<tr>
								<td rowspan=3><img src="/siteimages/spacer.gif" width="35" height="1" border="0" alt=""></td>
								<td class="lgntext" width=100%><br></td>
								</tr>
								<tr>
								<td class="lgntext" width=100%><strong>Login maximum reached.<br>
								Please try again in a few minutes.
								</strong>
								<input type="hidden" name="pID">
								<input type="hidden" name="pw">
								
								<br></td>
								</tr>
								<tr>
								<td><!--- <input type="submit" name="login" class="form_submit" value="Login"> ---><br></td>
								</tr>
							</cfif> 
							<CFIF cookie.kiosk EQ true>
								<CFSET signuppage = "newuser_kiosk.cfm">
							<CFELSE>
								<CFSET signuppage = "newuser.cfm">
							</CFIF>
							<tr>
							<td class="lgntext" align=center colspan=2><br><a href="javascript:void(0);" onClick="window.open('#signuppage#','newuser', 'width=400, height=475, scrollbars=no, toolbars=no, noresize');" style="text-decoration:none; color:FFFFFF;"><strong>I'm New</strong></a>&nbsp;&nbsp;&##8226;&nbsp;&nbsp;<a href="javascript:void(0);" onClick="window.open('findpw.cfm','sendpw', 'width=270, height=175, scrollbars=no, toolbars=no, noresize');" style="text-decoration:none; color:FFFFFF;">Forgot Password</a><br><a href="javascript:void(0);" onClick="window.open('idexplain.cfm','sendpw', 'width=270, height=450, scrollbars=yes, toolbars=no, noresize');" style="text-decoration:none; color:FFFFFF;"><font color="##FFFF66">Problem Logging In?</font></a><br><br></td>					
							</tr>	
							</table>
   
						</td>
						</tr>
					</table>
				</form>
			
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

<CFPARAM name="url.action" default="">
<CFPARAM name="url.portalstatus" default="open">
<CFPARAM name="suprresslogin" default="false">
<CFPARAM name="url.wwwclassid" default="">
<CFPARAM name="url.leagueid" default="">
<CFPARAM name="url.teamid" default="">
<CFPARAM name="url.divisionid" default="">
<CFPARAM name="url.deluxepass" default="">

<CFIF url.action EQ "logout">
	<CFINCLUDE template="/portalINC/logout.cfm">
</CFIF>
<!DOCTYPE html>
<html class="no-js" lang="en"> 
<head>
<title>Tualatin Hills Park and Recreation District - myTHPRD Registration Portal</title>
<meta charset="utf-8">
<meta http-equiv="X-UA-Compatible" content="IE=edge">
<meta name="description" content="Tualatin Hills Park & Recreation District (THPRD) connects people, parks & nature in Beaverton, Oregon. Learn about the many classes & activities we offer.">
<meta name="keywords" content="Tualatin Hills Park & Recreation District, Online Regisration">


<cfoutput>
<script>
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
<body>
<table style="width:750px;border:none;padding:0px;margin:0px">
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
   <td style="vertical-align:top">
   		<table style="width:749px;border:none;padding:0px;margin:0px">
		<tr>
		<td>&nbsp;</td>
		<td class="orangebig" style="text-align:center;"><img alt="THPRD Logo" src="/portal/images/logothprd2013.gif"><br>Welcome to the myTHPRD Online Activity Registration System</td>
		</tr>		
		<tr>
		<td style="vertical-align:top">
			<table >
			<tr>
			<td><img alt="Spacer" src="/siteimages/spacer.gif" width="150" height="1" ></td>
			</tr>
			<tr>
			<td style="vertical-align:top"><br>
			<cfinclude template="/portalINC/admin_nav_login.cfm">
			</td>
			</tr>		
			</table>		
		</td>
		<td style="vertical-align:top" class="bodytext"><br>
			<table style="width:600px;border:none;padding:0px;margin:0px">
			<tr>
			<td colspan=2 class="bodytext" style="float:left">
               
               		<form name="patronlogin" method="post" action="main.cfm" onSubmit="return validate();" >
                         <input type="hidden" name="wwwclassid" value="#url.wwwclassid#">
                              <input type="hidden" name="teamid" value="#url.teamid#">
                              <input type="hidden" name="leagueid" value="#url.leagueid#">
                              <input type="hidden" name="divisionid" value="#url.divisionid#">
                              <input type="hidden" name="deluxepass" value="#url.deluxepass#">
					<table  style="margin:15px;width:250px;float:right">
						
                              
                              <tr>
						<td style="vertical-align:top" >
							
							
							<table style="margin:15px;background:##002277;padding:2px;width:100%;margin:auto" >
							<tr>
							<td class="lgnhdr" style="text-align:center" colspan=2><br><strong>Login to myTHPRD<cfif application.productionserver EQ false> - DEV</cfif></strong><br> </td>
							</tr>

							<CFIF application.portalstatus EQ "closed" OR application.portalstatus EQ "closurepending">
								<tr>
									<td colspan=2 style="text-align:center">
								
								<table style="width:95%">
									<tr>
										<td  class="lgntext_yellow" style="color:yellow;"><strong><br>#application.closuremessage#<br></strong></td>
									</tr>
								</table>
                                        <script>alert('#application.closuremessage#');</script>
									</td>
								</tr>
							</CFIF>
							
							<cfif structKeyExists(url, "msg")>
							<cfoutput>
												
							<tr>
							<td class="lgntext" style="text-align:center" colspan=2><br>
							
							<strong style="color:##FF0;">
							
                                   <cfswitch expression="#url.msg#">
								<cfcase value="1">
								Your account has been locked
								</cfcase>
								<cfcase value="2">
								Invalid username/password<br>
								</cfcase>
                                        <cfcase value="3">
								Unable to authenticate session. <br>Please login again.<br>
                                        NOTE: This site requires the use of cookies.
                                        <CFTRY>
								<CFSET _cookie = GetHttpRequestData().headers.cookie>
                                        <CFCATCH><CFSET _cookie = "not able to define with GetHTTPRequestData()"></CFCATCH>
                                        </CFTRY>
                                             
                                        <CFMAIL to="webadmin@thprd.org" subject="Error 3 | Secure Login Failure: Unable to authenticate credentials. MSG 3" from="webadmin@thprd.org" type="html">
									Message 3.<br>
                                             <CFDUMP var="#cookie#">
                                             <hr>
									<CFDUMP var="#form#">
                                             <hr>
									<CFDUMP var="#cgi#">
                                             <hr>
                                             <CFDUMP var="#url#">
                                             <hr>
                                             <!---
                                             <CFDUMP var="#client#">
                                             <hr>
									--->
                                             New Cookie:<br>
                                             <CFDUMP var="#_cookie#">
								</CFMAIL>
								</cfcase>
								<cfcase value="33">
								Online account does not exist.<br>To create your account click I'm New.
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
								Your <strong>THPRD account</strong> has <strong>expired</strong>.<br>
                                        <br>
                                        <div style="background-color:##FF6;padding:2px;">
                                        <span style="color:##000;">Please bring the <a target="_blank" href="http://www.thprd.org/activities/create-an-account">required documents</a> to one of our centers so we can verify that your home residence is within district boundaries. </span></a></div>
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
                                        <cfcase value="55">
								Authentication error. Credentials not defined.
                                        <br><strong>NOTE:</strong> This site requires the use of cookies.
                                        <CFSET _cookie = GetHttpRequestData().headers.cookie>
                                        <CFMAIL to="webadmin@thprd.org" subject="Error 55 | Client variable not defined in header" from="webadmin@thprd.org" type="html">
									Message 3.<br>
                                             <CFDUMP var="#cookie#">
                                             <hr>
									<CFDUMP var="#form#">
                                             <hr>
									<CFDUMP var="#cgi#">
                                             <hr>
                                             <CFDUMP var="#url#">
                                             <hr>
                                             <!---
                                             <CFDUMP var="#client#">
                                             <hr>
									--->
                                             New Cookie:<br>
                                             <CFDUMP var="#_cookie#">
								</CFMAIL>
                                        
                                        
                                        
								</cfcase>
								<cfcase value="77">
								Password Updated - Please log in again<br>
								</cfcase>
                                        <cfcase value="1001">
								Illegal operation when attempting to drop class from basket.<br>
								</cfcase>
								<cfcase value="901">
								<CFPARAM name="url.msgtext" default="Unable to Create Session">
								<!---#url.msgtext#--->Your account is currently unavailable.<br>
								 Please try again later.<br>
								</cfcase>
                                        <cfcase value="921">
                                        <CFPARAM name="url.msgtext" default="Currently processing checkout.">
								<!---#url.msgtext#---><div style="padding:10px;" align="left">We are currently completing your checkout. Please try again later. If you need assistance registering for additional classes call the registration hotline 503/439-9400. </div><br>
                                        <script language="javascript">alert('We are currently completing your checkout. Please try again later. If you need assistance registering for additional classes call the registration hotline 503/439-9400.');</script>
								<CFSET suppresslogin = "true">
								</cfcase>
                                        <cfcase value="951">
                                        <CFPARAM name="url.msgtext" default="Currently processing checkout.">
								<!---#url.msgtext#---><div style="padding:10px;" align="left">We are currently completing your checkout. Please try again later. If you need assistance registering for additional classes call the registration hotline 503/439-9400. </div><br>
                                        <script language="javascript">alert("We are currently completing your checkout. Please try again later. If you need assistance registering for additional classes call the registration hotline 503/439-9400.");</script>
								<CFSET suppresslogin = "true">
								</cfcase>
								<cfcase value="888">
								Unable to authenticate credentials.
                                        <CFSET _cookie = GetHttpRequestData().headers.cookie>
								<CFMAIL to="webadmin@thprd.org" subject="Error 888 | Secure Login Failure: Unable to authenticate credentials." from="webadmin@thprd.org" type="html">
									<CFDUMP var="#cookie#">
									<CFDUMP var="#form#">
									<CFDUMP var="#cgi#">
                                             <CFDUMP var="#url#">
                                             <CFDUMP var="#_cookie#">
								</CFMAIL>
								</cfcase>							
								  
								
								<cfdefaultcase>
								
								</cfdefaultcase>
							</cfswitch>
							</strong>
							</td>
							</tr>
							</cfoutput>
							</cfif>
							<cfif (undermax EQ true and application.portalstatus NEQ "closed" and not structkeyexists(url,"msg")) <!---OR listfind(application.developerip,cgi.remote_addr) GT 0 --->> 
								<tr>
								<td rowspan=2><img src="/siteimages/spacer.gif" width="40" height="1"  alt=""></td>
								<td class="lgntext" style="width:100%"><br><strong>THPRD Card ID</strong>:<br><input type="text" name="pID" class="form_input"><br></td>
								</tr>
								<tr>
								<td class="lgntext" style="width:100%"><strong>Password</strong>
								:<br><input type="password" name="pw" class="form_input" maxlength="200"><br></td>
								</tr>
								  
								<tr>
								<td style="text-align:center" colspan="2"><input type="submit" name="login" class="form_submit" value="Login"><br></td>
								</tr>
							<CFELSEIF structkeyexists(url,"msg") >
                                   	<tr>
								<td rowspan=2><img src="/siteimages/spacer.gif" width="35" height="1"  alt=""></td>
								<td class="lgntext" style="width:100%"><br></td>
								</tr>
								<tr>
								<td class="lgntext" style="width:100%"><strong><a style="text-decoration:none;color:##fff;" href="/portal/index.cfm"><< Go to login page.</a></strong></td>
								
								</tr>
								<tr>
								<td><br><br></td>
								</tr>
							<cfelseif undermax EQ false>
								<tr>
								<td rowspan=2><img src="/siteimages/spacer.gif" width="35" height="1" alt=""></td>
								<td class="lgntext" style="width:100%"><br></td>
								</tr>
								<tr>
								<td class="lgntext" style="width:100%"><strong>Login maximum reached.<br>
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
							
							<CFSET signuppage = "newuser.cfm">
							
							<tr>
							<td class="lgntext" style="text-align:center" colspan=2><br><a href="javascript:void(0);" onClick="window.open('#signuppage#','newuser', 'width=400, height=525, scrollbars=no, toolbars=no, noresize');" style="text-decoration:none; color:##FFCC00;"><strong>I'm New</strong></a>&nbsp;&nbsp;&##8226;&nbsp;&nbsp;<a href="javascript:void(0);" onClick="window.open('findpw.cfm','sendpw', 'width=270, height=175, scrollbars=no, toolbars=no, noresize');" style="text-decoration:none; color:##FFFFFF;">Forgot Password</a><br><a href="javascript:void(0);" onClick="window.open('idexplain.cfm','sendpw', 'width=270, height=450, scrollbars=yes, toolbars=no, noresize');" style="text-decoration:none; color:##FFFF66;">Problem Logging In?</a><br><br></td>					
							</tr>	
							</table>
   
   
   
						</td>
						</tr>
                              
                              <tr>
                              <td  style="padding:3px;background:##fff;">
                              <div style="background:##eef;padding:2px;margin-top:5px;"><strong style="text-decoration:underline">IMPORTANT UPDATE: Class Deposits</strong><br>
                              Classes that have a deposit will have an option to pay deposit only (instead of the entire fee) beneath the
                              list of family members for each class entry. Select the family member(s) for the class
                              and then check '<strong>Enroll as deposit only</strong>' in the orange box.</div>
                              
                              
                              <br><strong style="text-decoration:underline">Getting Started</strong><br>
			If this is your first time registering online, click on <strong>I'm New</strong> to create your web account.  Please note that you must already be a member of THPRD and have a userID. Enter the required information and press the 'Create My Account' button. <span class="redtext">(Please use a unique email for each account)</span>.
               <!---
			A temporary password will be automatically generated and emailed to your specified email address.<br><br> 
			If you are returning to the site and have forgotten your password, click on 'Forgot Password'.
			Enter the required information and your password will be reset and emailed to you.<br><br>--->
			
			
               </td>
               </tr>
                              
					</table>
                         </form>
                         
               <!---          
               <h2 style="font-size:1.9em;padding-bottom:0px;margin-bottom:10px">Interested in a Deluxe Pass?</h2>
               <table cellspacing="0" cellpadding="5" >
               <tr style="background:##FFD;">
               <td style="font-size:.9em;" width="100%"><strong>Please Login to purchase</strong> </td>

               </tr>
			<tr style="background:##FFB;">
               <td style="font-size:.9em;">Offering 20% off through January!</td>
               </tr>
               </table>         
			--->
               
               <h2 style="font-size:1.6em;padding-bottom:0px;margin-bottom:10px">Winter 2018 - Registration</h2>
               
               <table style="border-spacing:0px;">
               <tr style="background:##eee;">
               <td style="font-size:.9em;padding:5px;"><strong>In-District</strong></td>
               <td></td>
               <td >Saturday December 9 at 8:00 a.m.</td>
             
               </tr>
               <tr style="background:##ddd;">
               <td style="font-size:.9em;padding:5px;"><strong>Out-of-District</strong></td>
               <td></td>
               <td >Monday December 11 at 8:00 a.m.</td>
               
               </tr>
               </table>               
               
               <!---
			2015 Fall 
			August 15 
			August 17
			--->

			<br>
               
			<!--- Main Content --->
               Thank you for your interest in signing up for THPRD programs.<br>
<br>
To use our online class registration system, you must have an account with THPRD. <a href="http://www.thprd.org/activities/create-an-account" target="_blank" ><strong>Creating an account is easy</strong></a>, and can now be done online. Lowest rates are provided for district residents, who support THPRD programs with property taxes.<br>

<ul>
<li><a href="http://www.thprd.org/activities/am-i-in-district" target="_blank"><strong>Am I in District?</strong></a></li>
</ul>

Once online registration begins (see times above), you can access this system daily, around the clock, to sign up for a variety of recreational programs provided by THPRD.<br>
<br>
Before you register, don't forget to: <br>

<ul>
<li>Login to myTHPRD to make sure your account hasn't expired</li>
<li>Verify that all household members are listed on your account</li>
<li>Review <a href="http://www.thprd.org/activities/registration" target="_blank"><strong>THPRD's refund/cancellation policies</strong></a></li>
</ul>

Changes to your account can be processed by calling at <a href="http://www.thprd.org/facilities/directory/" target="_blank"><strong>any THPRD facility</strong></a> prior to registration.

Having trouble? You can also register by phone (503-439-9400) or visit any THPRD facility. We accept MasterCard, Visa and Discover cards, as well as cash, checks and THPRD gift cards.
			</td>
			</tr>
			<tr>
			<td class="bodytext" style="vertical-align:top">
			
			
               
               <!---
               <div style="background:##FF6;border: ##999 1px dashed;padding:5px;margin-right:20px;"><strong>New Cancellation & Refund Policies</strong><br>
               <ul>
               <li>Changes effective June 1, 2015.
               <li>To receive a refund in the same method that you paid, you'll need to cancel <strong>at least five days</strong> before the class begins.
 			<li>If you choose to cancel <strong>fewer than five days</strong> before the class starts, your refund will be in the form of a <strong>THPRD gift card</strong>.
               <li>If you <strong>cancel more than twice</strong> in a term (per registrant), a cancellation fee may be assessed.
			<li>Deposits for camps are $30/week and non-transferable. 
               </ul>
               <a href="http://www.thprd.org/cancellation-policy" target="_blank">Click here to read complete policy.</a>
               </div>
			<br>
			--->
			
               
			<br>
               <div style="background:##FCC;border: ##999 1px dashed;padding:5px;margin-right:20px;">
			<strong style="text-decoration:underline">Browser Security Settings & Cookies</strong><br>
			Please confirm your browser security settings permit the use of cookies.</div>
		
			</td>
			<td style="vertical-align:top">
               
               
               
				
			
			</td>
			</tr>
			</table>
		</td>
		
   
  </tr>
  <tr>
   <td style="vertical-align:top"><p></p></td>
   <td><img src="/siteimages/spacer.gif" width="1" height="11"  alt=""></td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">
</cfoutput>
</table>
</td>
</tr>
</table>

<CFINCLUDE template="/portalINC/googleanalytics.cfm">




</body>
</html>


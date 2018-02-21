<CFLOCATION url="searchhelp.cfm">
<cfoutput>
<cfparam name="c" default="5"><!--- determine which category to show (5 is all) --->
<html>
<head>
	<title>Class Search / Registration Help</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
	<!--- <CFINCLUDE TEMPLATE="/Thirst/Header.cfm"> --->
</head>
<body topmargin="0" leftmargin="0" marginheight="0">
<TABLE WIDTH="500" cellpadding=1 cellspacing=0>
<tr bgcolor="0048d0">
<td align=center style="color:white;" class="bodytext" colspan=2><strong>Class Search / Registration Help</strong></td>
</tr>
<tr>
<td colspan="2" align="right"><img src="../photos/print.gif" border="0" onMouseup="javascript:window.print();" alt="Print Search Help">&nbsp;<img src="../photos/close.gif" border="0" onMouseup="javascript:window.close();" alt="Close Window"></td>
</tr>
<TR>
<td>&nbsp;&nbsp;</td>
<TD>
<ul>
<cfswitch expression="#c#">
	<cfcase value="1,2">
		<li><strong>Search Classes/Activities</strong><br>Our Detailed Activity/Class Search page allows you to locate your desired class(es) in many ways.  You can search by Class Number, Class Title, or any Keyword in the description of the class.  You can also search by Category, Facility, Instructor, Time, Day, Age or any combination.  Enter your search criteria and press: 'Search for Classes'.  
		<br><br>
		From the Activity/Class Search Results Page you will be able to review the class list to confirm dates, times, facilities and fees.  To add/remove any desired classes to 'Your Registration Basket', simply click the checkbox located at the right of each class title.
		<br><br>
		You can return to the 'Class Search' page by clicking on 'New Search' or complete your registration by clicking on 'Register', located on the top of each Search Results page.
		<br><br>
		<strong>If a class is full and you would like to be added to the waitlist,<br> please call (503) 439-9400 to register.</strong>
		<br><br>
		<span class="greentext"><strong>Technical note:</strong></span><br>
		After 30 minutes of inactivity, your 'Class Registration Basket' will be emptied and you will be returned to the main 'Class Search' page.</li>
		<br><br>
	</cfcase>
	<cfcase value="3">
		<li><strong>Activity Registration Check-Out</strong><br>
		From this page you can add participants or remove any unwanted classes by clicking the 'Remove' icon located at the right of each class entry.  You can also return to the 'Class Search' page to add additional classes and update your basket.<br>
		<br>
		To select or unselect a participant, simply press your cntrl key and click the desired person.<br><br>
		<li><strong>Checkout</strong><br>
		Payment:  Enter your credit card information and click 'Check Out' to complete the registration process.  MasterCard, Visa and Discover are accepted.<br><br>When registering for classes online you must pay your full balance at the time of checkout.  Any credits on your THPRD account will be used towards your class registrations.  If you do not want to use a credit card, you may visit any THPRD facility to register.
		<br><br>
		Press 'Checkout' to process your enrollments and payment.  A printable receipt will be available on screen.  Print a copy of the receipt, you will not be mailed an additional confirmation for online registrations.
		<br><br>
		Please be sure to complete the checkout process when registering for any classes.  If you do not complete the checkout process, you will not be registered for any class(es) and your account will not be charged.
		<br><br>
		<strong>If a class is full and you would like to be added to the waitlist,<br> please call (503) 439-9400 to register.</strong>
		<br><br>
		To cancel a class that you registered for online, you must call or visit your nearest THPRD facility for assistance.
		<br><br>
		If you encounter any problems or have any questions on the online registration process, please call Information Services @ (503) 645-6433, during regular office hours or email <a href="mailto:websupport@thprd.org?subject=Online Registration Question">web support</a>.  If you have questions about specific classes, please contact the <a href="http://www.thprd.org/contact/facdir.cfm" target="_blank">facility</a> offering the program.
		</li>
	</cfcase>
	<cfcase value="5">
		<li><strong>Search Classes/Activities</strong><br>Our Detailed Activity/Class Search page allows you to locate your desired class(es) in many ways.  You can search by Class Number, Class Title, or any Keyword in the description of the class.  You can also search by Category, Facility, Instructor, Time, Day, Age or any combination.  Enter your search criteria and press: 'Search for Classes'.  
		<br><br>
		From the Activity/Class Search Results Page you will be able to review the class list to confirm dates, times, facilities and fees.  To add any desired classes to 'Your Registration Basket', simply click the 'Add' icon located at the right of each class title.
		<br><br>
<!--- 		<span class="redtext">Online registration is not available the first 2 days of <br>phone-in registration for the next term</span></li>
		<br><br>
 --->		You can return to the 'Class Search' page by clicking on 'New Search' or complete your registration by clicking on 'Register', located on the top of each Search Results page.
		<br><br>
		<strong>If a class is full and you would like to be added to the waitlist,<br> please call (503) 439-9400 to register.</strong>
		<br><br>
		<span class="greentext"><strong>Technical note:</strong></span><br>
		After 30 minutes of inactivity, your 'Class Registration Basket' will be emptied and you will be returned to the main 'Class Search' page.</li>
		<br><br>
		<li><strong>View Class Registration Basket</strong><br>From the 'Choose Participant List' for each class, select the family member(s) you wish to enroll in that class.  If you choose not to register for any class, simply leave the 'Select None' on the Participant List.  Press the 'Continue' button to complete your registration.</li>
		<br><br>
		<li><strong>Activity Registration Check-Out</strong><br>
		From this page you can remove any unwanted classes by clicking the 'Remove' icon located at the right of each class entry.  You can also return to the 'Class Search' page to add additional classes and update your basket.</li>
		<br><br>
		Payment:  Enter your credit card information and click 'Check Out' to complete the registration process.  MasterCard, Visa and Discover are accepted.<br><br>When registering for classes online you must pay your full balance at the time of checkout.  Any credits on your THPRD account will be used towards your class registrations.  If you do not want to use a credit card, you may visit any THPRD facility to register.
		<br><br>
		<li><strong>Checkout</strong><br>
		Press 'Checkout' to process your enrollments and payment.  A printable receipt will be available on screen.  Print a copy of the receipt, you will not be mailed an additional confirmation for online registrations.
		<br><br>
		Please be sure to complete the checkout process when registering for any classes.  If you do not complete the checkout process, you will not be registered for any class(es) and your account will not be charged.
		<br><br>
		To cancel a class that you registered online, you must call or visit your nearest THPRD facility for assistance.
		<br><br>
		If you encounter any problems or have any questions on the online registration process, please call Information Services @ (503) 645-6433, during regular office hours or email <a href="mailto:websupport@thprd.org">websupport@thprd.org</a>.  If you have questions about specific classes, please contact the <a href="http://www.thprd.org/contact/facdir.cfm" target="_blank">facility</a> offering the program.
		</li>
	</cfcase>
</cfswitch>
</ul>
<BR><BR>
</TD>
</TR>
</TABLE>
</cfoutput>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>

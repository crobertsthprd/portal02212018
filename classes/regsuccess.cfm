<CFSILENT>
<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3&page=regsuccess">
</cfif>
</CFSILENT>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Tualatin Hills Park and Recreation District</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body leftmargin="0" topmargin="0">
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
			
		<tr>
		
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="/siteimages/spacer.gif" width="130" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap class="lgnusr"><br>
			<!--- start nav --->
			<cfinclude template="/portalINC/admin_nav_classes.cfm">
			<!--- end nav --->
			</td>
			</tr>		
			</table>		
		</td>
		
		<td valign=top class="bodytext" width="100%">
		<!--- start content --->
		<table border="0" width="100%" cellpadding="1" cellspacing="0">

			<tr>
				<td  class="pghdr"><br>Registration Completed</td>
			</tr>	

			<tr>
				<td>Your invoice number for this transaction is <b><cfoutput>#replacenocase(localfac,"'","","all")#-#NextInvoice#</cfoutput></b>.<br>You will receive an Email receipt within 2 hours.To return to the main menu, please click <a href="../main.cfm">here</a>.<br><br>
			<strong><font color="red">NOTE: All cancellations must be made in person or by phone.<br> 
			Please call or visit the appropriate facility hosting the class or activity to process the cancellation.</font></strong>
			<br><br>
           <!---    
          <div style="border-left-width:1px;border-left-style:dashed;border-left-color:#000000;padding-left:5px;border-top-width:1px;border-top-style:dashed;border-top-color:#000000;padding-top:5px;border-bottom-width:1px;border-bottom-style:dashed;border-bottom-color:#000000;padding-bottom:5px;background-color:#FFFF99;border-right-width:1px;border-right-style:dashed;border-right-color:#000000;padding-right:5px;width:90%;">
         <strong style="font-size:14px;">2012 Summer Registration Survey</strong><br>At THPRD, we are continually striving to improve our program registration process. In that spirit, we value your input in making changes that will benefit you. Please take a moment to take this <a style="text-decoration:none;" target="_blank" href="https://www.surveymonkey.com/s/X7DTQMG" ><strong>short survey</strong></a> to help us serve you better. We appreciate your time!<ul>
         <li ><a target="_blank" href="https://www.surveymonkey.com/s/X7DTQMG" style="text-decoration:none;" ><strong >Registration Survey</strong></a>. 
         </li>
         </ul> 
          </div>
		--->
		
			</td>
			</tr>	

	

	
		</table>
		
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

</body>

</html>


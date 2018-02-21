<!--- turn page off 03/09/2015 --->
<CFLOCATION url="main.cfm">

<cfif structKeyExists(form, "pID")>
	<CFINCLUDE template="/portalINC/login.cfm">
     
</CFIF>


<cfif NOT structkeyexists(cookie,"loggedin") >
	<cflocation url="index.cfm?msg=888">
	<cfabort>
</cfif>
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
			<td valign=top class="bodytext" width="100%" style="padding-left:20px;">
		<!--- start content --->
          
          <br><h1>It's our 60th anniversary!</h1>
          
          <p>To celebrate we want to give YOU the chance to win a $60 THPRD Gift Card. To enter the drawing, please tell us your name and email (so we know how to contact you when you win!).</p>
          
          <CFIF structkeyexists(form,"promoSignUp")>
          
          <CFPARAM name="cookie.promo60" default="false">
          
          <CFIF cookie.promo60 EQ "false">
          <CFMAIL to="webadmin@thprd.org" bcc="webadmin@thprd.org" subject="Online Spring Registration - THPRD 60th Anniversary Promo Signup" type="html" from="webadmin@thprd.org">
          
          Name: #form.patronname#<br>
          Email: #form.patronemail#<br>
          Social Media: #form.socialmedia#<br>
          <br>
          Account: #form.account#
          
          </CFMAIL>
          
          </CFIF>
          
          <CFQUERY name="insertPromo" datasource="#application.contentds#">
          	insert into promo60
               (patronname,patronemail,patronaccount,socialmedia)
               VALUES
               (<CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.patronname#">,
               <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.patronemail#">,
               <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.account#">,
               <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.socialmedia#">)
               
          </CFQUERY>
          
          
          
          <CFSET cookie.promo60 = "true">
          
          <br>
          <div align="center">
          
          <div style="width:400px;border:##ccc 1px solid;padding:10px;text-align:left;"><strong>#cookie.firstname#, thanks for your entry!</strong> Keep up with us on <a href="https://www.facebook.com/THPRD" target="_blank"><strong>Facebook</strong></a> or <a href="https://twitter.com/THPRD" target="_blank"><strong>Twitter</strong></a> for more promotions, contests and giveaways - we're celebrating our 60th anniversary all year!</div>
          </div>
          
          </div>
          
          <CFELSE>
          
          <form action="#cgi.script_name#" method="post">
          <input type="hidden" name="promoSignUp" value="true">
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
          <td><strong>Favorite Social Media Network</strong></td>
          <td><select name="socialmedia">
          		<option> </option>
          		<option>Facebook</option>
                    <option>Twitter</option>
                    <option>Instagram</option>
                    <option>Google+</option>
                    <option>Pinterest</option>
                    <option>SnapChat</option>
                    <option>Tumblr</option>
              </select>
          </td>
          </tr>
          <tr>
          <td colspan="2" align="center"><br><input type="submit" value="Enter Drawing!"></td>
          </tr>
          </table>
          </div>
          </form>
          </CFIF>
          

          
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
</body>
</html>
</cfoutput>
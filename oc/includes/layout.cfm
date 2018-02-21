<!--- the include is used by oc checkout--->

<cfquery name="Patron" datasource="#application.dopsds#">
	select   primarypatronID,
	         patronlookup,
	         firstname,
	         lastname,
	         indistrict,
	         loginstatus,
	         detachdate,
	         loginemail,
	         relationtype,
	         logindt,
	         insufficientID,
	         verifyexpiration,
	         locked
	from     dops.patroninfo
	where    ( patronlookup = <cfqueryparam value="#lTrim( rTrim( ucase( cookie.login ) ) )#" cfsqltype="cf_sql_varchar" list="no"> )
	and      loginstatus = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
	and      detachdate is null
</cfquery>

<CFPARAM name="patron.indistrict" default="">
<CFPARAM name="patron.firstname" default="">
<CFPARAM name="patron.lastname" default="">
<CFPARAM name="patron.patronlookup" default="">
<CFPARAM name="patron.detachdate" default="">
<CFPARAM name="nobackbutton" default="false">
<CFOUTPUT>
     <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
     <html>
     <head>
     <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
     <meta http-equiv='cache-control' content='no-cache'>
	<meta http-equiv='expires' content='0'>
	<meta http-equiv='pragma' content='no-cache'>
     <title>Tualatin Hills Park & Recreation District</title>
     <link rel="stylesheet" href="css/thprdstyles_min.css">
     <script src="https://code.jquery.com/jquery-1.9.1.min.js"></script>
     </head>
     <body bgcolor="##ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
     <table border="0" cellpadding="0" cellspacing="0" width="750">
          <tr>
               <td valign=top><table border=0 cellpadding=2 cellspacing=0 width=749>
                         <tr>
                              <td colspan=3 class="pghdr"><CFIF patron.indistrict EQ false>
                                        <CFSET ds="Out of District">
                                        <CFELSEIF patron.indistrict EQ true>
                                        <CFSET ds="In District">
                                   </CFIF>
                                   <table width="100%" border="0" cellpadding="0" cellspacing="0">
                                        <tr>
                                             <td  valign="middle"><span class="pghdr">myTHPRD Registration Portal</span></td>
                                             <td align="right" valign="middle" style="font-weight:normal;"><span class="lgnusr">Logged in as <strong>#patron.firstname# #patron.lastname#</strong></span><br />
                                                  Card Number: <strong>#patron.patronlookup#</strong>
                                                  <CFIF patron.detachdate NEQ "">
                                                       <br />
                                                       Card Expiration: <strong>#dateformat(patron.detachdate,"mm/dd/yyyy")#</strong>
                                                  </CFIF>
                                                  <CFIF Isdefined("ds")>
                                                       <br>
                                                       Status: <strong>#ds#</strong>
                                                  </CFIF>
                                                  <br /></td>
                                        </tr>
                                        <tr>
                                             <td colspan="2" bgcolor="##000000"><img src="images/spacer.gif" width="1" height="1" border="0" alt=""></td>
                                        </tr>
                                   </table></td>
                         </tr>
                         <tr>
                              <td valign=top><table border=0 cellpadding=2 cellspacing=0>
                                        <tr>
                                             <td><img src="images/spacer.gif" width="130" height="1" border="0" alt=""></td>
                                        </tr>
                                        <tr>
                                             <td valign=top nowrap class="lgnusr"><br></td>
                                        </tr>
                                   </table></td>
                              <td valign=top colspan=2 class="bodytext" align=left><table border="0" width=730 cellpadding="2" cellspacing="1">


                                        <TR>
                                             <td class="bodytext" colspan="8">

                                             <!--- add wizard steps --->
                                             <br><span class="pghdr">Gift Card Reload - Checkout</span><br>
                                             <hr color="##f58220" width=100% align="center" size="5px">


                                             <CFPARAM name="currentstep" default="5">
                                             <CFPARAM name="headertitle" default="Make Payment">

                                             <div align="center"><CFINCLUDE template="../wizardsteps.cfm"></div>



                                                  <br><span class="pghdr"><CFOUTPUT>#headertitle#</CFOUTPUT></span><br><br>
                                                  <CFIF Isdefined("maincontent")>
                                                  	#maincontent#
                                                  </CFIF>


                                                  <CFIF Isdefined("message")>
#message#
                                                       <CFIF NOT nobackbutton>
                                                            <br>
                                                            <a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>
                                                       </CFIF>
                                                       <div style="height:200px;"></div>
                                                  </CFIF>
                                                  <CFIF Isdefined("successmessage")>
                                                       #successmessage#<br>
                                                  </CFIF>
                                                  
                                                  <div style="height:50px"></div>
                                                  
                                                  </TD>
                                        </TR>
                                        <CFIF not structkeyexists(variables,"successmessage")>
                                             <TR>
                                                  <td colspan="8" align="center"><hr color="##f58220" width=100% align="center" size="5px"></TD>
                                             </TR>
                                        </CFIF>
                                   </table></td>
                         </tr>
                    </table></td>
          </tr>
          <tr>
               <td colspan="3"><img src="images/spacer.gif" width="1" height="11" border="0" alt=""></td>
          </tr>
          <tr>
               <td colspan="3" align="center" class="greentext" valign="middle" bgcolor="##dddddd"><strong>To protect your account, please <a href="/portal/index.cfm?action=logout" class="lgnmsg">logout</a> when you are finished.</strong></td>
          </tr>
          <tr>
               <td bgcolor="##666666" colspan="3" align="center" valign="middle" class="navtext" height="23" ><a href="/portal/main.cfm" class="navtext"><strong>Main Menu</strong></a>&nbsp;&nbsp;|&nbsp;&nbsp; <a class="navtext" href="mailto:webadmin@thprd.org">Web Support</a>&nbsp;&nbsp;|&nbsp;&nbsp; <a href="http://www.thprd.org/about/privacy.cfm" class="navtext" target="_blank">Privacy Policy</a>&nbsp;&nbsp;|&nbsp;&nbsp; <a href="http://www.thprd.org/contact/directory.cfm" class="navtext" target="_blank">Facility Directory</a></td>
          </tr>
     </table>
     <!---
     <a href="testjs.cfm" target="bridgepay">New window</a>
     <form action="formtest.cfm" name="testform">
     <input type = "submit">
     </form>
	--->
     </CFOUTPUT>
     <script>
	    $(document).ready(function () {

  $.ajaxSetup({ cache: false }); // cache problems on mobile

  $('#go1').click(function () {
    var statusDisplay = $('#launchBP');
    statusDisplay.html("<img src='/common/img/gears.gif' style='align:middle;padding-bottom:10px;'><br><strong>Currently awaiting response from processor.<br>Please be patient.</strong>");
    document.f.submit();
  });

	    });

	</script>
     </body>
     </html>

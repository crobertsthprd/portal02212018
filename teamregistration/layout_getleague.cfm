<cfif NOT structkeyexists(cookie,"uID")>
     <cflocation url="../index.cfm?msg=3&page=checkoutstepone">
     <cfabort>
</cfif>

<!--- check open call
<CFINCLUDE template="/portalINC/checkopencall.cfm">
--->



<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta http-equiv='cache-control' content='no-cache'>
<meta http-equiv='expires' content='0'>
<meta http-equiv='pragma' content='no-cache'>
<title>Tualatin Hills Park & Recreation District</title>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
<link type='text/css' href='/portal/jquery/css/demo.css' rel='stylesheet' media='screen' />
<link type='text/css' href='/portal/jquery/css/basic.css' rel='stylesheet' media='screen' />

</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
<cfoutput>


<table border="0" cellpadding="0" cellspacing="0" width="750">
<tr>
<td valign=top>
<table border=0 cellpadding=2 cellspacing=0 width=749>
<tr>
     <td colspan=3 class="pghdr"><!--- start header --->

          <CFINCLUDE template="/portalINC/dsp_header.cfm">

          <!--- end header ---></td>
</tr>
<tr>
<td valign=top><table border=0 cellpadding=2 cellspacing=0>
          <tr>
               <td><img src="/portal/images/spacer.gif" width="130" height="1" border="0" alt=""></td>
          </tr>
          <tr>
               <td valign=top nowrap class="lgnusr"><br>

                    <!--- start nav --->

                    <cfinclude template="/portalINC/admin_nav_classes.cfm">

                    <!--- end nav ---></td>
          </tr>
     </table></td>
<td valign=top colspan=2 class="bodytext" align=left>
<!--- START CLASS CONTENT --->

<cfset hiddenfieldsdebug = 0>
<!---<cfset totalfees = variables.runningsum>
<cfset disableenterkey = "">
<cfset hidecreditcardpaymentfields = 0>
<cfset useextensivemode = 0>
<cfset NetFees = form.TotalFees - max( 0, min( form.startingBalance, form.TotalFees ) )>
<cfset NetDue = variables.NetFees>
// end set payment block vars
<cfinclude template="paymentblock.cfm">--->
<CFPARAM name="variables.content" default="">
<table border="0" width=730 cellpadding="2" cellspacing="1">
          <TR>
               <TD colspan="8" class="pghdr"><br>Team Registration - Payment Details<br>
               <hr color="##f58220" width=100% align="center" size="5px">
                    </TD>
          </TR>

          <TR>
               <TD colspan="8" >#variables.content#
               
               </TD>
          </TR>
</table>
</form>
</td>
</tr>
</table>
</td>
</tr>
<cfinclude template="/portalINC/footer.cfm">
</table>
</cfoutput>
<cfinclude template="/portalINC/jqstuff.cfm">
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</body>
</html>

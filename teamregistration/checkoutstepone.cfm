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

<!--- <cfinclude template="#request.includes#/top_nav.cfm"> --->
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
<table>

</table>
<cfset hiddenfieldsdebug = 0>
<!---<cfset totalfees = variables.runningsum>--->
<cfset disableenterkey = "">
<cfset hidecreditcardpaymentfields = 0>
<cfset useextensivemode = 0>
<cfset NetFees = form.TotalFees - max( 0, min( form.startingBalance, form.TotalFees ) )>
<cfset NetDue = variables.NetFees>
<!--- end set payment block vars

<cfinclude template="paymentblock.cfm">--->
<table border="0" width=730 cellpadding="2" cellspacing="1">
          <TR>
               <TD colspan="8" class="pghdr"><br>Team Registration - Checkout<br>
               <hr color="##f58220" width=100% align="center" size="5px">
                    </TD>
          </TR>

          <TR>
               <TD colspan="8" align="center"><CFSET currentstep="1"><CFINCLUDE template="wizardsteps.cfm">
                    </TD>
          </TR>

                    <TR>
               <TD colspan="8" align="center"><CFIF structkeyexists(url,"cartfail")><div style="color:##fff;font-weight:bold;background-color:##F00;width:50%;">Please confirm cart contents are correct and check 'Yes' below.</div><CFELSEIF structkeyexists(url,"nogcpref")><div style="color:##fff;font-weight:bold;background-color:##F00;width:50%;">Please indicate below whether you would like to use a gift card.</div><CFSET cartok = true><CFELSE></CFIF>
                    </TD>
          </TR>


          <TR>
               <td class="bodytext" colspan="8" style="padding-left:10px;padding-right:10px;"><br><span class="pghdr">Confirm Selections</span>
               <br>
               <form method="post" action="checkoutccinfo.cfm" name="checkoutmain">
               <input type="hidden" name="checkoutone" value="true">
               Team selections are correct? <input type="radio" name="correct" value="true"  checked> Yes  <input type="radio" name="correct" value="false"> No<br>
               <CFIF variables.NetFees GT 0 and 0>
               Would you like to use a giftcard for all or part of this transaction? <input type="radio" name="gc" value="true"> Yes <input type="radio" name="gc" value="false"> No
               <CFELSE>
               <input type="hidden" name="gc" value="false">
               </CFIF>


               <div style="height:50px;"></div>



               </td>
               </TR>

<!--- all the form fields --->
<CFLOOP list="#form.fieldnames#" index="i">
	<CFIF i NEQ "startingbalance" and
		i neq "districtcreditusedzzz" and
		i neq "amountduezzz">
     <CFOUTPUT>
	<input type="hidden" name="#i#" value="#evaluate('form.#i#')#">
     </CFOUTPUT>
     </CFIF>
</CFLOOP>

               <TR>
                    <td colspan="8" align="center"><hr color="##f58220" width=100% align="center" size="5px">
                         <input name="checkout" value="Continue" type="Button" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;" class="throttlecheckout2" onclick="<CFOUTPUT>#application.checkoutonclick#('checkoutmain');</CFOUTPUT>">
                         <input type="hidden" name="testhidden" value="1">
					<CFIF listfind(application.developerip,cgi.remote_addr) GT 0>
                              <input type="checkbox" name="testmode" value="1">
                              Test Mode: Rollback and display invoice tables
                         </CFIF></TD>
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

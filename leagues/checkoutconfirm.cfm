

<!--- check open call 
<CFINCLUDE template="/portalINC/checkopencall.cfm">--->

<CFSET olddisclaimer = "If THPRD cancels or postpones your class, or you request to drop or change a class at least 48 hours before the first class meeting, the total fee will be credited to your Park District registration account. If you request to drop or change one-day programs, classes, or trips, it must be made at least 48 hours prior to the date of the program, for full credit. No credit will be applied to your Park District registration account with less than 48 hours notice.

If, because of vendor cancellation requirements, a longer refund request period is necessary, for a one day program, class or trip, it will be so noted in the class description, activities guide and on the patron invoice. No credit will be applied in the participant's Park District Registration Account with less than the required notice.

Requests to drop or change a camp program must be made at least two weeks (14 days) prior to the start of the camp. No credit will be applied in the participant's Park District Registration Account with less than two weeks (14 days) notice. Camp deposits are not refundable, and no credit will be applied in the participant's Park District Registration Account.

Credits may be used to register for another class at any THPRD facility. However, all credits of more than $2 will be refunded with the next available cycle, currently Monday, Wednesday and Friday of each week, adjusting for holidays. Credits of less than $2 will remain in the system for future use. Full refunds will be processed by the method of payment used, partial refunds will be refunded by check.">

<style>
label.checkbox-label input[type=checkbox]{
    position: relative;
    vertical-align: middle;
    bottom: 1px;
}
</style>

<CFPARAM name="variables.ccnum" default="">
<CFPARAM name="form.giftcardnumber" default="0">
<CFPARAM name="form.giftcardtstartbalance" default="0">
<CFPARAM name="form.giftcarddebitamount" default="0">
<CFPARAM name="form.giftcardisfa" default="0">

<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3&page=checkoutconfirm">
	<cfabort>
</cfif>

<cfset variables.tc = "">
<cfset variables.primarypatronid = cookie.uID>
<cfset variables.pid = cookie.uID>
<cfset variables.ShowInSession = 0>
<cfset variables.dopsds = "dopsds">
<cfset variables.throttleflag = "false">

<!---// must confirm user is in WWW session before continuing //
<CFSET checksession = sessioncheck( variables.primarypatronid )>

<CFIF checksession.sessionID NEQ 0>
	<CFSET CurrentSessionID = checksession.sessionID>
	<CFELSE>
	<CFSET CurrentSessionID = 0>
	<!--- generic alert page --->
	<CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(checksession.message)#">
	<CFABORT>
</CFIF>
--->
<!--- load FA balances, if any --->
<cfquery datasource="#application.dopsdsro#" name="LoadFABalance">
	SELECT   dops.loadfabalance(<cfqueryparam value="#variables.primarypatronid#" cfsqltype="CF_SQL_INTEGER">)
</cfquery>

<!---
<cfquery datasource="#application.dopsdsro#" name="Get4NewRegistrations">
	SELECT   exists(

	         select   termid
	         FROM     reg
	         WHERE    reg.SessionID = <cfqueryparam value="#variables.CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">) as tmp
</cfquery>
--->

<!--- change by Chris 07/25/2016
<cfif IsDefined("checkout")></cfif>

	<cfif Get4NewRegistrations.tmp is 0>

		<CFSAVECONTENT variable="othererror">
			No new registrations found to process.<BR>
			<a href="/portal/classes/index.cfm"><< Return to class search</a>
		</CFSAVECONTENT>

	</cfif>
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


<SCRIPT>
function validator() {

if(document.getElementById('refpolicy').checked == true) {
	<CFOUTPUT>#application.checkoutonclick#('checkoutmain');</CFOUTPUT>
}
else {alert('Please indicate to have read and agree to the refund policy by checking the box underneath the policy');
	return false;
}
}
</SCRIPT>



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
<!---
<cfif IsInSession( variables.pid ) is 1 or variables.ShowInSession is 1>
     <table width=600 border=0 cellpadding="1" cellspacing=0>
          <tr>
               <td class="pghdr" colspan=2><br>
                    Sports League Registration - Checkout</td>
          </tr>
          <tr>
               <td><img src="../images/spacer.gif" width=1 height=300></td>
               <td class="bodytext_red" align=center valign=top><br>
                    <br>
                    <br>
                    <br>
                    <br>
                    This account is currently being used at a facility or by phone. <br>
                    Please wait until finished and try again.<BR>
                    <input type="Button" class="form_submit" onClick="history.back()" value="Return to Class Listings"></td>
          </tr>
     </table>
     </td>
     </tr>
     </table>
     </td>
     </tr>
     <cfinclude template="/portalINC/footer.cfm">
     </table>
     </body>
     </html>
     <cfabort>
</cfif>
--->
<cfset variables.validationerror = "">

<!---
<cfif not IsDefined("refpolicy")>
     <cfset variables.validationerror = "Refund policy acknowledgement was not checked. Go back and try again.">
</cfif>
--->

<!--- display code --->

<cfset TotalMonies = 0>
<cfset TotalCost = 0>
<cfset variables.NetBalance = GetAccountBalance( variables.PrimaryPatronID )>
<cfset variables.NetToPay = max( 0, variables.TotalCost - variables.NetBalance )>
<cfset continuemode = "Finish">

<!--- if cc is needed, change button and directions --->
<CFPARAM name="form.tenderedcharge" default="0">
<cfif form.tenderedcharge gt 0>
	<cfset continuemode = "Continue">
</cfif>


<table border="0" width=730 cellpadding="2" cellspacing="1">
     <TR>
          <td class="pghdr" colspan=8><br>
                    Sports League Registration - Checkout<br><hr color="##f58220" width=100% align="center" size="5px">
          </td>
     </TR>
     <TR>
               <TD colspan="8" align="center"><CFSET currentstep="4"><CFINCLUDE template="wizardsteps.cfm">
                    </TD>
          </TR>
     <TR>
          <td class="bodytext" colspan="4" valign=top width="60%">



		<CFIF variables.validationerror NEQ "">
			<!--- error msg --->
			<span class="pghdr">Amount Due & Refund Policy - Error</span><br>
			<CFOUTPUT><b style="color:##F00;">#variables.validationerror#</b></CFOUTPUT>
		<CFELSEIF structkeyexists(variables,"othererror") EQ true>
          		<span class="pghdr">Amount Due & Refund Policy - Error</span><br>
			     <CFOUTPUT><b style="color:##F00;">#othererror#</b></CFOUTPUT>

		<CFELSEIF variables.throttleflag EQ true>
				Checkout is currently unavailable. You and your household have temporary reserved enrollment for all classes in your basket.<br>
				Please complete checkout by <b style="color:##C00;"><CFOUTPUT>#timeformat(dateadd('h',2,now()),'h:mm tt')#-#dateformat(now(),'mm/dd/yyyy')#</CFOUTPUT></b> or these class reservations will expire.<a href="javascript:history.back()">Go Back</a>
		<CFELSE>


			<!--- confirm msg; ready to post --->
			<span class="pghdr">Amount Due & Refund Policy</span><br>

			<form method="post" action="processleagueBP_www.cfm" name="checkoutmain" autocomplete="off">
			<!---input type="hidden" name="CurrentSessionID" value="#variables.CurrentSessionID#"--->
			<input type="hidden" name="invoicetranxpostpage" value="processleagueBP_www.cfm">
			<!---<input type="hidden" name="classregistrationtransaction" value="true">--->

			<cfquery datasource="#application.dopsdsro#" name="GetPrimaryData">
				select   firstname,
				         lastname,
				         address1,
				         address2,
				         city,
				         state,
				         zip, (

				select   sessionpatroncontact.contactdata
				from     dops.sessionpatroncontact
				where    sessionpatroncontact.patronid = <cfqueryparam value="#variables.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
				and      sessionpatroncontact.contacttype in ( 'H', 'W', 'C' )
				order by pk
				limit    1) as phone

				from     dops.patroninfo
				where    primarypatronid = <cfqueryparam value="#variables.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
				and      relationtype = <cfqueryparam value="1" cfsqltype="cf_sql_integer" list="no">
			</cfquery>

			<cfif 0>
				<cfdump var="#GetPrimaryData#">
			</cfif>

			<input type="hidden" name="firstname" value="#GetPrimaryData.firstname#">
			<input type="hidden" name="lastname" value="#GetPrimaryData.lastname#">
			<input type="hidden" name="address1" value="#GetPrimaryData.address1#">
			<input type="hidden" name="address2" value="#GetPrimaryData.address2#">
			<input type="hidden" name="city" value="#GetPrimaryData.city#">
			<input type="hidden" name="state" value="#GetPrimaryData.state#">
			<input type="hidden" name="zip" value="#GetPrimaryData.zip#">
			<input type="hidden" name="phone" value="#GetPrimaryData.phone#">
               <!---<input type="hidden" name="patronlookup" value="#cookie.login#">--->


			<CFLOOP list="#form.fieldnames#" index="i">
				<cfif i eq "NETDUE">
					<input type="hidden" name="NETTOPAY" value="#trim(evaluate('form.#i#'))#">
				<cfelseif i eq "TENDEREDCHARGE">
					<input type="hidden" name="NETDUE" value="#trim(evaluate('form.#i#'))#">
					<input type="hidden" name="TENDEREDCHARGE" value="#trim(evaluate('form.#i#'))#">
				<CFELSEIF i neq "fieldnames" and i neq "giftcardnumber" and i neq "primarypatronid" and i NEQ "originalavailablecredit">
					<input type="hidden" name="#i#" value="#trim(evaluate('form.#i#'))#">
				</CFIF>
			</CFLOOP>
                    <CFIF trim(form.giftcardnumber) EQ "">
                         <input type="hidden" name="checksumgiftcardnumber" value="0" >
                         <CFELSE>

                         <cf_cryp type="en" string="#REREPLACE(form.giftcardnumber,"[^0-9]","","ALL")#" key="#key#">
                         <input type="hidden" name="checksumgiftcardnumber" value="#cryp.value#" >

								<!--- get cardid --->
								<cfquery datasource="#application.dopsdsro#" name="GetOCDardID">
									select   cardid
									from     dops.othercreditdata
									where    othercreditdata = <cfqueryparam value="#cryp.value#" cfsqltype="cf_sql_varchar" list="no">
								</cfquery>

								<input type="hidden" name="othercreditcardid" value="#GetOCDardID.cardid#">
								<!--- end get cardid --->

                    </CFIF>
                    <input type="hidden" name="primarypatronid" value="#variables.primarypatronid#" >
                    <input type="hidden" name="patronlookup" value="#ulogin#" >
                    <input name="ORIGINALAVAILABLECREDIT" type="hidden" value="#variables.NetBalance#">
                    <CFPARAM name="variables.waitlistcount" default="0">
                    <CFOUTPUT>
                         
                         Please confirm payment details below, acknowledge refund policy at right and click #variables.continuemode#. <!---Class enrollments will be voided if checkout is not completed by<b style="color:##C00;"> #timeformat(dateadd('h',2,now()),'h:mm tt')#-#dateformat(now(),'mm/dd/yyyy')#.---></b><br><br>
                         </CFOUTPUT><br>
                    <br>
                    <CFIF form.creditused GT 0>
                         <table style="border-color:##000;border-width:1px;border-style:solid;margin-left:30px;width:300px;">
                              <tr>
                                   <td valign="top" style="font-size:12px;">Apply $#decimalformat(form.creditused)# credit.</td>
                              </tr>
                         </table>
                         <br>
                    </CFIF>
                    <CFIF form.tenderedcharge GT 0 OR form.GIFTCARDDEBITAMOUNT GT 0>
                         <table style="border-color:##000;border-width:1px;border-style:solid;margin-left:30px;">
                              <tr>
                                   <td valign="top" style="font-size:12px;"><CFIF form.tenderedcharge GT 0 and form.GIFTCARDDEBITAMOUNT EQ 0>
                                             	<strong>Charge my credit card $#decimalformat(form.tenderedcharge)#</strong><br>
                                             <CFELSEIF form.tenderedcharge GT 0 and form.GIFTCARDDEBITAMOUNT GT 0>
                                             	<strong>Apply $#decimalformat(form.GIFTCARDDEBITAMOUNT)# from my gift card</strong><br>
                                             	Number: XXXX - XXXX - XXXX - #right(GIFTCARDNUMBER,4)#<br>
                                             	<br>
                                             	<strong>Charge remaining balance of $#decimalformat(form.tenderedcharge)# to my credit card</strong><br>
                                             	<br>
                                             <CFELSEIF form.tenderedcharge EQ 0 and form.GIFTCARDDEBITAMOUNT GT 0>
                                             	<strong>Apply $#decimalformat(form.GIFTCARDDEBITAMOUNT)# from my gift card</strong><br>
                                             	Number: XXXX - XXXX - XXXX - #right(GIFTCARDNUMBER,4)#<br>
                                        </CFIF></td>
                              </tr>
                         </table>
                    </CFIF>
               </CFIF></TD>
          <td class="bodytext"  colspan=4  width="40%" style="margin-left:15px;">

	<cfif <!---Get4NewRegistrations.tmp is 1 OR---> 1 eq 1>

		<cfquery datasource="#application.dopsdsro#" name="GetDisclaimer" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
			select   disclaimcontents
			from     disclaimers
			where    disclaimname = <cfqueryparam value="Refunds" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>

                   <cfif nettopay gte 0>
                    <cfif GetDisclaimer.recordcount is 1>


                                   <table border=0 cellpadding=2 cellspacing="0"  width="300" bgcolor="##666666">
                                       <tr>
                                             <td align="center" valign="middle" style="padding-top:10px;">
                                                  <strong class="sectionhdr" style="color:##fff">Refund Policy</strong><br></td>
                                        </tr>

                                        <TR>
                                             <TD style="padding-top:10px;padding-right:20px;padding-left:10px;padding-bottom:10px;"><div class="scroll" style="height:100px">#Replace(GetDisclaimer.disclaimcontents,chr(13),"<BR>","all")#</div></TD>
                                        </TR>
                                        <!---
                                        <CFIF showolddisclaimer>
                                        <tr>
                                             <td align="center" valign="middle" style="padding-top:5px;padding-bottom:5px;" bgcolor="##999999">
                                                  <strong style="color:##fff">Refund Policy for previous terms</strong><br></td>
                                        </tr>
                                        <TR>
                                             <TD style="padding-top:10px;padding-right:20px;padding-left:10px;padding-bottom:10px;"><div class="scroll" style="height:30px">#Replace(olddisclaimer,chr(13),"<BR>","all")#</div></TD>
                                        </TR>
                                        </CFIF>
								--->
                                        <tr>
                                             <td align="center" style="padding-bottom:5px;padding-top:5px;background-color:##CC9;">
                                                  <label class="checkbox-label"><input type="checkbox" name="refpolicy" id="refpolicy" > &nbsp; I have read and <strong>agree</strong> to the refund policy</label></td>
                                        </tr>
                                   </table><!---<TD colspan=3  style="padding-left:10px;padding-right:10px;padding-bottom:10px;"></TD>--->

                    </cfif>
               </cfif>
               </cfif>

          </td>
     </TR>

     <tr>
     <td colspan="8">

      </td>
     </tr>

<!---
<CFLOOP list="#form.fieldnames#" index="i">
	<CFSET copylist = "SELECTAPPTYPE,SELECTSCHOOL,SELECTSHIRT">
	<CFIF listfindnocase(copylist,i) GT 0></CFIF>
     <CFOUTPUT>
	<input type="hidden" name="COPY_#i#" value="#evaluate('form.#i#')#">
     </CFOUTPUT>
</CFLOOP>
--->
     <TR>
          <td colspan="8" align="center"><div style="height:30px;"></div>
               <hr color="##f58220" width=100% align="center" size="5px">
               <input type="Button" class="GoButton" onClick="history.back()" value="Go Back" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;">
               <CFIF validationerror EQ "" and throttleflag EQ "false">
                    <input name="checkout" value="#variables.continuemode#" type="button" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;" class="throttlecheckout2" onclick="validator();">
               </CFIF></TD>
     </TR>
</table>
</form>

<!--- END CLASS CONTENT --->
</td>
</tr>
</table>
</td>
</tr>
<tr>
     <td colspan="3"><img src="#request.imagedir#/spacer.gif" width="1" height="11" border="0" alt=""></td>
</tr>
<cfinclude template="/portalINC/footer.cfm">
</table>
</cfoutput>
<cfinclude template="/portalINC/jqstuff.cfm">
<CFINCLUDE template="/portalINC/googleanalytics.cfm">

</body>
</html>

<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
</cfif>

<CFINCLUDE template="/portalINC/checkopencall.cfm">
<!---cfinclude template="/common/functions.cfm" 06122017 --->
<cfinclude template="/common/checkformelements.cfm">
<cfset sessionvars = getprimarysessiondata(cookie.uid, "TEAM")>

<cfif ( sessionvars.sessionid eq "NONE" or sessionvars.facid neq "WWW" )>
	<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
	<cfabort>
</cfif>

<CFSET variables.thisModule = "TEAM">
<CFSET variables.collisionMsg = "Activities not related to Team Registration were detected.">
<!--- standard code to determine if there are other items in basket // need to keep track of district credit // assumes closed cfoutput--->
<cfif variables.sessionvars.module neq "NONE" and variables.sessionvars.module neq variables.thisModule>
	<CFSAVECONTENT variable="message">
	<cfoutput>#variables.collisionMsg#<BR>
	#sessionvars.modulecomments#<cfif 0>#sessionvars.module#</cfif>
	</cfoutput>
	</CFSAVECONTENT>
	<cfset form.patronlookup = "">
	<cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>

<cfparam name="form.othercreditused" default="0.00">

<!--- check open call
<CFINCLUDE template="/portalINC/checkopencall.cfm">--->

<!--- ROUTING
<CFIF NOT structkeyexists(form,"classregistrationtransaction")>
     <!--- make sure patron confirmed contents --->
     <CFIF NOT structkeyexists(form,"correct") OR form.correct EQ "false">
          <CFLOCATION url="checkoutstepone.cfm?cartfail=false">
     </CFIF>

     <!--- make sure patron confirmed contents --->
     <CFIF NOT structkeyexists(form,"gc")>
          <CFLOCATION url="checkoutstepone.cfm?nogcpref=true">
     </CFIF>
     <!--- if patron wants to use a giftcard redirect --->
     <CFIF structkeyexists(form,"gc") and form.gc EQ true>
          <!--- this is so bad I cannot believe i wrote this --->
          <CFINCLUDE template="checkoutgiftcard.cfm">
          <CFABORT>
     </CFIF>
</CFIF> --->
<!---<cfset tc = "">
<cfset primarypatronid = cookie.uID>
<CFPARAM name="form.unreg_gc1" default="">
<CFPARAM name="form.unreg_gc2" default="">
<CFPARAM name="form.unreg_gc3" default="">
<CFPARAM name="form.unreg_gc4" default="">
<CFPARAM name="form.maxgcamount" default="">
<CFPARAM name="selectcardmessageerror" default="">
<CFPARAM name="famsg" default="">
<CFPARAM name="form.gctype" default="">

<CFPARAM name="form.GIFTCARDNUMBER" default="0">--->

<CFPARAM name="form.GIFTCARDDEBITAMOUNT" default="0">
<cfset moneywidth=70>


<!---// must confirm user is in WWW session before continuing //--->

<!--- ADD check to see if the sessionid has any completed transactions with it
<CFSET checksession = sessioncheck(primarypatronid)>
<CFIF checksession.sessionID NEQ 0>
     <CFSET CurrentSessionID = checksession.sessionID>
     <CFELSE>
     <CFSET CurrentSessionID = 0>
     <!--- generic alert page --->
     <CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(checksession.message)#">
     <CFABORT>
</CFIF>
--->
<!--- reset session for testing
<CFIF Isdefined("url.resetsession")>
     <cfset newsessionid = uCase(removeChars(application.IDmaker.randomUUID().toString(), 24, 1))>
     <CFQUERY name="newsession" datasource="#application.dopsds#">
insert into sessions
(sessionid)
VALUES
('#newsessionid#');
update sessionpatrons set sessionid = '#newsessionid#' where sessionid = '#CurrentSessionID#';
update sessionpatronsorigdata set sessionid = '#newsessionid#' where sessionid = '#CurrentSessionID#';
update sessionquerylisting set sessionid = '#newsessionid#' where sessionid = '#CurrentSessionID#';
update sessionquerywords set sessionid = '#newsessionid#' where sessionid = '#CurrentSessionID#';
</CFQUERY>
     <!--- recheck --->
     <CFSET rechecksession = sessioncheck(primarypatronid)>
     <CFSET CurrentSessionID = rechecksession.sessionID>
</CFIF>
--->

<!---<cfset TotalMonies = 0>
<cfset TotalCost = 0>
<cfset problems = 0>
<cfset TotalBalance = 0>
<cfset AssmtErrors = 0>--->

<!--- include for card; displayed below; called here because queries are needed --->
<cfset suppresstitle = 0>
<cfset suppressdropbutton = 1>
<!--- totalmonies is calculated in shownewregcheckout --->

<!---<cfset TotalCost = form.totalfees>--->

<cfset startingBalance = GetAccountBalance( cookie.uID )>

<CFQUERY name="gettotal" datasource="#application.dopsds#">
	SELECT   sum( sessionothercredit.amount ) as amount
	FROM     dops.sessionothercredit
	WHERE    sessionID = <CFQUERYPARAM cfsqltype="cf_sql_varchar" value="#form.currentsessionid#">
</CFQUERY>

<!---<cfset totalFees = gettotal.amount>--->
<!---<cfset districtCreditUsed = min( startingBalance, form.totalFees )>--->
<!---<cfset amountDue = max( 0, gettotal.amount - form.districtCreditUsed)>--->
<!---<cfset otherCreditUsed = 0>
<cfset otherCreditCardID = 0>
<cfset netDue = variables.totalFees - variables.districtCreditUsed>--->

<CFSILENT>
<cfset localfac = "WWW">
<cfset localnode = "AC">
<cfset DS = "#application.reg_dsn#">
<cfset pid = cookie.uID>
<cfset GLLineNo = 0>
<!---<cfset ShowCurrentReg = 0>--->
<!--- set to 0 to suppress showing current regs --->

<!--- toggle vars to show msg do ease in formatting --->
<!---<cfset ShowInSession = 0>
<cfset ShowDeleteConfirm = 0>
<cfset ShowCancelled = 0>
<cfset ShowAlreadyEnrolled = 0>
<cfset ShowNoAssmt = 0>
<cfset ShowWaitList = 0>
<cfset ShowError = 0>
<cfset ShowNonExistanceError = 0>
<cfset ShowNoRecords = 0>
<cfset ShowNoClasses = 0>
<cfset ShowNoActions = 0>
<cfset ShowNotAvail = 0>--->
<!--- end --->

<!--- what is this? - cr --->

<!---<cfquery datasource="#application.dopsdsro#" name="GetPrimary">
	SELECT   patrons.lastname,
	         patrons.firstname,
	         patrons.middlename,
	         patronRelations.verifyexpiration,
	         patrons.DOB,
	         PatronAddresses.address1,
	         PatronAddresses.address2,
	         PatronAddresses.city,
	         patrons.patronid,
	         patrons.insufficientid,
	         PatronAddresses.state,
	         PatronAddresses.zip,
	         PatronRelations.RelationType,
	         PatronRelations.InDistrict,
	         patrons.patronlookup,
	         patrons.verified,
	         patrons.inactive,
	         patrons.gender,
	         patrons.admcomments
	FROM     PatronRelations PatronRelations
	         INNER JOIN patrons patrons ON PatronRelations.PrimaryPatronid=patrons.PatronID
	         LEFT OUTER JOIN PatronAddresses PatronAddresses ON PatronRelations.AddressID=PatronAddresses.AddressID
	where    patronRelations.PrimaryPatronid = <cfqueryparam value="#pid#" cfsqltype="cf_sql_integer" list="no">
	and      patronRelations.SecondaryPatronid = <cfqueryparam value="#pid#" cfsqltype="cf_sql_integer" list="no">
	and      not patrons.inactive
</cfquery>--->
<!---<cfset InDistrictStatus = 1>
<cfif GetPrimary.insufficientid is 1 or GetPrimary.InDistrict is 0>
     <cfset InDistrictStatus = 0>
</cfif>--->
</cfsilent>

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN" "http://www.w3.org/TR/html4/loose.dtd">
<html>
<head>
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1">
<meta http-equiv='cache-control' content='no-cache'>
<meta http-equiv='expires' content='0'>
<meta http-equiv='pragma' content='no-cache'>
<title>Team Registration</title>
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




<!--- display code --->
<form method="post" action="checkoutconfirm.cfm" name="class_sum" autocomplete="off">
<input type="hidden" name="currentsessionid" value="#sessionvars.sessionid#">
     <!---<input type="hidden" name="classregistrationtransaction" value="true">--->
     <table border="0" width=730 cellpadding="2" cellspacing="1">
     <TR>
          <td class="pghdr" colspan=8><br>
               Team Registration - Checkout<br><hr color="##f58220" width=100% align="center" size="5px"></td>
     </TR>
     <TR>
          <TD colspan="8" align="center"><CFSET currentstep="3">
               <CFINCLUDE template="wizardsteps.cfm"></TD>
     </TR>




     <TR>
          <td class="bodytext" colspan="8" style="padding-left:10px;padding-right:10px;"><span class="pghdr">Account Information</span>
               <table border="0" cellpadding="1" cellspacing="1" style="margin-top:3px;" width="100%">
                    <TR align="right">
                         <td align="left" rowspan="4"><table cellpadding="2" border="0" width="100%" style="padding-right:10px;">
                                   <tr>
                                        <td colspan="3" rowspan="2" >
										<CFIF netdue gt form.giftcarddebitamount>
                                                  <table cellpadding="3" border="0"   width="100%" style="margin-top:2px;border-width:0px;border-style:solid;border-color:##000">
                                                       <tr>
                                                            <td valign="top" ></td>
                                                            <td valign="top" nowrap></td>
                                                            <td valign="top" nowrap></td>
                                                       </tr>
                                                       <tr>
                                                            <td colspan="3" ></td>
                                                       </tr>
                                                  </table>
                                                  <CFELSE>

                                                       <table cellpadding="3" border="0"  bgcolor="##CCCC99" width="100%" style="margin-top:2px;">
                                                            <tr>
                                                                 <td><CFIF Isdefined("form.giftcarddebitamount") and form.giftcarddebitamount GT 0>
                                                                           <strong>Entire amount due to be paid with gift card.</strong><br>
                                                                           Please click continue below to go to the next step in checkout.
                                                                           <CFELSE>
                                                                           <strong>No additional funds required.</strong><br>
                                                                           Please click continue below to go the next step in checkout.
                                                                      </CFIF>
                                                                      <br>
                                                                      <br></td>
                                                            </tr>
                                                       </table>


                                             </CFIF>
                                             <input name="giftcardnumber" type="hidden" value="0">
                    <!---input name="giftcardtstartbalance" type="hidden" value="#theselectedcardbalance#"--->
                    <!---<input name="giftcarddebitamount" type="hidden" value="0">--->
                    <!---input name="giftcardisfa" type="hidden" value="#theselectedcardisfa#" --->
                    <!---<input name="netdue" type="hidden" value="#form.netdue#">--->


                                             </td>
                                        <td rowspan="2">&nbsp;</td>
                                        <td></td>
                                   </tr>
                                   <tr>
                                        <td>&nbsp;</td>
                                   </tr>
                              </table></td>
                         <TD nowrap bgcolor="##eeeeee" width="1%">Account Balance</TD>
                         <td align="right" width="1%"><input value="#numberformat(startingBalance, "999999.99")#" name="startingbalance" type="text" readonly style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
                    </TR>
                    <TR align="right">
                         <TD nowrap bgcolor="##eeeeee">Total Fees</TD>
                         <td align="right" width="1%"><input readonly value="#numberformat(form.totalFees, "999999.99")#" type="Text" name="TotalFees" style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
                    </TR>
                    <TR align="right">
                         <TD bgcolor="##eeeeee">Credit Used</TD>
                         <TD><input value="#numberformat(districtCreditUsed, "999999.99")#" name="districtCreditUsed" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
                    </TR>

						<input value="#numberformat(amountDue, "999999.99")#" name="amountDue" type="hidden">
						<input type="hidden" name="OtherCreditUsed" value="0">

                    <TR align="right">
                         <td valign="middle" align="right" nowrap bgcolor="##FFFF99">Adjusted Net Due</td>
                         <td valign="middle" align="right" bgcolor="##FFFF99"><input value="#decimalformat( form.netDue - form.otherCreditUsed )#" type="Text" readonly="yes" <!---name="AdjustedNetDue"--->name="tenderedcharge" style="text-align: right; background: white; width:#moneywidth#px;" class="form_input"></td>
                    </TR>
               </table>

<CFLOOP list="#form.fieldnames#" index="i">
	<CFIF i neq "amountdue" and
		i NEQ "pickgiftcard" and
		i NEQ "fieldnames" and
		i NEQ "othercreditused" and
		i neq "totalfees" and
		i neq "currentsessionid">
     <CFOUTPUT>
	<input type="hidden" name="#i#" value="#evaluate('form.#i#')#">
     </CFOUTPUT>
     </CFIF>
</CFLOOP>

     <TR>
          <td colspan="8" align="center"><div style="height:50px;"></div>
               <hr color="##f58220" width=100% align="center" size="5px">
               <input type="Button" class="GoButton" onClick="history.back()" value="Go Back" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;">
               <input name="checkout" value="Continue" type="Button" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;" class="throttlecheckout2" onclick="<CFOUTPUT>#application.checkoutonclick#('class_sum');</CFOUTPUT>">
               <CFIF listfind(application.developerip,cgi.remote_addr) GT 0>
                    <br>
                    <input type="checkbox" name="testmode" value="1">
                    Test Mode: Rollback and display invoice tables
               </CFIF></TD>
     </TR>
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

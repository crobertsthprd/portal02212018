<!---CFDUMP var="#form#"--->

<cfif NOT structkeyexists(cookie,"uID")>
     <cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
     <cfabort>
</cfif>

<!--- check open call --->
<CFINCLUDE template="/portalINC/checkopencall.cfm">

<!---<CFINCLUDE template="/common/functionsv2.cfm">--->
<cfinclude template="/common/functionsbp.cfm">

<cfinclude template="/common/checkformelements.cfm">
<cfset sessionvars = getprimarysessiondata(cookie.uid)>

<cfif ( sessionvars.sessionid eq "NONE" or sessionvars.facid neq "WWW" ) or form.currentsessionid neq sessionvars.sessionid>
	<!--- redirect to cart
	<cflocation url="regbaldue1.cfm">
	<cfabort> --->
</cfif>


<!---<!--- ROUTING --->
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
          <CFLOCATION url="checkoutgiftcard.cfm">
     </CFIF>
</CFIF>--->

<CFIF NOT structkeyexists(form,"correct") OR form.correct EQ "false">
	<!---<CFLOCATION url="regbaldue1.cfm">--->
</CFIF>

     <!--- if patron wants to use a giftcard redirect --->
     <CFIF structkeyexists(form,"gc") and form.gc EQ true>
          <!---<CFLOCATION url="checkoutgiftcard.cfm">--->
<cfinclude template="checkoutgiftcard.cfm">
<cfabort>
     </CFIF>


<cfset tc = "">
<cfset primarypatronid = cookie.uID>
<!---<CFPARAM name="form.unreg_gc1" default="">
<CFPARAM name="form.unreg_gc2" default="">
<CFPARAM name="form.unreg_gc3" default="">
<CFPARAM name="form.unreg_gc4" default="">--->
<CFPARAM name="form.maxgcamount" default="">
<CFPARAM name="selectcardmessageerror" default="">
<CFPARAM name="famsg" default="">
<CFPARAM name="form.gctype" default="">
<CFPARAM name="form.GIFTCARDDEBITAMOUNT" default="0">
<CFPARAM name="form.GIFTCARDNUMBER" default="0">
<cfset moneywidth=70>

<!---// must confirm user is in WWW session before continuing //--->

<!--- ADD check to see if the sessionid has any completed transactions with it --->
<CFSET checksession = sessioncheck(primarypatronid)>
<CFIF checksession.sessionID NEQ 0>
     <CFSET CurrentSessionID = checksession.sessionID>
<CFELSE>
     <CFSET CurrentSessionID = 0>
     <!--- generic alert page --->
     <CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(checksession.message)#">
     <CFABORT>
</CFIF>

<!--- reset session for testing --->
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

<!--- load FA balances, if any --->
<cfquery datasource="#application.dopsdsro#" name="LoadFABalance">
	SELECT   dops.loadfabalance(<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">)
</cfquery>
<!---<cfinclude template="classescommon.cfm">--->

<!--- what is this? CR --->
<cfquery datasource="#application.dopsdsro#" name="Get4NewRegistrations">
	SELECT   exists(
	         select   termid
	         FROM     reg
	         WHERE    reg.SessionID = <cfqueryparam value="#form.currentSessionID#" cfsqltype="CF_SQL_VARCHAR">) as tmp
</cfquery>
<cfset TotalMonies = 0>
<cfset TotalCost = 0>
<cfset problems = 0>
<cfset TotalBalance = 0>
<cfset AssmtErrors = 0>
<CFSET FAmax = 0>
<!--- include for card; displayed below; called here because queries are needed --->
<cfset suppresstitle = 0>
<cfset suppressdropbutton = 1>
<!--- totalmonies is calculated in shownewregcheckout --->
<!---<cfinclude template="shownewregcheckout.cfm">--->
<cfset TotalCost = TotalMonies>
<cfset NetBalance = primarybalance(PrimaryPatronID)>
<cfset NetToPay = max(0,TotalCost - NetBalance)>
<!---<cfset districtCreditUsed = min( netBalance, variables.netToPay )>--->
<CFSILENT>
<cfset localfac = "WWW">
<cfset localnode = "W1">
<cfset DS = "#application.reg_dsn#">
<cfset pid = cookie.uID>
<cfset GLLineNo = 0>
<cfset ShowCurrentReg = 0>
<!--- set to 0 to suppress showing current regs --->

<!--- toggle vars to show msg do ease in formatting --->
<cfset ShowInSession = 0>
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
<cfset ShowNotAvail = 0>
<!--- end --->

<!--- what is this? - cr --->

<CFINCLUDE template="/portalINC/familyassistance_functions.cfm">
<cfquery datasource="#application.dopsdsro#" name="GetPrimary">
	SELECT   patrons.lastname, patrons.firstname, patrons.middlename, patronRelations.verifyexpiration,
	         patrons.DOB, PatronAddresses.address1,
	         PatronAddresses.address2, PatronAddresses.city, patrons.patronid, patrons.insufficientid,
	         PatronAddresses.state, PatronAddresses.zip, PatronRelations.RelationType,
	         PatronRelations.InDistrict, patrons.patronlookup, patrons.verified, patrons.inactive, patrons.gender, patrons.admcomments
	FROM     PatronRelations PatronRelations
	         INNER JOIN patrons patrons ON PatronRelations.PrimaryPatronid=patrons.PatronID
	         LEFT OUTER JOIN PatronAddresses PatronAddresses ON PatronRelations.AddressID=PatronAddresses.AddressID
	where    patronRelations.PrimaryPatronid = <cfqueryparam value="#pid#" cfsqltype="cf_sql_integer" list="no">
	and      patronRelations.SecondaryPatronid = <cfqueryparam value="#pid#" cfsqltype="cf_sql_integer" list="no">
	and      not patrons.inactive
	</cfquery>
<cfset InDistrictStatus = 1>
<cfif GetPrimary.insufficientid is 1 or GetPrimary.InDistrict is 0>
     <cfset InDistrictStatus = 0>
</cfif>
</cfsilent>

<cfinclude template="regbaldue4a.cfm">

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

<!---
<cfif IsInSession(pid) is 1 or ShowInSession is 1>
<table width=730 border=0 cellpadding="1" cellspacing=0>
     <tr>
          <td class="pghdr" colspan=2><br>
               Class Registration - Checkout</td>
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


<CFPARAM name="gcpayment" default="0">
<CFPARAM name="newcardbalance" default="0">
<CFPARAM name="theselectedcard" default="0">
<CFPARAM name="theselectedcardbalance" default="0">
<CFPARAM name="theselectedcardisfa" default="0">
<CFIF giftcardnumber NEQ 0>
     <!---
     <CFSET newgcbalance = theselectedcardbalance - nettopay - gcpayment>
     <cf_cryp type="en" string="#theselectedcard#" key="#skey#">
     <cfset CardLimit = getCardData.sumnet>
     <cfif getCardData.isfa is 1>
          <cfset CardLimit = min(CardLimit, FACardLimit)>
     </cfif>
     <CFIF getCardData.isfa IS true>
          <cfset ApplicableAmount = FACardLimit>
          <cfelse>
          <cfset ApplicableAmount = CardLimit>
     </CFIF>
     <CFIF getCardData.isfa IS true>
          <CFSET famsg = "Available funds are determined by eligibility of individual household members for family assistance.">
     </CFIF>
	--->
</CFIF>

<!--- display code --->
<form method="post" action="checkoutconfirm.cfm" name="class_sum" autocomplete="off">
	<input type="hidden" name="currentsessionid" value="#form.currentsessionid#">
	<input type="Hidden" name="amountdue" value="#form.amountdue#">
	<input type="hidden" name="startingBalance" value="#form.startingBalance#">

	<!---<input type="Hidden" name="NetDue" value="#form.netdue#">--->
	<!---<input type="Hidden" name="giftcarddebitamount" value="#form.giftcarddebitamount#">--->

     <!---<input type="hidden" name="classregistrationtransaction" value="true">--->
     <table border="0" width=730 cellpadding="2" cellspacing="1">

               <cfset TotalCost = TotalMonies>

     <TR>
               <TD colspan="8" class="pghdr"><br>Pay Balance - Checkout<br>
               <hr color="##f58220" width=100% align="center" size="5px">
                    </TD>
          </TR>
     <TR>
          <TD colspan="8" align="center"><CFSET currentstep="3">
               <CFINCLUDE template="includes/wizardsteps.cfm"></TD>
     </TR>




     <TR>
          <td class="bodytext" colspan="8" style="padding-left:10px;padding-right:10px;"><span class="pghdr">Account Information</span>
               <table border="0" cellpadding="1" cellspacing="1" style="margin-top:3px;" width="100%">
                    <TR align="right">
                         <td align="left" rowspan="4"><table cellpadding="2" border="0" width="100%" style="padding-right:10px;">
                                   <tr>
                                        <td colspan="3" rowspan="2" >
										<CFIF nettopay gt form.giftcarddebitamount>
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
                                                  <cfif Get4NewRegistrations.tmp is 1>
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
                                                       <input type="hidden" name="cctype" value="">
                                                       <input type="hidden" name="ccnum1" value="">
                                                       <input type="hidden" name="ccnum2" value="">
                                                       <input type="hidden" name="ccnum3" value="">
                                                       <input type="hidden" name="ccnum4" value="">
                                                       <input type="hidden" name="ccExpMonth" value="">
                                                       <input type="hidden" name="ccExpYear" value="">
                                                       <input type="hidden" name="ccv" value="">
                                                  </cfif>
                                             </CFIF>
                                             <input name="giftcardnumber" type="hidden" value="#form.giftcardnumber#">
                    <!---input name="giftcardtstartbalance" type="hidden" value="#theselectedcardbalance#"--->
                    <input name="giftcarddebitamount" type="hidden" value="#form.giftcarddebitamount#">
                    <!---input name="giftcardisfa" type="hidden" value="#theselectedcardisfa#" --->
                    <!---<input name="calculatedNetToPay" type="hidden" value="#nettopay#">--->
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
                         <td align="right" width="1%"><input value="#numberformat(NetBalance, "999999.99")#" name="AvailableCredit" type="text" readonly style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
                    </TR>
                    <TR align="right">
                         <TD nowrap bgcolor="##eeeeee">Total Fees</TD>
                         <td align="right" width="1%"><input readonly value="#numberformat( form.amountdue, "999999.99")#" type="Text" name="TotalFees" style="text-align: right; width: #moneywidth#px;" class="form_input"></td>
                    </TR>
                    <TR align="right">
                         <TD bgcolor="##eeeeee">Credit Used</TD>
                         <TD><input value="#numberformat(form.districtCreditUsed, "999999.99")#" name="districtCreditUsed" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
                    </TR>
                    <TR align="right">
                         <TD bgcolor="##eeeeee">Net Due</TD>
                         <TD><input value="#numberformat(form.netdue, "999999.99")#" name="NetFees" readonly type="text" style="text-align: right; width: #moneywidth#px;" class="form_input"></TD>
                    </TR>
                    <TR align="right">
                         <td valign="middle" bgcolor="##99CCFF" align="right"><CFIF Isdefined("giftcarddebitamount") and giftcarddebitamount GT 0>
                                   <strong>Card #mid( giftcardnumber, 1, 4)# #mid( giftcardnumber, 5, 4)# #mid( giftcardnumber, 9, 4)# #mid( giftcardnumber, 13, 4)#</strong>&nbsp;&nbsp;&nbsp;
                              </CFIF>
                              <CFSET ThisOtherCreditAvailableLimit = 0></td>
                         <TD bgcolor="##99CCFF" valign="middle"><!---<cfif IsDefined("getCardData.othercreditdesc")>#getCardData.othercreditdesc#<cfelse>Card</cfif><br>Funds To Apply--->
                              Gift Card
                              <!---
                         <CFIF Isdefined("gcpayment") and gcpayment GT 0>
                              Gift Card
                         </CFIF>
					---></TD>
                         <!---
                    <CFIF structkeyexists(form,"giftcarddebitamount") and form.giftcarddebitamount GT 0>
                         <CFSET thegcpay = form.giftcarddebitamount>

                         <CFELSE>
                         <CFSET thegcpay = 0>
                    </CFIF>
				--->
                         <TD bgcolor="##99CCFF" valign="middle"><input type="Text" <cfif ThisOtherCreditAvailableLimit is 0> style="text-align: right; width: #moneywidth#px; font-size:10px;" readonly<cfelse> style="background-color:##FFFF99; text-align: right; width: #moneywidth#px; font-size:10px;" onChange="this.value=formatCurrency(this.value);calcfee()" </cfif> name="OtherCreditUsed" value="#numberformat(form.giftcarddebitamount,'99999999.99')#" class="form_input" ></TD>
                    </TR>
                    <TR align="right">
                         <td bgcolor="##FFFF99" ></td>
                         <td valign="middle" align="right" nowrap bgcolor="##FFFF99">Adjusted Net Due</td>
                         <td valign="middle" align="right" bgcolor="##FFFF99"><input value="#numberformat(form.netdue - form.giftcarddebitamount  ,"999999.99")#" type="Text" readonly="yes" <!---name="AdjustedNetDue"--->name="netdue" style="text-align: right; background: white; width:#moneywidth#px;" class="form_input"></td>
                    </TR>
               </table>
				</td>

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

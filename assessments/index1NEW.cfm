<CFSILENT>
<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>


<CFABORT>
<!--- start set up for assessments; this should be on it own page --->
<!--- handle assessment selections --->
<CFIF Isdefined("url.clearpicks")>
	<CFQUERY name="removeassmtinsession" datasource="#application.slavedopsds#">
		delete
		from dops.sessionassessments
		where sessionid = <cfqueryparam cfsqltype="cf_sql_varchar" value='#getsession.sessionid#' list="no">
	</CFQUERY>
	<CFSET cookie.assmtpicks = 0>
</CFIF>


<CFQUERY name="sa" datasource="#application.slavedopsds#">
	select aid from dops.sessionassessments
	where sessionid = <cfqueryparam cfsqltype="cf_sql_varchar" value='#getsession.sessionid#' list="no">
</CFQUERY>
<CFSET cookie.assmtpicks = valuelist(sa.aid)>


<CFPARAM name="cookie.assmtpicks" default="">

<cfparam name="DisplayMode" default="A">
<!--- DisplayMode codes:
A = assessment status
P = Pass Status
R = Registrations
 --->

	<cfset localfac = "WWW">
	<cfset localnode = "W1">
	<cfset DS = "thirst">

	<CFINCLUDE template="/portalINC/checkopencall.cfm">
	<!---cfinclude template="/common/functions.cfm" 06122017 --->
	<cfinclude template="/common/functionsbp.cfm">
	<cfinclude template="/common/checkformelements.cfm">
	<cfset sessionvars = getprimarysessiondata(cookie.uid)>
	<!--- <cfdump var="#sessionvars#"><cfdump var="#cookie#"> --->
	<cfif ( sessionvars.sessionid eq "NONE" or sessionvars.facid neq "WWW" ) <!--- or form.currentsessionid neq sessionvars.sessionid --->>
		<cflocation url="../index.cfm?msg=3&page=checkoutccinfo">
		<cfabort>
	</cfif>

	<cfif sessionvars.module neq "ASSMT" AND sessionvars.module neq "NONE" AND sessionvars.module neq "">
		<CFSAVECONTENT variable="message">
		Activities not related to assessment purchase were detected.<br>
          You currently have shopping cart items in: <br>
          <CFDUMP var="#sessionvars#">
		<!---
		<cfoutput>#sessionvars.module#</cfoutput>
          <CFDUMP var="#sessionvars#">
		--->
		</CFSAVECONTENT>
		<cfset form.patronlookup = "">
          <CFPARAM name="currentstep" default="1">
          <CFPARAM name="headertitle" default="Cart Unavailable">
		<cfinclude template="includes/layout.cfm">
		<cfabort>
	</cfif>



<!--- <cfif not IsDefined("PrimaryPatronID")>
	<strong>No patron ID specified.</strong>
	<cfabort>
</cfif> --->
<cfquery datasource="#application.slavedopsds#" name="GetPrimaryName">
	SELECT   lastname, firstname, middlename
	FROM     Patrons
	WHERE    PatronID = #cookie.uid#
</cfquery>

<cfquery datasource="#application.slavedopsds#" name="GetPassTypes">
	select passtype
	from passtype
</cfquery>

<!--- get last invoice for balance --->
<cfquery datasource="#application.slavedopsds#" name="GetCurrentBalance">
	Select startingbalance, newcredit, TenderedCash, TenderedCheck, TenderedCC, TenderedChange, TotalFees
	from INVOICE
	where PRIMARYPATRONID = #cookie.uid#
	AND      invoice.isvoided = false
	order by dt desc
	limit 1
</cfquery>

<cfquery datasource="#application.slavedopsds#" name="GetSession">
	SELECT   sessionid
	FROM     dops.sessionpatrons
	WHERE    primarypatronid = <cfqueryparam cfsqltype="cf_sql_integer" value="#cookie.uid#" list="no">
	and      relationtype = <cfqueryparam cfsqltype="cf_sql_integer" value="1" list="no">
</cfquery>

<!--- change on assessment --->

<cfquery datasource="#application.slavedopsds#" name="CheckAssmtStatus">
	SELECT   ALLASSESSMENTS.*, INVOICE.DT,
	         PATRONS.PATRONLOOKUP, PATRONS.LASTNAME, PATRONS.FIRSTNAME,
	         PATRONS.MIDDLENAME
	FROM     ALLASSESSMENTS
	         INNER JOIN INVOICE INVOICE ON ALLASSESSMENTS.INVOICEFACID=INVOICE.INVOICEFACID AND ALLASSESSMENTS.INVOICENUMBER=INVOICE.INVOICENUMBER
	         INNER JOIN PATRONS PATRONS ON ALLASSESSMENTS.PATRONID=PATRONS.PATRONID
	WHERE    ALLASSESSMENTS.PRIMARYPATRONID = #cookie.uid#
	AND      ALLASSESSMENTS.valid = true
	AND      ALLASSESSMENTS.assmtexpires >= current_date
	ORDER BY INVOICE.DT DESC, PATRONS.LASTNAME, PATRONS.FIRSTNAME, ALLASSESSMENTS.assmteffective
</cfquery>


</CFSILENT>

<cfoutput>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Patron Information</title>
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
			<cfinclude template="/portalINC/admin_nav_history.cfm">
			<!--- end nav --->
			</td>
			</tr>
			</table>
		</td>

		<td valign=top class="bodytext" width="100%">
		<!--- start content --->
		<table border="0" width="100%" cellpadding="1" cellspacing="0">





<!--- start assessment --->
     <cfquery datasource="#application.dopsdsro#" name="GetNewRegistrations">
	select   reg.patronid,reg.sessionID
	from     reg
	where    reg.sessionid is not null
	and      reg.primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
	limit    1
     </cfquery>

	<cfif DisplayMode is "A" AND GetNewRegistrations.recordcount EQ 0>

		<TR>
			<TD colspan="11">
				<table width="100%" border="0" cellpadding=1 cellspacing=0>
					<TR>
						<TD colspan="6" class="pghdr"><br>Assessment Status</TD>
					</TR>
					<tr valign="bottom" bgcolor="cccccc">
						<TD><strong>Patron</strong></TD>
						<TD><strong>Relation</strong></TD>
						<TD><strong>Assmt Name</strong></TD>
						<TD><strong>Effective</strong></TD>
						<TD><strong>Expires</strong></TD>
						<TD><strong>Invoice</strong></TD>
					</tr>
					<cfloop query="CheckAssmtStatus">
						<cfif assmtexpires less than now() + 30>
							<cfset tmp = 'class = "BlackOnYellow"'>
						<cfelse>
							<cfset tmp = ''>
						</cfif>

						<cfquery datasource="#application.slavedopsds#" name="GetRelationType">
							SELECT   RELATIONSHIPTYPE.relationshipdesc
							FROM     patronrelations PATRONRELATIONS
							         INNER JOIN relationshiptype RELATIONSHIPTYPE ON PATRONRELATIONS.relationtype=RELATIONSHIPTYPE.relationtype
							WHERE    PATRONRELATIONS.primarypatronid = #cookie.uid#
							AND      PATRONRELATIONS.secondarypatronid = #patronid#
						</cfquery>

						<tr>
							<TD>#lastname#, #firstname# #middlename#</TD>
							<TD>#GetRelationType.relationshipdesc#</TD>
							<TD>#assmtname#</TD>
							<TD>#Dateformat(assmteffective,"mm-dd-yyyy")#</TD>
							<TD>#Dateformat(assmtexpires,"mm-dd-yyyy")#</TD>
							<TD>
								<a href="javascript:void(0);" onClick="window.open('../classes/class_summary_receipt.cfm?invoicelist=#invoicefacid#-#Invoicenumber#&p=y','receipt','toolbars=no, scrollbars=yes, resizable');">#invoicefacid#-#Invoicenumber#</a>
							</TD>
						</tr>
					</cfloop>
					<cfif CheckAssmtStatus.recordcount is 0>
						<TR>
							<TD colspan="6">No current assessments found</TD>
						</TR>
					</cfif>
				</table>

<!--- start line 467 DISABLED 			line 833 END --->

<!--- START: out of district patrons can purchase a new assessment --->
<CFIF cookie.ds EQ "Out of District">

<CFIF Isdefined("url.aid") and listfind(cookie.assmtpicks,url.aid) EQ 0>
	<!--- loop through assmtpics list to check assessment overlap before adding aid --->
	<CFQUERY name="getnewAssmtinfo" datasource="#application.slavedopsds#">
		select *
		from dops.assessmentrates
		where id = #url.aid#
	</CFQUERY>
     <!--- added cfqueryparam 11/3/2016 CR - breaks public CF9 without --->
	<CFQUERY name="getAssmtinsession" datasource="#application.slavedopsds#">
		select *
		from dops.sessionassessments
		where primarypatronid = #cookie.uID#
		and (assmteffective, assmtexpires) overlaps ( '#DateFormat( getnewAssmtinfo.assmteffective, "yyyy-mm-dd" )#', '#DateFormat( getnewAssmtinfo.assmtexpires, "yyyy-mm-dd" )#' )
	</CFQUERY>

	<cfif getAssmtinsession.recordcount eq 0>
		<CFQUERY name="InsertnewAssmt" datasource="#application.slavedopsds#">
			insert into dops.sessionassessments
			(aid, name, sessionid, primarypatronid, assmteffective, assmtexpires, grace, rate,assmtyear,assmtterm) values
			(
			<cfqueryparam cfsqltype="cf_sql_integer" value='#getnewAssmtinfo.id#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value='#getnewAssmtinfo.name#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value='#getsession.sessionid#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_integer" value='#cookie.uID#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_date" value='#getnewAssmtinfo.assmteffective#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_date" value='#getnewAssmtinfo.assmtexpires#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_integer" value='#getnewAssmtinfo.grace#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_decimal" value='#getnewAssmtinfo.rate#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_integer" value='#getnewAssmtinfo.assmtyear#' list="no">,
			<cfqueryparam cfsqltype="cf_sql_integer" value='#getnewAssmtinfo.assmtterm#' list="no">
			)
		</CFQUERY>
		<CFSET cookie.assmtpicks = listappend(cookie.assmtpicks,url.aid)>
	<cfelse>
		<script language="javascript">alert('Assessment overlap detected!')</script>
	</cfif>
</CFIF>

	<CFQUERY name="getAssmtinsession" datasource="#application.slavedopsds#">
		select *
		from dops.sessionassessments
		where primarypatronid = #cookie.uID#
		and sessionid = <cfqueryparam cfsqltype="cf_sql_varchar" value='#getsession.sessionid#' list="no">
	</CFQUERY>
	<!--- <cfdump var="#getassmtinsession#" label="sessionAssessments"> --->
<CFIF Isdefined("url.raid")>
	<CFLOOP condition="listfind(cookie.assmtpicks,url.raid) NEQ 0">
		<CFSET dindex = listfind(cookie.assmtpicks,url.raid)>
		<CFIF dindex GT 0>
			<CFQUERY name="removeassmtinsession" datasource="#application.slavedopsds#">
				delete
				from dops.sessionassessments
				where aid = <cfqueryparam cfsqltype="cf_sql_integer" value='#url.raid#' list="no">
				and sessionid = <cfqueryparam cfsqltype="cf_sql_varchar" value='#getsession.sessionid#' list="no">
			</CFQUERY>
			<CFSET cookie.assmtpicks = listdeleteat(cookie.assmtpicks,dindex)>
		</CFIF>
	</CFLOOP>
</CFIF>
<!--- <cfdump var="#cookie#"> --->
<CFSET amountDue = 0>

<!--- need to add current assessments to the exclusion list --->

<CFQUERY name="getPatronAssess" datasource="#application.slavedopsds#">
	select r.id , r.assmteffective::date as ref, r.assmtexpires::date as rep
	from assessmentrates r, assessments a
	where r.name = a.assmtname
	and a.primarypatronid = #cookie.uID#
	and a.valid = true
	and r.assmtexpires > current_date
</CFQUERY>

<cfquery name="availabeassmtlist" datasource="#application.slavedopsds#">
	select id, name,isannual,assmteffective, assmtexpires,rate
	from assessmentrates
	where assmtexpires > current_date
	<cfif getPatronAssess.recordcount gt 0>
		and not (assmteffective, assmtexpires) overlaps ('#DateFormat( getPatronAssess.ref, "yyyy-mm-dd" )#', '#DateFormat( getPatronAssess.rep, "yyyy-mm-dd" )#')
		and id != <cfqueryparam cfsqltype="cf_sql_integer" value="#getPatronAssess.id#">
	</cfif>
	<cfif cookie.assmtpicks neq 0>
		and id not in (<cfqueryparam cfsqltype="cf_sql_integer" value="#cookie.assmtpicks#" list="yes">)
	</cfif>
</CFQUERY>

<!--- <cfdump var="#availabeassmtlist#" label="availabeassmtlist"> --->
<CFIF getPatronAssess.recordcount  GT 0>
	<CFSET exclusion = valuelist(getPatronAssess.id)>
<CFELSE>
	<CFSET exclusion = 0>
</CFIF>


<CFIF cookie.assmtpicks NEQ 0 OR exclusion NEQ 0>
	<CFQUERY name="getAssmtinsession2" datasource="#application.slavedopsds#">
		select sum(rate) as totalamountDue
		from dops.sessionassessments
		where primarypatronid = #cookie.uID#
		and sessionid = <cfqueryparam cfsqltype="cf_sql_varchar" value='#getsession.sessionid#' list="no">
	</CFQUERY>
	<CFSET amountDue = getAssmtinsession2.totalamountDue>
</CFIF>



				<br><br><form action="process_assessmentBP_www.cfm" method="post">

				<table width="100%" border="0" cellpadding=1 cellspacing=0>

					<TR>
						<TD colspan="7" class="pghdr">Purchase Assessment - Available Options<br><!---(current assessment expires #Dateformat(CheckAssmtStatus.assmtexpires,"mm-dd-yyyy")#)---></TD>
					</TR>
					<tr valign="bottom" bgcolor="cccccc">
						<TD class="bodytext2">&nbsp;</TD>
						<TD class="bodytext2"><strong>Term</strong></TD>
						<TD class="bodytext2"><strong>Type</strong></TD>
						<TD class="bodytext2"><strong>Effective</strong></TD>
						<TD class="bodytext2"><strong>Expires</strong></TD>
						<TD class="bodytext2"><strong>Cost</strong></TD>
						<TD class="bodytext2"><strong>Purchase</strong></TD>
					</tr>
					<CFSET thebg="eeeeee">

					<CFIF availabeassmtlist.recordcount GT 0>
						<tr valign="bottom" bgcolor="eeeeee">
							<TD class="bodytext2">&nbsp;</TD>
							<TD colspan="6" class="bodytext2"><em>Current Term</strong></TD>
						</tr>
						<CFLOOP query="availabeassmtlist" >
						<CFIF listfind(cookie.assmtpicks,availabeassmtlist.ID) NEQ 0>
							<CFSET thestyle = "boldtext">
							<CFSET thecheck = "checked">
						<CFELSE>
							<CFSET thestyle = "bodytext3">
							<CFSET thecheck = "">
						</CFIF>
						<CFIF availabeassmtlist.recordcount EQ availabeassmtlist.currentrow AND listfind(cookie.assmtpicks,availabeassmtlist.ID) NEQ 0>
							<CFSET thestyle = "boldtext">
						<CFELSEIF availabeassmtlist.recordcount EQ availabeassmtlist.currentrow>
							<CFSET thestyle = "bodytext2">
						</CFIF>
						<tr valign="middle">
							<TD class="#thestyle#">&nbsp;<CFIF thecheck EQ "checked"><img src="../images/check.gif"></CFIF></TD>
							<TD class="#thestyle#">#name#</TD>
							<TD class="#thestyle#"><CFIF isannual EQ 0>Quarterly<CFELSE>Annual</CFIF></TD>
							<TD class="#thestyle#">#dateformat(assmteffective,'mm/dd/yyyy')#</TD>
							<TD class="#thestyle#">#dateformat(assmtexpires,'mm/dd/yyyy')#</TD>
							<TD class="#thestyle#">$#rate#</TD>
							<td class="#thestyle#"><CFIF listfind(cookie.assmtpicks,availabeassmtlist.ID) EQ 0><a href="#cgi.script_name#?aid=#id#&DisplayMode=A">Add to Cart</a><CFELSE><a href="#cgi.script_name#?raid=#id#&DisplayMode=A">Remove</a></CFIF></td>
						</tr>

						<CFIF thebg EQ "eeeeee"><CFSET thebg = "ffffff"><CFELSE><CFSET thebg="eeeeee"></CFIF>
						</CFLOOP>
					</CFIF>

					<tr><td colspan="7"><!---<a href="#cgi.script_name#?clearcookies=true&DisplayMode=A">Reset</a>---></td></tr>
				</table>
				<br>
				<CFIF amountDue GT 0>

					<!--- display session assessment --->
				<table width="100%" border="0" cellpadding=1 cellspacing=0>

					<TR>
						<TD colspan="7" class="pghdr" style="background-color:##FF9;">Selected Items<br><!---(current assessment expires #Dateformat(CheckAssmtStatus.assmtexpires,"mm-dd-yyyy")#)---></TD>
					</TR>
					<tr valign="bottom" bgcolor="cccccc">
						<TD class="bodytext2">&nbsp;</TD>
						<TD class="bodytext2"><strong>Term</strong></TD>
						<TD class="bodytext2"><strong>Type</strong></TD>
						<TD class="bodytext2"><strong>Effective</strong></TD>
						<TD class="bodytext2"><strong>Expires</strong></TD>
						<TD class="bodytext2"><strong>Cost</strong></TD>
						<TD class="bodytext2"><strong>Purchase</strong></TD>
					</tr>
				<CFLOOP query="getAssmtinsession">
						<tr valign="middle">
							<TD class="#thestyle#">&nbsp;<CFIF thecheck EQ "checked"><img src="../images/check.gif"></CFIF></TD>
							<TD class="#thestyle#">#name#</TD>
							<TD class="#thestyle#"><CFIF isannual EQ 0>Quarterly<CFELSE>Annual</CFIF></TD>
							<TD class="#thestyle#">#dateformat(assmteffective,'mm/dd/yyyy')#</TD>
							<TD class="#thestyle#">#dateformat(assmtexpires,'mm/dd/yyyy')#</TD>
							<TD class="#thestyle#">$#rate#</TD>
							<td class="#thestyle#"><a href="#cgi.script_name#?raid=#aid#&DisplayMode=A">Remove</a></td>
						</tr>
				</CFLOOP>
				</table><hr>



				<cfset lastmonth = dateadd('m','-1',now())>
				<!--- look up credit; etc --->
				<CFSET netBalance = GetAccountBalance(cookie.uID)>
				<cfset creditUsed = min(netBalance,amountDue)>
				<cfset NetToPay = max(0,amountDue - NetBalance)>
                         <input type="hidden" name="cctype" value="">
					<input type="hidden" name="ccnum1" value="">
					<input type="hidden" name="ccnum2" value="">
					<input type="hidden" name="ccnum3" value="">
					<input type="hidden" name="ccnum4" value="">
					<input type="hidden" name="ccExpMonth" value="">
					<input type="hidden" name="ccExpYear" value="">
					<input type="hidden" name="ccv" value="">
                         <input type="hidden" name="netbalance" value="#netbalance#">
					<input type="hidden" name="assessments" value="#cookie.assmtpicks#">
					<input type="hidden" name="primarypatronid" value="#cookie.uID#">
					<input type="hidden" name="creditused" value="#creditused#">
					<input type="hidden" name="amountDue" value="#(amountdue-creditused)#">

                    <DIV ALIGN="center">
                    <input type="button" class="form_input" value="Clear Selections" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;" onClick="window.location.href='index1.cfm?clearpicks=true'"> &nbsp;
                    &nbsp;&nbsp;
                    <input type="submit" class="form_input" value="Complete Purchase" style="width: 170px; height: 30px; color:##ffffff; background-color:##0000cc; font-weight:bold;" >
                    </DIV>
				</form>
				</CFIF>
			</CFIF>

<!--- END: out of district patrons can purchase a new assessment --->
			</TD>
		</TR>
	</cfif>

	<cfquery datasource="#application.slavedopsds#" name="CheckPassStatus">
		SELECT   *
		FROM     validpasses
		WHERE    primarypatronid = #cookie.uid#
		ORDER BY passtype, passexpires
	</cfquery>


<cfif DisplayMode is "A" AND GetNewRegistrations.recordcount GT 0>
		<TR>
			<TD colspan="11">
				<table width="100%" border="1" cellpadding=1 cellspacing=0>
					<TR>
						<TD colspan="6" class="pghdr"><br>Assessment Status</TD>
					</TR>
					<tr valign="bottom" bgcolor="cccccc">
						<TD><strong>Patron</strong></TD>
						<TD><strong>Relation</strong></TD>
						<TD><strong>Assmt Name</strong></TD>
						<TD><strong>Effective</strong></TD>
						<TD><strong>Expires</strong></TD>
						<TD><strong>Invoice</strong></TD>
					</tr>
					<cfloop query="CheckAssmtStatus">
						<cfif assmtexpires less than now() + 30>
							<cfset tmp = 'class = "BlackOnYellow"'>
						<cfelse>
							<cfset tmp = ''>
						</cfif>

						<cfquery datasource="#application.slavedopsds#" name="GetRelationType">
							SELECT   RELATIONSHIPTYPE.relationshipdesc
							FROM     patronrelations PATRONRELATIONS
							         INNER JOIN relationshiptype RELATIONSHIPTYPE ON PATRONRELATIONS.relationtype=RELATIONSHIPTYPE.relationtype
							WHERE    PATRONRELATIONS.primarypatronid = #cookie.uid#
							AND      PATRONRELATIONS.secondarypatronid = #patronid#
						</cfquery>

						<tr>
							<TD>#lastname#, #firstname# #middlename#</TD>
							<TD>#GetRelationType.relationshipdesc#</TD>
							<TD>#assmtname#</TD>
							<TD>#Dateformat(assmteffective,"mm-dd-yyyy")#</TD>
							<TD>#Dateformat(assmtexpires,"mm-dd-yyyy")#</TD>
							<TD>
								<a href="javascript:void(0);" onClick="window.open('../classes/class_summary_receipt.cfm?invoicelist=#invoicefacid#-#Invoicenumber#&p=y','receipt','toolbars=no, scrollbars=yes, resizable');">#invoicefacid#-#Invoicenumber#</a>&nbsp;
							</TD>
						</tr>
					</cfloop>
					<cfif CheckAssmtStatus.recordcount is 0>
						<TR>
							<TD colspan="6">No current assessments found</TD>
						</TR>
					</cfif>
				</table>
                    <br>
		<table style="padding-bottom:5px;" width="100%" border="0">
		<tr>
			<td style="background:##C00;border-width:1px;border-color:##000;border-style:solid;padding:2px;color:##FFF"><strong>PURCHASE ASSESSMENT: In order to purchase an assessment please drop all classes from your shopping cart. If you are concerned about losing a class enrollment due to high demand (particularly on opening registration day) DO NOT empty your cart - instead call the registration hotline for assistance.</td>
		</tr>
		</table>

</TD>
</TR>

</cfif>


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
</body>
<CFINCLUDE template="/portalINC/googleanalytics.cfm">
</html>
</cfoutput>

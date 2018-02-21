<CFSILENT>
<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>
<CFPARAM name="cookie.assmtpicks" default="">

<!--- <cfif 1 is 2>
call by view_patron_hist.cfm?PrimaryPatronID=#cookie.uid#&DisplayMode=<DisplayModeParam>

Use:
SELECT   DISTINCT PATRONS.PATRONID 
FROM     PATRONS PATRONS
         INNER JOIN VALIDPASSES VALIDPASSES ON PATRONS.PATRONID=VALIDPASSES.PRIMARYPATRONID
         INNER JOIN REG REG ON PATRONS.PATRONID=REG.PRIMARYPATRONID
         INNER JOIN VALIDASSESSMENTS VALIDASSESSMENTS ON PATRONS.PATRONID=VALIDASSESSMENTS.PRIMARYPATRONID
         INNER JOIN CLASSES CLASSES ON REG.TERMID=CLASSES.TERMID AND REG.FACID=CLASSES.FACID AND REG.CLASSID=CLASSES.CLASSID 
WHERE    CLASSES.ENDDT < timestamp

to see "busy" patrons for testing
</cfif> --->

<cfparam name="DisplayMode" default="M">
<!--- DisplayMode codes:
A = assessment status
P = Pass Status
R = Registrations
 --->

<cfset localfac = "WWW">
<cfset localnode = "W1">
<cfset DS = "thirst">

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


<cfquery datasource="#application.slavedopsds#" name="CountDropinHistory">
	SELECT   count(*) as tmp
	FROM     dropinhistory
	where    primaryPatronID = #cookie.uid#
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

<cfquery datasource="#application.slavedopsds#" name="GetHousehold">
	SELECT   PATRONS.patronlookup, PATRONS.lastname, PATRONS.firstname, 
	         PATRONS.middlename, PATRONS.gender, PATRONS.dob, 
	         RELATIONSHIPTYPE.relationshipdesc, PATRONRELATIONS.addressid,  patronrelations.indistrict,
	         PATRONS.patroncomment, patrons.verified, patrons.patronid, patronrelations.detachdate, patrons.instrlevela, patrons.instrlevelt
	FROM     patronrelations PATRONRELATIONS
	         INNER JOIN patrons PATRONS ON PATRONRELATIONS.secondarypatronid=PATRONS.patronid
	         INNER JOIN relationshiptype RELATIONSHIPTYPE ON PATRONRELATIONS.relationtype=RELATIONSHIPTYPE.relationtype
	where    patronRelations.PrimaryPatronid = #cookie.uid#
	and      patrons.inactive = false
	order by patronrelations.relationtype, upper(patrons.lastname), upper(patrons.firstname)
</cfquery>

<cfif GetHousehold.addressid is "">
	<strong>No history information available: PPID: #cookie.uid#</strong>
	<cfabort>
</cfif>

<cfquery datasource="#application.slavedopsds#" name="GetPatronContactData">
	SELECT   PATRONCONTACT.contactdata, CONTACTMETHOD.contactmethod, patroncontact.patronid
	FROM     patroncontact PATRONCONTACT
	         INNER JOIN contactmethod CONTACTMETHOD ON PATRONCONTACT.contacttype=CONTACTMETHOD.contacttype 
	WHERE    PATRONCONTACT.patronid in (#ValueList(GetHousehold.patronid)#)
	AND      contactmethod.contacttype in ('H','W','C')
	ORDER BY CONTACTMETHOD.listorder
</cfquery>

<cfquery name="GetAddress" datasource="#application.slavedopsds#">
	SELECT   address1, address2, city, state, zip
	FROM     patronaddresses 
	WHERE    addressid = #GetHousehold.addressid#
</cfquery>

<cfquery datasource="#application.slavedopsds#" name="GetTerms">
	select distinct termid, termname
	from terms
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



<cfif IsDefined("AcctMode")>
	<input name="AcctMode" type="hidden" value="1">
</cfif>

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

	<cfif displaymode is 'm'>
	<tr>
	<td colspan=11 class="pghdr"><br>My Household</td>
	</tr>
     

  

	<TR>
		<TD colspan="11">
		
			<table width="650" border=0	 cellpadding=3 cellspacing="0">
				<cfset showids = 1>
				<cfset showsecheader = 1>

				<cfquery name="Chk4OotherPrimaryReg" datasource="#application.slavedopsds#">
					SELECT   distinct REG.primarypatronid, PATRONS.patronlookup, reg.patronid 
					FROM     reg REG
					         INNER JOIN patrons PATRONS ON REG.primarypatronid=PATRONS.patronid 
					WHERE    REG.primarypatronid != #GetHousehold.patronid[1]#
					AND      REG.patronid in (#valuelist(GetHousehold.patronid)#)
					AND      reg.regstatus != 'V'
				</cfquery>

				<cfquery name="Chk4OotherPrimaryPass" datasource="#application.slavedopsds#">
					SELECT   distinct passmembers.primarypatronid, PATRONS.patronlookup, passmembers.patronid 
					FROM     passmembers
					         INNER JOIN patrons PATRONS ON passmembers.primarypatronid=PATRONS.patronid 
					WHERE    passmembers.primarypatronid != #GetHousehold.patronid[1]#
					AND      passmembers.patronid in (#valuelist(GetHousehold.patronid)#)
				</cfquery>

				<cfquery name="Chk4OotherPrimaryAssmt" datasource="#application.slavedopsds#">
					SELECT   distinct assessmentmembers.primarypatronid, PATRONS.patronlookup, assessmentmembers.patronid 
					FROM     assessmentmembers
					         INNER JOIN patrons PATRONS ON assessmentmembers.primarypatronid=PATRONS.patronid 
					WHERE    assessmentmembers.primarypatronid != #GetHousehold.patronid[1]#
					AND      assessmentmembers.patronid in (#valuelist(GetHousehold.patronid)#)
				</cfquery>

				<cfloop query="GetHousehold">
					<cfset TmpArray = ArrayNew(2)>
					<cfset rows = 0>

					<cfloop query="Chk4OotherPrimaryReg">

						<cfif GetHousehold.patronid[GetHousehold.currentrow] is Chk4OotherPrimaryReg.patronid[Chk4OotherPrimaryReg.currentrow]>
	
							<cfif ArrayLen(TmpArray) is 0>
								<cfset TmpArray[1][1] = primarypatronid>
								<cfset TmpArray[1][2] = patronlookup>
								<cfset rows = 1>
							<cfelse>
								<cfset DoThisOne = 0>
	
								<cfloop from="1" to="#rows#" step="1" index="n">
	
									<cfif TmpArray[n][1] is not primarypatronid>
										<cfset DoThisOne = 1>
									</cfif>
	
								</cfloop>
	
								<cfif DoThisOne is 1>
									<cfset rows = rows + 1>
									<cfset TmpArray[rows][1] = primarypatronid>
									<cfset TmpArray[rows][2] = patronlookup>
								</cfif>
	
							</cfif>

						</cfif>

					</cfloop>

					<cfset rows = 0>

					<cfloop query="Chk4OotherPrimaryPass">

						<cfif GetHousehold.patronid[GetHousehold.currentrow] is Chk4OotherPrimaryPass.patronid[Chk4OotherPrimaryPass.currentrow]>

							<cfif ArrayLen(TmpArray) is 0>
								<cfset TmpArray[1][1] = primarypatronid>
								<cfset TmpArray[1][2] = patronlookup>
								<cfset rows = 1>
							<cfelse>
								<cfset DoThisOne = 0>
	
								<cfloop from="1" to="#rows#" step="1" index="n">
	
									<cfif TmpArray[n][1] is not primarypatronid>
										<cfset DoThisOne = 1>
									</cfif>
	
								</cfloop>
	
								<cfif DoThisOne is 1>
									<cfset rows = rows + 1>
									<cfset TmpArray[rows][1] = primarypatronid>
									<cfset TmpArray[rows][2] = patronlookup>
								</cfif>
	
							</cfif>

						</cfif>

					</cfloop>

					<cfset rows = 0>

					<cfloop query="Chk4OotherPrimaryAssmt">

						<cfif GetHousehold.patronid[GetHousehold.currentrow] is Chk4OotherPrimaryAssmt.patronid[Chk4OotherPrimaryAssmt.currentrow]>

							<cfif ArrayLen(TmpArray) is 0>
								<cfset TmpArray[1][1] = primarypatronid>
								<cfset TmpArray[1][2] = patronlookup>
								<cfset rows = 1>
							<cfelse>
								<cfset DoThisOne = 0>
	
								<cfloop from="1" to="#rows#" step="1" index="n">
	
									<cfif TmpArray[n][1] is not primarypatronid>
										<cfset DoThisOne = 1>
									</cfif>
	
								</cfloop>
	
								<cfif DoThisOne is 1>
									<cfset rows = rows + 1>
									<cfset TmpArray[rows][1] = primarypatronid>
									<cfset TmpArray[rows][2] = patronlookup>
								</cfif>
	
							</cfif>

						</cfif>

					</cfloop>

					<cfif showids is 1>
						<TR bgcolor="CCCCCC">
							<TD class="lgnusr" nowrap><strong>#lastname#, #firstname# #middlename# (#patronlookup#)</strong></TD>
							<!--- <CF_HowLongHasItBeen DATE1="#DOB#" DATE2="#now()#" ADDWORDS="Yes" Abbreviated="yes"> --->
							<TD class="lgnusr" align=right>#dateformat(dob,"mm/dd/yyyy")#<!--- (#HowLong_Years#, #HowLong_Months#) ---></TD>
							<TD class="lgnusr" align=right colspan=3><strong>
							<cfif GetHousehold.InDistrict is 1>
								In District
							<cfelseif GetHousehold.verified is 0>
								To Be Verified
							<cfelse>
								Out Of District
							</cfif>
							</strong>
							</TD>
						</TR>
						<TR>
							<TD valign="top" colspan=2>
								#GetAddress.address1#<cfif GetAddress.address2 is not "">, #GetAddress.address2#</cfif>
								<br>#GetAddress.city#, #GetAddress.state# #left(GetAddress.zip,5)#
							</TD>
							<TD valign="top" colspan=3>
							<table border=0 cellpadding=1 cellspacing=0 width=400 align="right">
								<tr>
								<td rowspan="7" nowrap valign="top"><strong>Contact<br>Information</strong></td>
								</tr>
								<cfquery name="qGetEmail" datasource="#application.slavedopsds#">
									select loginemail,nocontact
									from patroninfo
									where primarypatronID = #cookie.uid#
									and patronlookup = '#patronlookup#'
								</cfquery>
								<cfset contactlist = "Home Phone,Work Phone,Cell Phone">
								<cfloop query="GetPatronContactData"><!--- loop over current contact types --->
								<tr>
								<td class="bodytext">#contactmethod#:</td>
								<td class="bodytext" align=right><cfif contactdata is not ''>#contactdata#<cfelse><em>No Entry</em></cfif></td>
								<td class="bodytext" align=right><cfif GetHousehold.patronlookup is cookie.ulogin><a href="javascript:void(0);" onClick="window.open('editcontact.cfm?type=#removechars(contactmethod,2,len(contactmethod)-1)#&pID=#patronID#','edit','width=400,height=220,statusbar=0,scrollbars=1,resizable=0');">Update</a><cfelse><img src="#request.imagedir#/spacer.gif" width="47" height="1" border="0" alt=""></cfif></td>
								</tr>
								<!--- if value exists, delete from original list --->
								<cfif listfind(contactlist,contactmethod) gt 0>
									<cfset contactlist = listdeleteat(contactlist,listfindnocase(contactlist,contactmethod))>
								</cfif>
								
								</cfloop>
								<!--- if values still in list, display for editing purposes --->
								<cfif listlen(contactlist) gt 0>
									<cfloop list="#contactlist#" index="contacttype">
										<tr>
										<td class="bodytext">#contacttype#:</td>
										<td class="bodytext" align=right><em>No Entry</em></td>
										<td class="bodytext" align=right><cfif GetHousehold.patronlookup is cookie.ulogin><a href="javascript:void(0);" onClick="window.open('editcontact.cfm?type=#removechars(contacttype,2,len(contacttype)-1)#&pID=#patronID#','edit','width=400,height=220,statusbar=0,scrollbars=1,resizable=0');">Update</a><cfelse><img src="#request.imagedir#/spacer.gif" width="47" height="1" border="0" alt=""></cfif></td>
										</tr>
									</cfloop>
								</cfif>
								<tr>
								<td class="bodytext">Portal Email:</td>
								<td class="bodytext" align=right><cfif qGetEmail.loginemail is ''><em>No Entry</em><cfelse>#listfirst(qGetEmail.loginemail)#</cfif></td>
								<td class="bodytext" align=right><cfif GetHousehold.patronlookup is cookie.ulogin><a href="javascript:void(0);" onClick="window.open('editcontact.cfm?type=E&pID=#patronID#&plkup=#patronlookup#','edit','width=400,height=250,statusbar=0,scrollbars=1,resizable=0');">Update</a><cfelse><img src="#request.imagedir#/spacer.gif" width="47" height="1" border="0" alt=""></cfif></td>
								</tr>
                                        
                                        <!--- parse aux emails from list --->
                                        <CFSET auxemails = "">
                                        <CFIF listlen(qGetEmail.loginemail) GT 1>
                                        	<CFSET auxemails = listdeleteat(qGetEmail.loginemail,1)>
                                        </CFIF>
                                        	
                                        
                                        <tr>
								<td class="bodytext">Additional Email(s):</td>
								<td class="bodytext" align=right>
									<cfif auxemails is ''>
                                             	<em>No Entry</em>
                                             <cfelse>#replacenocase(auxemails,",","<br>")#</cfif>
                                        </td>
								<td class="bodytext" align=right><cfif GetHousehold.patronlookup is cookie.ulogin><a href="javascript:void(0);" onClick="window.open('editcontact.cfm?type=EA&pID=#patronID#&plkup=#patronlookup#','edit','width=400,height=250,statusbar=0,scrollbars=1,resizable=0');">Add / Edit</a><cfelse><img src="#request.imagedir#/spacer.gif" width="47" height="1" border="0" alt=""></cfif></td>
								</tr>
                                        
                                        <tr>
								<td class="bodytext">E-announcements? </td>
								<td class="bodytext" align=right><cfif qGetEmail.nocontact is true>NO<cfelse>YES</cfif></td>
								<td class="bodytext" align=right><cfif GetHousehold.patronlookup is cookie.ulogin><a href="javascript:void(0);" onClick="window.open('editcontact.cfm?type=E&pID=#patronID#&plkup=#patronlookup#','edit','width=400,height=250,statusbar=0,scrollbars=1,resizable=0');">Update</a><cfelse><img src="#request.imagedir#/spacer.gif" width="47" height="1" border="0" alt=""></cfif></td>
								</tr>
							</table>
							</TD>
						</TR>
						<cfif patroncomment is not "">
							<TR>
								<TD colspan="4"><strong>#patroncomment#</strong></TD>
							</TR>
						</cfif>

						<cfset showids = 0>
					<cfelse>
						<cfquery name="qGetEmail" datasource="#application.slavedopsds#">
							select loginemail
							from patroninfo
							where patronlookup = '#patronlookup#'
						</cfquery>

						<cfif showsecheader is 1>
							<TR bgcolor="ededed">
								<TD colspan="5"><strong>Secondary Patrons on this Account</strong></TD>
							</TR>
							<cfset showsecheader = 0>
						</cfif>

						<tr valign="top">
							<TD>#lastname#, #firstname# #middlename# </TD>
							<TD align=right><strong>(#patronlookup#)</strong></TD>
							<TD align=right><cfif gender is "M">Male<cfelseif gender is "F">Female</cfif> #relationshipdesc# - (#dateformat(dob,"mm/dd/yyyy")#)</TD>
							<td class="bodytext" align=right><cfif qGetEmail.loginemail is ''><em>No Email on File</em><cfelse>#qGetEmail.loginemail#</cfif></td>
							<td class="bodytext" align=right><cfif patronlookup is cookie.ulogin><a href="javascript:void(0);" onClick="window.open('editcontact.cfm?type=E&pID=#patronID#&plkup=#patronlookup#','edit','width=400,height=220,statusbar=0,scrollbars=1,resizable=0');">Update</a><cfelse><img src="#request.imagedir#/spacer.gif" width="33" height="1" border="0" alt=""></cfif></td>
							
						</tr>
						<cfif detachdate is not "">
							<tr>
								<td colspan="5" align="left"><strong>Above patron scheduled to be detached on #dateformat(detachdate,"mm/dd/yyyy")#</strong></td>
							</tr>
						</cfif>

						<cfif ArrayLen(TmpArray) is not 0>
							<TR>
								<TD colspan="5">
									<strong>Other Primaries w/ History:</strong>
									<cfloop from="1" to="#ArrayLen(TmpArray)#" step="1" index="n">
										#TmpArray[n][2]#
									</cfloop>
								</TD>
							</TR>
						</cfif>

					</cfif>

				</cfloop>
		
          <tr><td colspan="11"></td></tr>		
     	<tr>
          	<td colspan="11" style="background:##FF9;border-width:1px;border-color:##000;border-style:solid;padding:2px;color:##000"><strong>Notice: To add a new member to your household please VISIT one of the <a target="_blank" href="http://www.thprd.org/contact/directory.cfm"><strong>district's centers</strong></a> in person, so we can verify credentials. </strong>

               </td>
          </tr>

			</table>


			<!---
			<!--- family assistance --->
			
			<!--- does not seem to work with card type 1 || difference between balance and cardbalance --->
			
			<CFQUERY name="getFAbalance" datasource="#application.reg_dsn#">
				SELECT   secondarypatronid,p.firstname,p.lastname,
						 dops.getfapatronbalancepit(patronrelations.primarypatronid, patronrelations.secondarypatronid, now()::timestamp) as balance, (
				 
				select   faapps.apptype
				from     dops.faapps
				where    faapps.primarypatronid = patronrelations.primarypatronid
				and      faapps.status = 'G') as apptype, (
				 
				SELECT   othercredithistorysums.sumnet 
				FROM     othercredithistorysums othercredithistorysums
						 INNER JOIN faapps faapps ON othercredithistorysums.cardid=faapps.cardidtoload 
				WHERE    faapps.primarypatronid = #cookie.uid# 
				AND      faapps.status = 'G') as cardbalance
				 
				FROM     dops.patronrelations, dops.patrons p
				WHERE primarypatronID = #cookie.uid#
				AND secondarypatronid = p.patronid
			</CFQUERY>

			
			<CFIF getFAbalance.recordcount GT 0>
				<br><span class="sectionhdr">Family Assistance</span><br><br>
				
				<CFLOOP query="getFAbalance">
					
					#firstname# #lastname# <em>#secondarypatronid#</em> - #balance# #cardbalance# #apptype#<br>
					
				</CFLOOP>
				
			</CFIF>
			--->
		</TD>
	</TR>
	</cfif>
     
     <cfif displaymode is 'l'>
	<tr>
	<td colspan=11 class="pghdr"><br>My Household</td>
	</tr>
     

  

	<TR>
		<TD colspan="11">
		
			<table width="650" border=0	 cellpadding=3 cellspacing="0">
				<cfset showids = 1>
				<cfset showsecheader = 1>

					<TR bgcolor="ededed">
								<TD colspan="5" style="color:##FFF;background:##390;font-size:12px;"><strong>Aquatic & Tennis Levels</strong></TD>
							</TR>
							
						
                              <tr valign="top">
							<TD class="bodytext"><strong>Member Name</strong></TD>
							<TD class="bodytext" align=right><strong>ID</strong></TD>
							<TD class="bodytext" align=right><strong>Birthday</strong></TD>
							<td class="bodytext" align=right><strong>Aquatic Level</strong></td>
							<td class="bodytext" align=right><strong>Tennis Level</strong></td>
						</tr>


				<cfloop query="GetHousehold">
                    
						

						
							
						<tr valign="top">
							<TD>#lastname#, #firstname# #middlename#</TD>
							<TD align=right>#patronlookup#</TD>
							<TD align=right>#dateformat(dob,"mm/dd/yyyy")#</TD>
							<td class="bodytext" align=right><CFIF trim(instrlevela) EQ "">N/A<CFELSE>#trim(instrlevela)#</CFIF></td>
							<td class="bodytext" align=right><CFIF trim(instrlevelt) EQ "">N/A<CFELSE>#trim(instrlevelt)#</CFIF></td>
						</tr>


					

				</cfloop>
		
			          <tr><td colspan="5"></td></tr>		
     	<tr>
          	<td colspan="5" style="background:##FF9;border-width:1px;border-color:##000;border-style:solid;padding:2px;color:##000"><strong>To update an aquatic or tennis level please call the appropriate recreation center. 'N/A' indicates that the level has not been assigned by a THPRD instructor or other staff.</strong>

               </td>
          </tr>

			</table>

		</TD>
	</TR>
	</cfif>
     
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
							<TD colspan="5">No current assessments found</TD>
						</TR>
					</cfif>
				</table>

<!--- start line 467 DISABLED 			line 833 END --->

<!--- START: out of district patrons can purchase a new assessment --->				
<CFIF cookie.ds EQ "Out of District">

<!--- start set up for assessments; this should be on it own page --->
<!--- handle assessment selections --->
<CFIF NOT Isdefined("cookie.assmtpicks") or Isdefined("url.clearpicks") or trim(cookie.assmtpicks) EQ "">
	<CFSET cookie.assmtpicks = 0>
</CFIF>

<CFIF Isdefined("url.aid") and listfind(cookie.assmtpicks,url.aid) EQ 0>
	<CFSET cookie.assmtpicks = listappend(cookie.assmtpicks,url.aid)>
</CFIF>

<CFIF Isdefined("url.raid")>
	<CFLOOP condition="listfind(cookie.assmtpicks,url.raid) NEQ 0">
		<CFSET dindex = listfind(cookie.assmtpicks,url.raid)>
		<CFIF dindex GT 0>
			<CFSET cookie.assmtpicks = listdeleteat(cookie.assmtpicks,dindex)>
		</CFIF>
	</CFLOOP>
</CFIF>

<CFSET amountDue = 0>

<!--- need to add current assessments to the exclusion list --->

<CFQUERY name="getPatronAssess" datasource="#application.slavedopsds#">
	select r.id 
	from assessmentrates r, assessments a
	where r.name = a.assmtname
	and a.primarypatronid = #cookie.uID#
	and a.valid = true
</CFQUERY>

<CFIF getPatronAssess.recordcount  GT 0>
	<CFSET exclusion = valuelist(getPatronAssess.id)>
<CFELSE>
	<CFSET exclusion = 0>
</CFIF>

<CFIF cookie.assmtpicks NEQ 0 OR exclusion NEQ 0>	
	<cfquery datasource="#application.slavedopsds#" name="getdates">
		select * from assessmentrates where id in (#cookie.assmtpicks#,<CFIF trim(exclusion) NEQ "">#exclusion#<cfelse>0</cfif>)
	</cfquery>
	<!--- loop through what they already have and what they want to purchase to eliminate overlaps --->
	<CFLOOP query="getdates">
		
		<CFIF getdates.isannual EQ 0>
		<!--- exclude annuals for quarter starting on same day --->
			<CFQUERY name="qtr" datasource="#application.slavedopsds#">
				select id from assessmentrates
				where assmteffective = '#dateformat(getdates.assmteffective,"yyyy-mm-dd")#'
				and id not in (#cookie.assmtpicks#) and id not in (<CFIF trim(exclusion) NEQ "">#exclusion#<cfelse>0</cfif>)
			</CFQUERY>
			<CFIF qtr.recordcount gt 0>
				<CFSET exclusion = listappend(exclusion,valuelist(qtr.id))>
			</CFIF>
		<!--- exclude annuals overlapping this quarter --->
			<CFQUERY name="qtr2" datasource="#application.slavedopsds#">
				select id from assessmentrates
				where assmteffective < '#dateformat(getdates.assmteffective,"yyyy-mm-dd")#' 
				and assmtexpires >= '#dateformat(getdates.assmtexpires,"yyyy-mm-dd")#'
				and isannual is true
				and id not in (#cookie.assmtpicks#) and id not in (<CFIF trim(exclusion) NEQ "">#exclusion#<cfelse>0</cfif>)
			</CFQUERY>
			<CFIF qtr2.recordcount gt 0>
				<CFSET exclusion = listappend(exclusion,valuelist(qtr2.id))>
			</CFIF>
			
		<CFELSE>
		<!--- exclude quarters contained by annual --->
			<CFQUERY name="annual" datasource="#application.slavedopsds#">
				select id from assessmentrates
				where assmteffective >= '#dateformat(getdates.assmteffective,"yyyy-mm-dd")#'
				and assmtexpires <= '#dateformat(getdates.assmtexpires,"yyyy-mm-dd")#'
				and id not in (#cookie.assmtpicks#) and id not in (<CFIF trim(exclusion) NEQ "">#exclusion#<cfelse>0</cfif>)
			</CFQUERY>
			<CFIF annual.recordcount gt 0>
				<CFSET exclusion = exclusion & "," & valuelist(annual.id,",")>
			</CFIF>
			<!--- exclude annuals overlapping this annual --->
			<CFQUERY name="annual2" datasource="#application.slavedopsds#">
				select id from assessmentrates
				where isannual is true and
				assmteffective < '#dateformat(getdates.assmtexpires,"yyyy-mm-dd")#'
				and id not in (#cookie.assmtpicks#) and id not in (0<CFIF trim(exclusion) NEQ "">#exclusion#<cfelse>,0</cfif>)
			</CFQUERY>
			
			<CFIF annual2.recordcount gt 0>
				<CFSET exclusion = exclusion & "," & valuelist(annual2.id,",")>
			</CFIF>
		</CFIF>
		<!--- only add value if it is a date they have selected --->
		<CFIF listfind(cookie.assmtpicks,getdates.id) GT 0>	
			<CFSET amountDue = amountDue + getdates.rate>
		</CFIF>
	</CFLOOP>
	<!---<CFOUTPUT>#exclusion#<br></CFOUTPUT>--->
</CFIF>
<!--- end set up for assessments --->
				
				<cfquery datasource="#application.slavedopsds#" name="getNextAssess">
					select p.primarypatronID, p.patronlookup, p.firstname, p.lastname, p.indistrict, p.loginstatus, p.detachdate, 		
					p.relationtype, p.logindt, p.insufficientID, p.verifyexpiration, a.assmtexpires
					from patroninfo p, assessments a
					where p.patronlookup = '#cookie.ulogin#'
					and p.primarypatronid = a.primarypatronid
					and detachdate is null	
					and a.valid = true
					order by a.assmtexpires desc
					limit 1 
				</cfquery>			
				<!--- no previous assessments --->
				<CFSET therefdate = '1900-01-01'>
				<!--- previous assessments --->
				<CFIF getNextAssess.recordcount GT 0>
					<CFSET therefdate = dateformat(getNextAssess.assmtexpires,'yyyy-mm-yy')>
				</CFIF>
				<!--- selected assessments --->
				
				
				
				<cfquery datasource="#application.slavedopsds#" name="getassessinfo">
					select * from assessmentrates
					where ((assmteffective > now() and isannual is false)
					OR  
					(assmteffective > now() and isannual is true))
					and available is true
					order by isannual,assmteffective asc
				</cfquery>	
				
				<!---this is lame!--->
				<CFQUERY name="getNextTerms" dbtype="query" maxrows="2">
					select * from getassessinfo
					where assmteffective > #now()#
					order by assmteffective,isannual asc
				</CFQUERY>
				
				<CFQUERY name="getNext" dbtype="query" maxrows="2">
					select * from getNextTerms
					where assmteffective > #now()# AND assmteffective > '#therefdate#' 
					<CFIF exclusion NEQ 0 and trim(exclusion) NEQ "">and id not in (#exclusion#)</CFIF>
					order by assmteffective,isannual asc
				</CFQUERY>
				
				<CFQUERY name="getCurrentPre" datasource="#application.slavedopsds#" maxrows="2">
					select * from assessmentrates
					where assmteffective < #now()# and assmtexpires > #now()#
					<CFIF exclusion NEQ 0 and trim(exclusion) NEQ "">and id not in (#exclusion#)</CFIF>
					order by assmteffective desc,isannual asc
				</CFQUERY>
				
				<!--- make current term match first record of above query --->
				<CFIF getCurrentPre.recordcount GT 0>
					<CFSET therefdate = dateformat(getCurrentPre.assmteffective,'yyyy-mm-yy')>
				</CFIF>
				
				<!--- filter  --->
				<CFQUERY name="getCurrent" dbtype="query" >
					select * from getCurrentPre
					where assmteffective >= '#therefdate#' 
					<CFIF exclusion NEQ 0 and trim(exclusion) NEQ "">and id not in (#exclusion#)</CFIF>
					order by assmteffective desc,isannual asc
				</CFQUERY>
				
				<!--- filter  --->
				<CFQUERY name="allOthers" dbtype="query" >
					select * from getassessinfo
					<CFIF exclusion NEQ 0 and trim(exclusion) NEQ "">where id not in (#exclusion#)</CFIF>
					order by assmteffective asc,isannual asc
				</CFQUERY>
				
				
				<br><br><form action="finishassessment.cfm" method="post">
				
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
					
					<CFIF getCurrent.recordcount GT 0>
						<tr valign="bottom" bgcolor="eeeeee">
							<TD class="bodytext2">&nbsp;</TD>
							<TD colspan="6" class="bodytext2"><em>Current Term</strong></TD>
						</tr>
						<CFLOOP query="getCurrent" >
						<CFIF listfind(cookie.assmtpicks,getCurrent.ID) NEQ 0>
							<CFSET thestyle = "boldtext">
							<CFSET thecheck = "checked">
						<CFELSE>
							<CFSET thestyle = "bodytext3">
							<CFSET thecheck = "">
						</CFIF>
						<CFIF getCurrent.recordcount EQ getCurrent.currentrow AND listfind(cookie.assmtpicks,getCurrent.ID) NEQ 0>
							<CFSET thestyle = "boldtext">
						<CFELSEIF getCurrent.recordcount EQ getCurrent.currentrow>
							<CFSET thestyle = "bodytext2">
						</CFIF>
						<tr valign="middle">
							<TD class="#thestyle#">&nbsp;<CFIF thecheck EQ "checked"><img src="../images/check.gif"></CFIF></TD>
							<TD class="#thestyle#">#name#</TD>
							<TD class="#thestyle#"><CFIF isannual EQ 0>Quarterly<CFELSE>Annual</CFIF></TD>
							<TD class="#thestyle#">#dateformat(assmteffective,'mm/dd/yyyy')#</TD>
							<TD class="#thestyle#">#dateformat(assmtexpires,'mm/dd/yyyy')#</TD>
							<TD class="#thestyle#">$#rate#</TD>
							<td class="#thestyle#"><CFIF listfind(cookie.assmtpicks,getCurrent.ID) EQ 0><a href="#cgi.script_name#?aid=#id#&DisplayMode=A">Add to Cart</a><CFELSE><a href="#cgi.script_name#?raid=#id#&DisplayMode=A">Remove</a></CFIF></td>
						</tr>
						
						<CFIF thebg EQ "eeeeee"><CFSET thebg = "ffffff"><CFELSE><CFSET thebg="eeeeee"></CFIF>
						</CFLOOP>
					</CFIF>					
					
					<CFIF getNext.recordcount GT 0>
						<tr valign="middle" bgcolor="eeeeee" >
							<TD class="bodytext2">&nbsp;</TD>
							<TD colspan="6" class="bodytext2"><em>Next Term</em></TD>
						</tr>
						<CFLOOP query="getNext">
						<CFIF listfind(cookie.assmtpicks,getNext.ID) NEQ 0>
							<CFSET thestyle = "boldtext">
							<CFSET thecheck = "checked">
						<CFELSE>
							<CFSET thestyle = "bodytext3">
							<CFSET thecheck = "">
						</CFIF>
						<CFIF getNext.recordcount EQ getNext.currentrow AND listfind(cookie.assmtpicks,getNext.ID) NEQ 0>
							<CFSET thestyle = "boldtext">
						<CFELSEIF getNext.recordcount EQ getNext.currentrow>
							<CFSET thestyle = "bodytext2">
						</CFIF>
						<tr valign="middle">
							<TD class="#thestyle#">&nbsp;<CFIF thecheck EQ "checked"><img src="../images/check.gif"></CFIF></TD>
							<TD class="#thestyle#">#name#</TD>
							<TD class="#thestyle#"><CFIF isannual EQ 0>Quarterly<CFELSE>Annual</CFIF></TD>
							<TD class="#thestyle#">#dateformat(assmteffective,'mm/dd/yyyy')#</TD>
							<TD class="#thestyle#">#dateformat(assmtexpires,'mm/dd/yyyy')#</TD>
							<TD class="#thestyle#">$#rate#</TD>
							<td class="#thestyle#"><CFIF listfind(cookie.assmtpicks,getNext.ID) EQ 0><a href="#cgi.script_name#?aid=#id#&DisplayMode=A">Add to Cart</a><CFELSE><a href="#cgi.script_name#?raid=#id#&DisplayMode=A">Remove</a></CFIF></td>
						</tr>
						<CFIF thebg EQ "eeeeee"><CFSET thebg = "ffffff"><CFELSE><CFSET thebg="eeeeee"></CFIF>
						</CFLOOP>
					</CFIF>
					
					<CFSET thebg="eeeeee">
					
					<tr valign="bottom" bgcolor="eeeeee" >
						<TD class="bodytext2">&nbsp;</TD>
						<TD colspan="6" class="bodytext2"><em>Other Terms</em></TD>
					</tr>
					<CFLOOP query="allOthers">
						<CFIF listfind(cookie.assmtpicks,allOthers.ID) NEQ 0>
							<CFSET thestyle = "boldtext">
							<CFSET thecheck = "checked">
						<CFELSE>
							<CFSET thestyle = "bodytext3">
							<CFSET thecheck = "">
						</CFIF>
						<CFIF allOthers.recordcount EQ allOthers.currentrow AND listfind(cookie.assmtpicks,allOthers.ID) NEQ 0>
							<CFSET thestyle = "boldtext">
						<CFELSEIF allOthers.recordcount EQ allOthers.currentrow>
							<CFSET thestyle = "bodytext2">
						</CFIF>
						<CFIF listfind(valuelist(getNext.id,","),id) EQ 0 AND listfind(valuelist(getNext.id,","),id) EQ 0>
							<tr valign="middle">
								<TD class="#thestyle#">&nbsp;<CFIF thecheck EQ "checked"><img src="../images/check.gif"></CFIF></TD>
								<TD class="#thestyle#">#name#</TD>
								<TD class="#thestyle#"><CFIF isannual EQ 0>Quarterly<CFELSE>Annual</CFIF></TD>
								<TD class="#thestyle#">#dateformat(assmteffective,'mm/dd/yyyy')#</TD>
								<TD class="#thestyle#">#dateformat(assmtexpires,'mm/dd/yyyy')#</TD>
								<TD class="#thestyle#">$#rate#</TD>
								<td class="#thestyle#"><CFIF listfind(cookie.assmtpicks,allothers.ID) EQ 0><a href="#cgi.script_name#?aid=#id#&DisplayMode=A">Add to Cart</a><CFELSE><a href="#cgi.script_name#?raid=#id#&DisplayMode=A">Remove</a></CFIF></td>
							</tr>
							<CFIF thebg EQ "eeeeee"><CFSET thebg = "ffffff"><CFELSE><CFSET thebg="eeeeee"></CFIF>
						</CFIF>
					</CFLOOP>
					<CFIF allOthers.recordcount EQ 0>
					<tr valign="bottom">
						<td>&nbsp;</td>
						<TD colspan="6" class="greentext"><strong>There are no other assessments available for your account.</strong></TD>
					</tr>
					</CFIF>
					<tr><td colspan="7"><!---<a href="#cgi.script_name#?clearcookies=true&DisplayMode=A">Reset</a>---></td></tr>
				</table>
				<br>
				<CFIF amountDue GT 0>
				<cfset lastmonth = dateadd('m','-1',now())>
				<!--- look up credit; etc --->
				<CFSET netBalance = GetAccountBalance(cookie.uID)>
				<cfset creditUsed = min(netBalance,amountDue)>
				<cfset NetToPay = max(0,amountDue - NetBalance)>
				<table border="0" cellspacing="1" cellpadding="2">
					<TR>
					<td class="bodytext" colspan="2" valign=top nowrap bgcolor="FFFFCC"><cfset lastmonth = dateadd('m','-1',now())>
					<cfif nettopay gt 0><!--- only show cc fields if there is a non-credit balance --->
					<strong>Please enter payment information:</strong><br>
						<select name="ccType" class="form_input">
							<option value="V">Visa</option>
							<option value="MC">MasterCard</option>
							<option value="DISC">Discover</option>
						</select>
						<input name="ccNum1" size="4" type="password" maxlength="4" class="form_input">-<input name="ccNum2" size="4" type="password" maxlength="4" class="form_input">-<input name="ccNum3" size="4" type="password" maxlength="4" class="form_input">-<input name="ccNum4" size="4" type="password" maxlength="4" class="form_input"><br>
						<select name="ccExpMonth" class="form_input">
							<cfloop from="1" to="12" step="1" index="q">
								<option value="#numberformat(q,"00")#" <cfif month(lastmonth) is q>selected</cfif>>#numberformat(q,"00")#
							</cfloop>
						</select>
						<select name="ccExpYear" class="form_input">
							<option value="#year(dateadd('yyyy','-1',now()))#">#year(dateadd('yyyy','-1',now()))#</option>
							<cfloop from="0" to="9" step="1" index="q"><!--- allow 10 years ahead --->
								<option value="#year(now()) + q#">#year(now()) + q#
							</cfloop>
						</select>
						<br><a href="javascript:void(0);" onClick="window.open('../classes/ccv.cfm','ccv','width=340, height=400, toolbar=no, scrollbars=yes, noresize');">CCV Number</a> (back of credit card)&nbsp;&nbsp;&nbsp;<input name="ccv" size="3" type="Text" maxlength="3" class="form_input">
					<cfelse><!--- patron had more credit than amount due, just pass fields to satisfy processing --->
					You have a $0.00 balance - no credit card needed.
						<input type="hidden" name="cctype" value="">
						<input type="hidden" name="ccnum1" value="">
						<input type="hidden" name="ccnum2" value="">
						<input type="hidden" name="ccnum3" value="">
						<input type="hidden" name="ccnum4" value="">
						<input type="hidden" name="ccExpMonth" value="">
						<input type="hidden" name="ccExpYear" value="">
						<input type="hidden" name="ccv" value="">
					</cfif>
					</TD>
					<td bgcolor="FFFFCC">&nbsp;</td>
					<td class="bodytext" align="right" colspan=2 valign=top nowrap bgcolor="FFFFCC">Account Starting Balance<br>
					 Total Fees<br>
					 Credit Used<br>
					 Amount Due<br>
					 <strong>Account Ending Balance</strong><br>
					</TD>
					<td bgcolor="FFFFCC">&nbsp;</td>
					<td class="bodytext" align="right" valign=top bgcolor="FFFFCC">#numberformat(NetBalance,"999,999.99")# <br>
					#numberformat(amountDue,"999,999.99")# <br>
					#numberformat(CreditUsed,"999,999.99")# <br>
					<span class="bodytext_red">#numberformat(NetToPay,"999,999.99")#</span> <br>
					<span class="bodytex"><strong>#numberformat(NetBalance - CreditUsed,"999,999.99")#</strong></span>
					</TD>
					<input type="hidden" name="netbalance" value="#netbalance#">
					<input type="hidden" name="assessments" value="#cookie.assmtpicks#">
					<input type="hidden" name="primarypatronid" value="#cookie.uID#">
					<input type="hidden" name="creditused" value="#creditused#">
					<input type="hidden" name="amountDue" value="#amountdue#">
					</TR>
					<tr>
						<td colspan=7 align="right"><input type="button" class="form_input" value="Clear Selections" onClick="location.href='#cgi.script_name#?clearpicks=true&Displaymode=A';"> <input type="submit" class="form_input" value="Complete Purchase"></td>
						<td>&nbsp;</td>
					</tr>			
				</table>
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

	<cfif DisplayMode is "P">
		<TR>
			<TD colspan="11" class="pghdr"><br>Pass Status</TD>
		</TR>
		<TR>
			<TD colspan="11">
				<table width="650" border="0" cellpadding=1 cellspacing=0>

			
					<tr valign="bottom" bgcolor="cccccc">
						<TD><strong>Invoice</strong></TD>
						<TD><strong>Patron</strong></TD>
						<TD nowrap><strong>Date Added</strong></TD>
						<TD><strong>Pass Type</strong></TD>
						<TD nowrap><strong>Remaining Punches</strong></TD>
						<TD><strong>Expires</strong></TD>
					</tr>
					<cfloop query="CheckPassStatus">

						<cfquery datasource="#application.slavedopsds#" name="GetPassDetails">
							select   *
						    from     validpasses
						    WHERE    primarypatronid = #PrimaryPatronID#
						    AND      patronid = #PatronID#
						    and      ec = #CheckPassStatus.ec[currentrow]#
						</cfquery>
						<cfif GetPassDetails.recordcount is not 0>

							<cfloop query="GetPassDetails">

								<cfif GetPassDetails.passexpires less than now() + 7>
									<cfset tmp = 'class = "BlackOnYellow"'>
								<cfelse>
									<cfset tmp = ''>
								</cfif>

								<cfif (CheckPassStatus.passallocation[CheckPassStatus.currentrow] is 0) or (CheckPassStatus.passallocation[CheckPassStatus.currentrow] is not 0 and CheckPassStatus.passuses[CheckPassStatus.currentrow] is not CheckPassStatus.passallocation[CheckPassStatus.currentrow])>

									<cfquery datasource="#application.slavedopsds#" name="GetPatronData">
										select lastname, firstname, middlename
			 							from patrons
										where patronid = #GetPassDetails.PatronID#
									</cfquery>

									<tr >
										<TD nowrap><cfset str1 = CheckPassStatus.InvoiceFacID[CheckPassStatus.currentrow] & "-" & CheckPassStatus.InvoiceNumber[CheckPassStatus.currentrow]><a href="../classes/class_summary_receipt.cfm?invoicelist=#str1#" target="_blank">#str1#</a></TD>
										<TD nowrap>#GetPatronData.lastname#, #GetPatronData.firstname# #GetPatronData.middlename#</TD>
										<TD  nowrap>#Dateformat(GetPassDetails.dtadded,"mm-dd-yyyy")#</TD>
										<TD nowrap>
											<cfquery datasource="#application.slavedopsds#" name="GetPassData2">
												SELECT   passdescription
												FROM     passtype
												WHERE    passtype = '#CheckPassStatus.passtype[CheckPassStatus.CurrentRow]#'
											</cfquery>
			
											#GetPassData2.passdescription#
										</TD>
										<TD nowrap>
											<cfif CheckPassStatus.passallocation[CheckPassStatus.currentrow] is not 0 and CheckPassStatus.passuses[CheckPassStatus.currentrow] is not CheckPassStatus.passallocation[CheckPassStatus.currentrow]>
												#CheckPassStatus.passallocation[CheckPassStatus.currentrow] - CheckPassStatus.passuses[CheckPassStatus.currentrow]#
											</cfif>
										</TD>
										<TD nowrap>#Dateformat(GetPassDetails.passexpires,"mm-dd-yyyy")#</TD>
									</tr>
								</cfif>
							</cfloop>

						</cfif>
					</cfloop>
				</table>
			</TD>
		</TR>

	</cfif>

	<cfquery datasource="#application.slavedopsds#" name="GetCurrentRegistrations">
		SELECT   Reg.*, Classes.Description, Classes.StartDT, Classes.EndDT, Classes.suncount, Classes.moncount,Classes.tuecount,Classes.wedcount,Classes.thucount,Classes.fricount,Classes.satcount,Classes.gdc,
		         patrons.lastname, patrons.firstname, patrons.middlename, Terms.TermName, 
		         regstatuscodes.StatusDescription, reg.deferred, reg.deferredpaid,reg.regid,
		         reg.regstatus, reg.queuedfordrop, facilities.name as facname
		FROM     Reg 
		         INNER JOIN Classes Classes ON Reg.TermID=Classes.TermID AND Reg.FacID=Classes.FacID AND Reg.ClassID=Classes.ClassID
		         INNER JOIN patrons patrons ON Reg.PatronID=patrons.PatronID
		         INNER JOIN Terms Terms ON Reg.TermID=Terms.TermID AND Reg.FacID=Terms.FacID
		         INNER JOIN regstatuscodes regstatuscodes ON Reg.regstatus=regstatuscodes.StatusCode
		         inner join facilities on reg.facid = facilities.facid
		WHERE    reg.PrimaryPatronID = #cookie.uid#
		AND      reg.RegStatus in ('E','W','A','R','H')
		AND      Classes.EndDT >= now()
		and      exists(
		         select   pk
		         from     reghistory
		         where    primarypatronid = reg.primarypatronid
		         and      regid = reg.regid
		         and      invoicenumber is not null
		         )
		ORDER BY patrons.lastname, patrons.firstname, reg.termid, reg.classid
	</cfquery>
	
	<cfif DisplayMode is "R">
		<TR>
			<TD colspan="8" class="pghdr"><br>Current Registrations</TD>
			<td colspan="3" align="right" valign="top"><a href="javascript:window.print();">Print</a></td>
		</TR>
		<TR>
			<TD colspan="11">
				<table border="0" width="750" cellpadding="3" cellspacing="0">

					<TR valign="bottom" bgcolor="cccccc">
						<TD><strong>Class ID</strong></TD>
						<TD colspan=2><strong>Class Name</strong></TD>
						<TD><strong>Date(s)</strong></TD>
						<TD><strong>Time</strong></TD>
						<TD><strong>Day(s)</strong></TD>
						<TD><strong>Facility</strong></TD>
						<TD><strong>Patron</strong></TD>
						<TD><strong>Status</strong></TD>
					</TR>
					<cfloop query="GetCurrentRegistrations">
						 <cfset tmpweekdays = "">
						 <cfif suncount is 0><cfset tmpweekdays = tmpweekdays & ""><cfelse><cfset tmpweekdays = tmpweekdays & "/Su"></cfif>
						 <cfif moncount is 0><cfset tmpweekdays = tmpweekdays & ""><cfelse><cfset tmpweekdays = tmpweekdays & "/M"></cfif>
						 <cfif tuecount is 0><cfset tmpweekdays = tmpweekdays & ""><cfelse><cfset tmpweekdays = tmpweekdays & "/T"></cfif>
						 <cfif wedcount is 0><cfset tmpweekdays = tmpweekdays & ""><cfelse><cfset tmpweekdays = tmpweekdays & "/W"></cfif>
						 <cfif thucount is 0><cfset tmpweekdays = tmpweekdays & ""><cfelse><cfset tmpweekdays = tmpweekdays & "/Th"></cfif>
						 <cfif fricount is 0><cfset tmpweekdays = tmpweekdays & ""><cfelse><cfset tmpweekdays = tmpweekdays & "/F"></cfif>
						 <cfif satcount is 0><cfset tmpweekdays = tmpweekdays & ""><cfelse><cfset tmpweekdays = tmpweekdays & "/S"></cfif>
						 
						 <cfif len(tmpweekdays) is not 0>
						  <cfset tmpweekdays = right(tmpweekdays,len(tmpweekdays)-1)>
						 </cfif>
						 
						 <!--- consolidate day of week --->
						 <cfif tmpweekdays is "M/T/W/Th/F">
						  <cfset tmpweekdays = "M-F">
						 <cfelseif tmpweekdays is "M/T/W/Th">
						  <cfset tmpweekdays = "M-Th">
						 <cfelseif tmpweekdays is "M/T/W">
						  <cfset tmpweekdays = "M-W">
						 </cfif>					
						<TR valign="top">
							<TD>#ClassID#</TD>
							<TD colspan=2>#Description#</TD>
							<td>#dateformat(startdt,'m/dd/yy')#<cfif dateformat(startdt,'mm/dd/yyyy') is not dateformat(enddt,'mm/dd/yyyy')> - #dateformat(enddt,'m/dd/yy')#</cfif></td>
							<td>#timeformat(startdt,'h:mm tt')#-#timeformat(enddt,'h:mm tt')#</td>
							<td>#tmpweekdays#</td>
							<TD>#facname#</TD>
							<TD>#lastname#, #firstname# #middlename#</TD>
							<TD>
								<cfif RegStatus is "E">
									Enrolled
								<cfelseif RegStatus is "W">
									Wait List
								<cfelseif RegStatus is "A">
									Alert
								<cfelseif RegStatus is "R">
									Reserved
								<cfelseif RegStatus is "H">
									Hold
								</cfif>
	
								<cfif deferred is 1>(Def)</cfif>
								<cfif depositonly is 1>(Dep)</cfif>
							</TD>
						</TR>
					</cfloop>
				</table>
			</TD>
		</TR>
		<TR>
			<TD colspan="11">
				<table border="0"  cellpadding="3" cellspacing="0">
					<TR>
						<TD class="pghdr" colspan="2"><br>Class Documents</TD>
					</TR>
					<CFLOOP query="getCurrentRegistrations">
						<CFIF trim(getCurrentRegistrations.gdc) EQ ''>
							<CFSET thegdc = 0>
						<CFELSE>
							<CFSET thegdc = getCurrentRegistrations.gdc>
						</CFIF>
						<CFQUERY name="getDocs" datasource="#application.common_dsn#">
							select d.*,r.*,u.docfolder
							from documents d, documentsref r, documentsusagelist u
							where d.docid = r.docid
							and r.docusage = u.usagecode
							and r.gdc = #thegdc#
							and r.showonweb IS true
							order by d.docfilename
						</CFQUERY>
						<CFIF getDocs.recordcount GT 0>
						<TR valign="top">
							<TD valign="top">#getCurrentRegistrations.Description#</TD>
							<td>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td>
							<td valign="top"><CFLOOP query="getDocs"><a target="new" href="classdoc.cfm?docid=#getDocs.docid#">#getDocs.doctitle#</a></CFLOOP></td>
						</TR>
							
						</CFIF>
					</CFLOOP>
				</table>
			</TD>
		</TR>
       <TR>
			<TD colspan="11" ><br><div class="pghdr" style="padding-left:3px;">Drop Class</div><div style="padding-left:3px;">All drops/cancellations must be made in person or by phone. Please call or visit the appropriate facility hosting the class or activity to drop or cancel a class.</div></TD>
			
		</TR>
	</cfif>

<!---
	<cfquery datasource="#application.reg_dsn#" name="GetAccountHistory">
		SELECT   Activity.Debit, Activity.Credit, Invoice.PrimaryPatronID,activity.passmodification,
		         Activity.TermID, Activity.FacID, Activity.Activity, activity.regid,
		         Activity.InvoiceFacID, Activity.InvoiceNumber, activity.patronid,
		         Patrons.lastname, Patrons.firstname, patrons.middlename, Invoice.DT, 
		         Activity.ActivityCode, Invoice.startingbalance, invoice.printable,
		         Invoice.TotalFees, Invoice.TenderedCash, invoice.cca, invoice.cced, invoice.ccv,
		         Invoice.TenderedCheck, Invoice.TenderedCC, Invoice.TenderedChange, invoice.ccType,
		         Activity.IsMiscFee, activity.activitycode, invoice.cashoutid, Activitycodes.Activitydescription,
		         invoice.newcredit, userlogin, userlast, userfirst, invoice.isvoided,
		         Activity.deferred, Activity.depositonly, Activity.overridden, activity.upgradetype,
		         coalesce(invoice.userid,0) as userid, classes.description as class_desc
		FROM     Activity Activity
		         INNER JOIN Invoice Invoice ON Activity.InvoiceFacID=Invoice.InvoiceFacID AND Activity.InvoiceNumber=Invoice.InvoiceNumber
		         INNER JOIN Patrons Patrons ON Patrons.PatronID=Activity.PatronID
		         LEFT OUTER JOIN thusers ON invoice.userid=thusers.userid
		         LEFT OUTER JOIN activitycodes ON Activity.ActivityCode=activitycodes.activitycode
		         LEFT OUTER JOIN classes ON activity.termid=classes.termid AND activity.facid=classes.facid AND activity.activity=classes.classid
		WHERE    activity.PrimaryPatronID = #cookie.uid#
		AND
					<cfif IsDefined("ShowLimit")>
						date_part('year',invoice.dt) * 12 + date_part('month',invoice.dt) between #left(ShowLimit,5)# and #right(ShowLimit,5)#
					<cfelse>
						current_date - date(invoice.dt) <= 200
					</cfif>
		ORDER BY Invoice.DT desc, activity.line
		limit 100
	</cfquery>
--->

	<cfquery datasource="#application.reg_dsn#" name="GetAccountHistory">
			SELECT   *, invoicenet as endingbalance
 			FROM     dops.invoicenet invoice
 			WHERE    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
 			and isvoided = false
			<!---and istempnumber = false--->
		
		AND
					<cfif IsDefined("ShowLimit")>
						date_part('year',invoice.dt) * 12 + date_part('month',invoice.dt) between #left(ShowLimit,5)# and #right(ShowLimit,5)#
					<cfelse>
						current_date - date(invoice.dt) <= 200
					</cfif>
		ORDER BY Invoice.DT desc
		limit 100
	</cfquery>


	<cfif GetCurrentBalance.RecordCount is not 0>
		<cfset NetBalance = GetCurrentBalance.startingbalance+GetCurrentBalance.newcredit+GetCurrentBalance.TenderedCash+GetCurrentBalance.TenderedCheck+GetCurrentBalance.TenderedCC-GetCurrentBalance.TenderedChange-GetCurrentBalance.TotalFees>
	</cfif>

	<cfset ThisInvoice = 0>
	<cfset ThisFac = "">

	<cfif DisplayMode is "I">
<form method="post" action="patronhistory.cfm?PrimaryPatronID=#cookie.uid#">
<cfif isdefined('displaymode')>
	<input name="displaymode" type="hidden" value="#displaymode#">
</cfif>
	<tr>
		<td colspan="7" class="pghdr"><br>Invoice History</td>
		<td colspan="4" align=right valign="botton"><br>
			<select  name="ShowLimit" class="form_input" > of data.
				<cfset ThisMonth2 = month(now())>
				<cfset ThisYear2 = year(now())>
				<cfset ThisMonth1 = ThisMonth2 - 6>
				<cfset ThisYear1 = ThisYear2>

				<cfif ThisMonth1 lt 1>
					<cfset ThisMonth1 = ThisMonth1 + 12>
					<cfset ThisYear1 = ThisYear1 - 1>
				</cfif>

				<cfset LastMonth = datediff("m","2004-02-01",now())>

				<cfloop from="0" to="#LastMonth#" step="1" index="n">
					<option <cfif IsDefined("ShowLimit") and ShowLimit is ThisYear1 * 12 + ThisMonth1 & "-" & ThisYear2 * 12 + ThisMonth2>selected</cfif> value="#ThisYear1 * 12 + ThisMonth1#-#ThisYear2 * 12 + ThisMonth2#">#numberformat(ThisMonth1,'00')#/#ThisYear1# to #numberformat(ThisMonth2,'00')#/#ThisYear2# 
					<cfset ThisMonth1 = ThisMonth1 - 1>

					<cfif ThisMonth1 lt 1>
						<cfset ThisMonth1 = ThisMonth1 + 12>
						<cfset ThisYear1 = ThisYear1 - 1>
					</cfif>

					<cfset ThisMonth2 = ThisMonth2 - 1>

					<cfif ThisMonth2 lt 1>
						<cfset ThisMonth2 = ThisMonth2 + 12>
						<cfset ThisYear2 = ThisYear2 - 1>
					</cfif>
					<CFIF n EQ 2><option value="24145-24157">All 2012</option></CFIF>
                         
				</cfloop>
                    
			</select>
			<input type="Submit" value="View Other Invoices" class="form_submit">
			
			</TD>
		</TR>
	<tr>
	<td colspan="11" valign="top">
		<table border=0 cellpadding=3 cellspacing="0" width=670>
		
		<!--- <cfif IsDefined("netbalance") and NetBalance is not "">
			<TR>
				<TD colspan="5" align="right"><strong>Account Balance</strong></TD>
				<TD colspan="2" align="right"><strong>#DecimalFormat(NetBalance)#</strong></TD>
			</TR>
		</cfif> --->
	
		<tr bgcolor="cccccc">
		<td class="bodytext"><strong>Invoice Number</strong></td>
		<td class="bodytext" align=right><strong>Invoice Date</strong></td>
		<td class="bodytext" align=right><strong>Starting Balance</strong></td>
		<td class="bodytext" align=right><strong>Ending Balance</strong></td>
		</tr>
		<cfloop query="GetAccountHistory">
	
			<cfif IsVoided is 0 or IsDefined("AcctMode")>
				<cfif InvoiceFacID is not ThisFac or InvoiceNumber is not ThisInvoice>
					<cfset RunningDedit = 0>
					<cfset RunningCredit = 0>
					<cfset ThisInvoice = InvoiceNumber>
					<cfset ThisFac = InvoiceFacID>
					<!--- cfset EndingBalance = startingbalance+newcredit+TenderedCash+TenderedCheck+TenderedCC+othercreditused-TenderedChange-TotalFees --->
					<cfset str1 = GetAccountHistory.InvoiceFacID & "-" & GetAccountHistory.InvoiceNumber>
					<TR valign="top">
						<td class="bodytext">
							<cfif printable is 1>
								<a href="javascript:void(0);" onClick="window.open('../classes/class_summary_receipt.cfm?invoicelist=#GetAccountHistory.InvoiceFacID#-#GetAccountHistory.InvoiceNumber#&p=y','receipt','toolbars=no, scrollbars=yes, resizable');">#GetAccountHistory.InvoiceFacID#-#GetAccountHistory.InvoiceNumber#</a>
							</cfif>
						</td>
						<td class="bodytext" align=right>#DateFormat(DT,"mm/dd/yyyy")#</td>
						<td class="bodytext" align=right>$ #DecimalFormat(startingbalance)#</td>
						<td class="bodytext" align=right>$ #DecimalFormat(EndingBalance)#</td>
					</TR>
				</cfif>
		</cfif>
		</cfloop>
		</table>
	</td>
	
	</tr>
	</form>	
	</cfif>
     
<cfif DisplayMode is "A" AND GetNewRegistrations.recordcount GT 0>
		
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
							<TD colspan="5">No current assessments found</TD>
						</TR>
					</cfif>
				</table>
                    <br>
                    		<table style="padding-bottom:5px;" width="100%">
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

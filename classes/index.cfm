<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3&page=classes.index">
	<cfabort>
</cfif>

<!--- check open call --->
<CFINCLUDE template="/portalINC/checkopencall.cfm">

<!--- add routine to check and if necessary redefine cookies if we are returning from checkout; add referring page --->
<CFIF Isdefined("form.checkoutcomplete")>

	<!--- if the cookie was lost restore credentials; NOTE sessionid is only stored in the db  --->
     <CFIF not Isdefined("cookie.uid")>
     <cfquery name="Patron" datasource="#application.dopsds#">
               select   primarypatronID, patronlookup, firstname, lastname, 
                          indistrict, loginstatus, detachdate, loginemail,
                          relationtype, logindt, insufficientID, 
                          verifyexpiration, locked
               from     patroninfo 
               where    (patronlookup = '#ucase(form.patronlookup)#')
               and     loginstatus = 1
               and     detachdate is null
     </cfquery>
     
     <cfcookie name="ufname" value="#Patron.firstname#"><!--- first name --->
     <cfcookie name="ulname" value="#Patron.lastname#"><!--- last name --->
     <cfcookie name="ulogin" value="#form.patronlookup#">
     <cfcookie name="uemail" value="#Patron.loginemail#"><!--- login --->
     <cfcookie name="expirationdate" value="#Patron.verifyexpiration#"><!--- expiration --->
     <cfcookie name="uID" value="#Patron.primarypatronID#">
     <!--- district status --->
     <cfif Patron.indistrict is False>
          <cfcookie name="ds" value="Out of District">
     <cfelse>
          <cfcookie name="ds" value="In District">
     </cfif>
     
     </CFIF>

</CFIF>



<!--- <cfset dopsds = application.reg_dsn> --->
<cfset CallingProgram = "index.cfm">
<cfset bg = "E2E2E2">

<cfoutput>
<html>
<head>
<title>Tualatin Hills Park and Recreation District</title>
<META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
<META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE">
<meta http-equiv="Content-Type" content="text/html;">
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">

<table border="0" cellpadding="0" cellspacing="0" width="750">
	
	<tr>
		<td valign=top>
   			<table border=0 cellpadding=2 cellspacing=0 width=749>
					<tr>
						<td colspan=3 class="pghdr">
						<!--- start header --->
						<CFINCLUDE template="/portalINC/dsp_header.cfm">
						<!--- end header --->
						</td>
					</tr>
				<tr>
					<td valign=top>
						<table border=0 cellpadding=2 cellspacing=0>
							<tr>
								<td><img src="/portal/images/spacer.gif" width="130" height="1" border="0" alt=""></td>
							</tr>
							<tr>
								<td valign=top nowrap class="lgnusr">
								<!--- start nav --->
								<cfinclude template="/portalINC/admin_nav_classes.cfm">
								<!--- end nav --->
								</td>
							</tr>		
						</table>		
					</td>
					<td valign=top colspan=2 class="bodytext" align=left>
					
					<!--- START CLASS CONTENT --->
					
			<!--- looks for content - displays check back msg if current content not available --->

			<!--- stop user if has pending conversions --->
			<cfquery name="GetCurrentWLRegistrations" datasource="#application.dopsds#">
				select   reg.regid
				from     dops.sessionregconvert
				         inner join dops.reg on sessionregconvert.primarypatronid = reg.primarypatronid and sessionregconvert.regid = reg.regid
				where    sessionregconvert.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
				and      reg.regstatus in (
					<cfqueryparam value="R" cfsqltype="cf_sql_char" maxlength="1" list="no">,
					<cfqueryparam value="H" cfsqltype="cf_sql_char" maxlength="1" list="no"> )
			</cfquery>

			<cfif GetCurrentWLRegistrations.recordcount gt 0>
				Currently there are #GetCurrentWLRegistrations.recordcount# pending class conversions. Click the Pay Balance link below to complete them before adding new classes.
				<cfabort>
			</cfif>

			<!--- set to true if running new code --->
			<TABLE WIDTH="755" border=0 cellpadding="1" cellspacing="0">
				<!--- new code --->
				<cfif not IsDefined("cookie.uID")>
					No user currently logged in
					<cfabort>
				</cfif>

				<cfset primarypatronid = cookie.uID>
				<!---<cfset CurrentSessionID = GetSessionID(primarypatronid)>--->
				<CFSET CurrentSessionID = "">
				
				<cfinclude template="classescommon.cfm">

				<!---
				<cfif CurrentSessionID is "">
					No session detected for logged in user. Try clicking <strong>Class Search</strong> or logout/login again. 
					<!---<cfabort>--->
				</cfif>
				--->

				<cfif IsDefined("dc") and dc is not "">
					<cfinclude template="dropclass.cfm">
				</cfif>

				<form action="queryclasses.cfm" name="f" method="post" onSubmit="return false;">
				<input type="Hidden" valid="#primarypatronid#" name="primarypatronid">

				<!--- to prevent CR submitting page 
				<input type="submit" onClick="return false" style="display:none; width: 0px; height: 0px;" >--->

				<!--- drop class --->
				<cfinclude template="dropclass.cfm">

				<tr  ><td valign=top class="bodytext" align=left>
				<!---<CFIF cookie.insession EQ "true"></CFIF>--->
				<cfinclude template="shownewregcheckout.cfm">
               	#shoppingcart#
				
					

					<!--- <cfquery name="csqGetMessage" datasource="#application.dsn#ro" cachedwithin="#CreateTimeSpan(0,0,1,0)#">
						select   m_status, m_message
						from     th_messages
						where    m_id = 2
					</cfquery> --->

					<!--- <cfif csqGetMessage.m_status is 2>
						<TR>
							<TD colspan="36" align="center"><BR><BR><BR>
								<cfoutput>#csqGetMessage.m_message#</cfoutput><BR><BR><BR><BR><BR><BR><BR>
								<cfinclude template="#request.includes#/footer.cfm">
								<cfabort>
							</TD>
						</TR>
					</cfif> --->

			   	<table border=0 cellpadding=2 cellspacing=0 width="100%">
					<tr>
						<td class="sectionhdr" colspan="4">Search by Class Number&nbsp;&nbsp;&nbsp;<span style="font-size: x-small;">(Enter class(es) to search, e.g.: AL31000 AL31001 AL31002) &nbsp; <A HREF="javascript:void(window.open('searchhelp.cfm','','width=500,height=500,statusbar=0,scrollbars=1,resizable=1'))">Search Help</A> </span> </td>
					</tr>

					<tr>
					<td valign=top colspan=4 class="bodytext" align="left">
					<!--- looks for content - displays check back msg if current content not available --->
					<div ID="searchsection">
						<TABLE border="0"  cellpadding="1" cellspacing="0">
						<tr>
						<td >
						<input name="offset" type="Hidden" value="0">
						<input name="getclasses" type="Hidden" value="">
						<textarea name="classlist" wrap="virtual" style="width: 400px;" rows="1" class="form_input"><cfif IsDefined("classlist")>#classlist#</cfif></textarea></td>
						<cfparam name="SelectSearchTerm" default="">
						<cfparam name="SelectSearchTermClassMode" default="">

						<cfif SelectSearchTerm is "">
							<cfset SelectSearchTerm = csGetAllAvailTerms.termid>
							<!---
							<cfloop query="csGetAllAvailTerms">
								<cfif now() gt startdt and now() lt enddt>
									<cfset SelectSearchTerm = termid>
									<cfbreak>
								</cfif>
							</cfloop>
							--->
						</cfif>

						<cfif SelectSearchTermClassMode is "">
							<cfset SelectSearchTerm = csGetAllAvailTerms.termid>
							<!---
							<cfloop query="csGetAllAvailTerms">
								<cfif now() gt startdt and now() lt enddt>
									<cfset SelectSearchTerm = termid>
									<cfbreak>
								</cfif>
							</cfloop>
							--->
						</cfif>

						<!--- <select name="SelectSearchTermClassMode"  class="form_input">
							<cfoutput>
							<cfloop query="csGetAllAvailTerms">
								<option value="#termid#" <cfif IsDefined("SelectSearchTermClassMode") and termid is SelectSearchTermClassMode>selected</cfif>>#TermName#
							</cfloop>
							</cfoutput>
						</select> --->
						<td width="20">&nbsp;</td>
						<td valign="middle">
						&nbsp;&nbsp;&nbsp;&nbsp;<input type="button" name="submitter" value="Search By Number" class="formsub3" style="width: 150px;" onClick="document.f.getclasses.value='Search By Number';document.f.action='queryclasses.cfm';document.f.submit();">
						&nbsp;&nbsp;&nbsp;&nbsp;
						
						</td>
						</tr>
						</table>
						</div>


<TABLE WIDTH="100%" border="0" cellpadding="0" cellspacing="0" >
						<TR>
							<TD colspan=4 align="center">
								<table width="100%" >
									<TR>
										<TD width="45%"><hr color="f58220" width=100% align="center" size="5px"></TD>
										<TD align="center" style="font-size: larger;"><strong color="f58220">OR</strong></TD>
										<TD width="45%"><hr color="f58220" width=100% align="center" size="5px"></TD>
									</TR>
								</table>
							</TD>
						</TR>

						

						<tr>
							<td  colspan="5" ><span class="sectionhdr">Advanced Class Search</span> <A style="margin-left:20px;" HREF="javascript:void(window.open('searchhelp.cfm','','width=500,height=500,statusbar=0,scrollbars=1,resizable=1'))">Search Help</A></td>
						</tr>	
												<tr>
							<td  colspan="5" ><div style="margin-bottom:5px;">Ineligible patrons and patrons already enrolled in a matched class will be <strong>excluded</strong> from search results.</div></td>
						</tr>		

						<TR>
							<TD colspan="2" valign="top" >
							
							<cfparam name="SearchMode" default="all">
							<div ID="searchsection" style="margin-right:5px;height:82px;">
										<table border="0" width="98%">
				<tr>
					<td valign="top" style="padding-top:5px;padding-bottom:15px"><strong>Select Term</strong> </td>
					<td valign="middle" style="padding-bottom:15px">			
			<cfset isselected = 0>
<cfloop query="csGetAllAvailTerms">
			<cfoutput>
               <CFIF datecompare(now(),websearchavailable) GTE 0>
				<input type="radio" name="SelectSearchTerm" value="#termid#" <CFIF isselected EQ 1 or csGetAllAvailTerms.recordcount EQ 1>checked</CFIF>> #TermName#
				<cfset isselected = 1>
               <CFELSE>
               	<input type="radio" disabled> #termname# &nbsp;<img onClick="alert('#termname#\n\nOnline Search Available: #dateformat(websearchavailable,'mmm d, yyyy')#\nIn-District Registration: #dateformat(startdt,'mmm d, yyyy')# at 8:00 a.m.\nOut-of-District Registration: #dateformat(allowoddt,'mmm d, yyyy')# at 8:30 a.m.');" src="/portal/images/questionmark.gif" align="texttop" border="0" title="Search Available #dateformat(websearchavailable,'mmm d, yyyy')# || In-District Registration: #dateformat(startdt,'mmm d, yyyy')# at 8:00 a.m. || Out-of-District Registration: #dateformat(allowoddt,'mmm d, yyyy')# at 8:30 a.m.">
               </CFIF>
			</cfoutput>
			</cfloop>
			
			    	</td>
                    <!---
					<td rowspan="2" valign="top">
					<INPUT TYPE="radio" NAME="SearchMode" value="all" align="absmiddle" <cfif SearchMode is "All">checked</cfif>>All Words<br>
			<INPUT TYPE="radio" NAME="SearchMode" value="any" <cfif SearchMode is "any">checked</cfif>>Any Word<br>
			<INPUT TYPE="radio" NAME="SearchMode" value="phrase" <cfif SearchMode is "phrase">checked</cfif>>Exact Phrase<br></td>
			--->
				</tr>
				
                    
                    <tr>
					<td valign="top"><strong>Keywords</strong></td>
					<td valign="top" ><INPUT TYPE="text" NAME="keywords" class="form_input" style="width: 95%" <cfif IsDefined("keywords")>value="<CFOUTPUT>#keywords#</CFOUTPUT>"</cfif> onBlur="ga('send','event', 'PortalClassSearchKeyword', 'FormEntry', this.value);"><br>
                         <INPUT TYPE="radio" NAME="SearchMode" value="all" align="absmiddle" <cfif SearchMode is "All">checked</cfif>>All Words
			<INPUT TYPE="radio" NAME="SearchMode" value="any" <cfif SearchMode is "any">checked</cfif>>Any Word
			<INPUT TYPE="radio" NAME="SearchMode" value="phrase" <cfif SearchMode is "phrase">checked</cfif>>Exact Phrase
                         </td>
				</tr>
				
			</table></div>
			
			
			
							</td>
							<td valign="top"><div ID="searchsection" style="height:82px;margin-right:5px;"><strong>Search By Class Level</strong><br>Aquatics, Diving & Tennis<br><select name="SelectClassLevel" class="form_input" style="margin-top:5px;">
				<option value="">Any

				<cfloop query="csGetClassLevels">
					<cfoutput><option value="#leveltext#" <cfif SelectClassLevel is leveltext>selected</cfif>>#leveltext#</cfoutput>
				</cfloop>
				</select>
				<input type="hidden" name="SelectClassType" value="">   

</div></td>
							<td valign="top"><div ID="searchsection" style="height:82px;"><strong>Search By Class Dates</strong>
<table cellpadding="0" cellspacing="0" border="0">
			<tr>
				<td></td>
				<td><select name="startm1" class="form_input">
		<option value=""></option>
		<option value="01">Jan</option>
		<option value="02">Feb</option>
		<option value="03">Mar</option>
		<option value="04">Apr</option>
		<option value="05">May</option>
		<option value="06">Jun</option>
		<option value="07">Jul</option>
		<option value="08">Aug</option>
		<option value="09">Sep</option>
		<option value="10">Oct</option>
		<option value="11">Nov</option>
		<option value="12">Dec</option>
	</select>
	<select name="startd1" class="form_input">
		<option value=""></option>
		<CFLOOP from="1" to="31" index="i"><CFOUTPUT><option value="#i#">#i#</option></CFOUTPUT></CFLOOP>
	</select>
	<select name="starty1" class="form_input">
		<option value=""></option>
		<CFOUTPUT><option value="#year(now())#">#year(now())#</option>
		<option value="#year(now())+1#">#year(now())+1#</option></CFOUTPUT>
	</select><br></td>
			</tr>
			<tr><td colspan="2" align="center" style="font-size:11px;"><b>to</b></td></tr>
			<tr>
				<td></td>
				<td><select name="endm1" class="form_input">
		<option value=""></option>
		<option value="01">Jan</option>
		<option value="02">Feb</option>
		<option value="03">Mar</option>
		<option value="04">Apr</option>
		<option value="05">May</option>
		<option value="06">Jun</option>
		<option value="07">Jul</option>
		<option value="08">Aug</option>
		<option value="09">Sep</option>
		<option value="10">Oct</option>
		<option value="11">Nov</option>
		<option value="12">Dec</option>
	</select>
	<select name="endd1" class="form_input">
		<option value=""></option>
		<CFLOOP from="1" to="31" index="i"><CFOUTPUT><option value="#i#">#i#</option></cfoutput></CFLOOP>
	</select>
	<select name="endy1" class="form_input">
		<option value=""></option>
		<CFOUTPUT><option value="#year(now())#">#year(now())#</option>
		<option value="#year(now())+1#">#year(now())+1#</option></CFOUTPUT>
	</select></td>
			</tr>
		</table></div></td>
						</TR>
						
						
				
						
						
						
						<TR>
							<TD width="200" valign="top" nowrap  >
								
							<div ID="searchsection" style="margin-right:5px;">
								<strong>Search By Facility</strong> (select all that apply)
								<cfset adj = 1>
								&nbsp;&nbsp;&nbsp;<A href="javascript:;" onClick="<cfloop query="csGetFacilities">document.f.SelectFacility[#currentrow-adj#].selected=false;</cfloop>">Clear</A>
								<br>

								<select name="SelectFacility" size="9" multiple class="form_input"  style="width: 270px;">
					
									<cfloop query="csGetFacilities">
										<cfoutput><option value="'#facid#'" <cfif IsDefined("SelectFacility") and Find(facid, SelectFacility) gt 0>selected</cfif>>#altname#</cfoutput>
									</cfloop>
					
								</SELECT>
								</div>

								<cfif IsDefined("IncludeInstructor")><cfset t2 = "checked"><cfelse><cfset t2 = ""></cfif>
								<div ID="searchsection" style="margin-right:5px;"><!--- <input #t2# type="Checkbox" name="IncludeInstructor"> ---><strong>Search By Instructors</strong>
								<!--- &nbsp;&nbsp;&nbsp;<A href="javascript:;" onClick="document.f.SelectInstructor.option[0].selected=true;">Clear</A> --->
					
								<select NAME="SelectInstructor" class="form_input" style="width: 270px;">
									<option value="" selected>#StringPad("All Instructors", 15)#
					
									<cfloop query="csGetInstructors">
										<cfoutput><option value="#InstructorID#"<cfif IsDefined("SelectInstructor") and Find(InstructorID, SelectInstructor) gt 0> selected</cfif>>#name#</cfoutput><BR>
									</cfloop>
					
								</select>
								</div>
								<cfparam name="WeekdayInclusion" default="Any">
							</TD>
							<TD valign="top" nowrap width="0" >
							
							<div ID="searchsection" style="margin-right:5px;"><strong>Restrict Search To</strong><BR>
					
					<table  border="0" cellspacing="0" cellpadding="1">
						
					
					
								<cfloop query="GetPatrons">
								<tr>
							<td width="20" c>
									<input <cfif (IsDefined("IncludeDOB") and Find(dateformat(dob, "yyyymmdd"), IncludeDOB) gt 0) or not IsDefined("IncludeDOB")>checked</cfif> name="IncludeDOB" value="#dateformat(dob, "yyyymmdd")#_#secondarypatronid#" type="Checkbox" style="margin:0px;padding:0px;">
							</td><td ><a href="javascript:void(0);" onClick="alert('Levels - <cfif instrlevela is not "">Aquatics: #instrlevela#; </cfif> 
									<cfif instrleveld is not "">Diving: #instrleveld#;</cfif> 
									<cfif instrlevelt is not "">Tennis: #instrlevelt#;</cfif>  ');">#left(firstname,15)#</a><br>
									
									</td>
						</tr>
								</cfloop>
								</table>
								</div>

								<!--- <cfif isDefined("hadlevels")>
									<BR><BR>Levels denoted by<BR>
									<strong>(A)</strong> = Aquatics<BR>
									<!--- <strong>(D)</strong> = Diving<BR> --->
									<strong>(T)</strong> = Tennis
								</cfif> --->
					
							</TD>
							<TD  valign="top" width="0%" class="bodytext" nowrap><div ID="searchsection" style="margin-right:5px;"><strong>Search By Day</strong><br>
							
							
							<table cellpadding="1" cellspacing="0">
				<tr>
					<td>
								<input type="checkbox" name="CBSun" <cfif IsDefined("CBSun")>checked</cfif>>Sunday<BR>
								<input type="checkbox" name="CBMon" <cfif IsDefined("CBMon")>checked</cfif>>Monday<BR>
								<input type="checkbox" name="CBTue" <cfif IsDefined("CBTue")>checked</cfif>>Tuesday<BR>
								<input type="checkbox" name="CBWed" <cfif IsDefined("CBWed")>checked</cfif>>Wednesday<BR>
								<input type="checkbox" name="CBThu" <cfif IsDefined("CBThu")>checked</cfif>>Thursday<BR>
								<input type="checkbox" name="CBFri" <cfif IsDefined("CBFri")>checked</cfif>>Friday<BR>
								<input type="checkbox" name="CBSat" <cfif IsDefined("CBSat")>checked</cfif>>Saturday</td>
								<td valign="middle">
								<input type="Radio" name="WeekdayInclusion" value="Any" <cfif WeekdayInclusion is "Any">checked</cfif>>Any<br>
								<input type="Radio" name="WeekdayInclusion" value="All" <cfif WeekdayInclusion is "All">checked</cfif>>All
								</td>
								</tr>
								</table>
								
								</div>
								
								<div id="searchsection" style="margin-right:5px;"><strong>Search By Time of Day</strong><br>
								<input type="checkbox" name="tod" value="0|11" <cfif IsDefined("tod") and Find("0|11", tod) gt 0>checked</cfif>>&nbsp;Morning (6am-12pm)<BR>
								<input type="checkbox" name="tod" value="12|17" <cfif IsDefined("tod") and Find("12|17", tod) gt 0>checked</cfif>>&nbsp;Afternoon (12pm-6pm)<br>
								<input type="checkbox" name="tod" value="18|24" <cfif IsDefined("tod") and Find("18|24", tod) gt 0>checked</cfif>>&nbsp;Evening (After 6pm)</div>
							</TD>
				
							<!--- if number of input selects are changed also change the query builder to account for the change --->
							<TD valign="top" ><div ID="searchsection">
								<strong>Sort Results By:</strong><BR>
								<cfparam name="ViewOrder" default="classid">
								<INPUT TYPE="radio" NAME="ViewOrder" value="classid" <cfif ViewOrder is "classid">checked</cfif>>Class Number<BR>
								<INPUT TYPE="radio" NAME="ViewOrder" value="description" <cfif ViewOrder is "description">checked</cfif>>Class Name<BR><BR>
								<input name="includestarted" <cfif IsDefined("includestarted")>checked</cfif> type="Checkbox">Include Already Started<BR>
								<input name="includecompleted" <cfif IsDefined("includecompleted")>checked</cfif> type="Checkbox">Include Completed/Canceled<BR>
								<input name="ignoreage" <cfif IsDefined("ignoreage")>checked</cfif> type="Checkbox">Ignore Patron Age<BR>
								<input name="notfilled" <cfif IsDefined("notfilled")>checked</cfif> type="Checkbox">Suppress Filled<BR>
								<input name="nowaitlists" <cfif IsDefined("nowaitlists")>checked</cfif> type="Checkbox">Suppress Waitlisted<BR><BR>
								<div align="center"><input type="button" name="submitter2" value="Search For Classes" class="formsub3" style="width: 150px;" onClick="document.f.getclasses.value='Search For Classes';document.f.action='queryclasses.cfm';document.f.submit();"></div></div>
								
							</TD>
						</TR>
					</TABLE>
				</td>
				</form>

					</td>
				</tr>
			</table>
	
		</td>
    </tr>
	</table>
	<hr color="f58220" width=100% align="center" size="5px">
	</td>
	</tr>
	
	<tr>
		<td colspan="3"><img src="#request.imagedir#/spacer.gif" width="1" height="11" border="0" alt=""></td>
	</tr>
<cfinclude template="/portalINC/footer.cfm">
</table>
</cfoutput>




<CFINCLUDE template="/portalINC/googleanalytics.cfm">



</body>
</html>
<!---
<CFIF cgi.remote_addr EQ "192.168.164.187">
<CFDUMP var="#csGetAllAvailTerms#">
</CFIF>
--->

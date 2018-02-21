<CFSETTING showdebugoutput="yes">
<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
</cfif>

<!--- get docs that currently appear on public web page --->
<CFSET thepageID = "1012">
     <cfquery name="docs" datasource="#application.contentdsro#">
                    select d.*,l.*,coalesce(l.sortorder,0) as thesortorder
                    from www_documents d, www_documents_location l
                    where l.contentid = <cfqueryparam value="#thepageID#" cfsqltype="cf_sql_integer"> 
                    and d.id = l.documentid
                    and d.status = true
                    and (l.documentid = 0 OR ( d.neverexpires = true OR d.expires > now() ) )
                    order by thesortorder asc, d.starts desc, d.name
     </cfquery>

<!--- set to developer mode if IS pcs --->
<cfset IsInDevMode = 0>

<cfif Find(REMOTE_HOST, "'192.168.160.92', '192.168.160.97'") gt 0>
	<cfset IsInDevMode = 1>
</cfif>

<cfset content = "contentds">
<cfparam name="primarypatronid" default="#cookie.uID#">
<cfparam name="huserid" default="0">
<cfparam name="SelectAppType" default="0">
<cfparam name="SelectFacility" default="AC">
<cfparam name="localfac" default="WWW">

<cfif primarypatronid gt 0 and (not IsDefined("patrons") and IsDefined("ProceedToProcess"))>
	<strong>No patron(s) were defined. At lease one patron must be checked.</strong>
	<cfabort>
</cfif>

<cfquery datasource="#application.contentdsro#" name="GetAppTypeLeagueFees" >
	SELECT   facid, typecode, description, fee, offershirt, assmtcheckdate, maxqty, startdate - cast(maxagemonths || ' months' as interval) as mindob,
startdate - cast(minagemonths || ' months' as interval) as maxdob, (

	SELECT   coalesce(count(*), 0)
	FROM     content.th_league_enrollments_view
	WHERE    th_league_enrollments_view.leaguetype = th_leaguetype.typecode 
	AND      th_league_enrollments_view.valid 
	AND      not th_league_enrollments_view.isvoided) as enrolledcount

	FROM     th_leaguetype 
	WHERE    facid = <cfqueryparam value="#SelectFacility#" cfsqltype="CF_SQL_VARCHAR">
	and      available
	and      current_date between startdate and cutoffdate
	ORDER BY description
</cfquery>

<CFQUERY name="leagueages" dbtype="query" maxrows="1">
	select   mindob AS themaxage
	from     GetAppTypeLeagueFees
	order by maxdob asc
</CFQUERY>

<cfset OfferShirts = 0>

<cfloop query="GetAppTypeLeagueFees">

	<cfif offershirt is 1>
		<cfset OfferShirts = 1>
		<cfbreak>
	</cfif>

</cfloop>



<cfquery datasource="#application.dopsdsro#" name="GetPatrons">
	SELECT   patronrelations.primarypatronid,
     	    patronrelations.secondarypatronid, 
	         secondary.lastname, 
	         secondary.firstname, 
	         secondary.middlename, 
	         secondary.gender,
              secondary.dob
	FROM     patronrelations 
	         INNER JOIN patrons primarypatron ON patronrelations.primarypatronid=primarypatron.patronid
	         INNER JOIN patrons secondary ON patronrelations.secondarypatronid=secondary.patronid
	WHERE    patronrelations.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
</cfquery>

<cfquery datasource="#application.contentdsro#" name="GetLeaguePatronShirtSizes" cachedwithin="#CreateTimeSpan(0,0,10,0)#">
	SELECT   sizecode, sizedescription 
	FROM     th_shirtsize
	where    displayorder > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
	order by displayorder
</cfquery>

<cfquery datasource="#application.contentdsro#" name="GetSchools1" >
	SELECT   th_schools.schoolname, th_schoolsmiddle.schoolname AS middle, 
	         th_schoolshigh.schoolname AS high, th_schoolfeeders.schoolid, 
	         th_schoolfeeders.feederms, th_schoolfeeders.feederhs, 0 as rn
	FROM     th_schoolfeeders th_schoolfeeders
	         INNER JOIN th_schools th_schools ON th_schoolfeeders.schoolid=th_schools.id
	         INNER JOIN th_schools th_schoolsmiddle ON th_schoolfeeders.feederms=th_schoolsmiddle.id
	         INNER JOIN th_schools th_schoolshigh ON th_schoolfeeders.feederhs=th_schoolshigh.id 
	WHERE    th_schoolfeeders.feederms > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER"> 
	AND      th_schoolfeeders.feederhs > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">  
	ORDER BY th_schools.schoolname, th_schoolshigh.schoolname, th_schoolsmiddle.schoolname
</cfquery>



<cfloop query="GetSchools1">
	<cfset QuerySetCell(GetSchools1, "rn", 1000 + currentrow, currentrow)>
</cfloop>



<CFQUERY name="getleaguereg" datasource="#application.contentdsro#">
	select   l.*,lt.description
	from     th_league_enrollments l, th_leaguetype lt
	where    l.patronid IN (#valuelist(GetPatrons.secondarypatronid)#,0)
	and      l.leaguetype = lt.typecode
	and      l.valid
     and 	    current_date < enddate
     order by lt.description	
</CFQUERY>

<!--- check for primary having asesessment for Winter if OD --->
<cfquery datasource="#application.dopsds#" name="CheckForNeedOfAssessment">
	SELECT   patronrelations.pk 
	FROM     patronrelations patronrelations
	         INNER JOIN patrons patrons ON patronrelations.primarypatronid=patrons.patronid 
	WHERE    patronrelations.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
	AND      patronrelations.indistrict
	AND      not patrons.insufficientid
	limit    1
</cfquery>




<cfif CheckForNeedOfAssessment.recordcount is 0>

	<cfquery datasource="#application.dopsds#" name="CheckForAssessment">
		select   pk
		from     assessments
		where    primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		and      <cfqueryparam value="#GetAppTypeLeagueFees.assmtcheckdate#" cfsqltype="CF_SQL_DATE"> between assmteffective and assmtexpires
		and      valid
		limit    1
	</cfquery>
	
	<cfif CheckForAssessment.recordcount is 0>
		<cfset stoppage = 1>
          
          <CFQUERY name="getAssessments" datasource="#application.dopsds#">
          SELECT   *
FROM     dops.assessmentrates
WHERE    <cfqueryparam value="#GetAppTypeLeagueFees.assmtcheckdate#" cfsqltype="CF_SQL_DATE"> between assmteffective - grace::integer and assmtexpires + grace::integer
order by assmteffective asc
          </CFQUERY>
          
	</cfif>

</cfif>


<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Sports League Registration</title>
	<link rel="stylesheet" href="/includes/thprdstyles_min.css">
     
 <!---   
<SCRIPT language="javascript">
function setshirt() {
	
}
</SCRIPT>    
---> 
     
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

			<tr>
				<td  class="pghdr"><br>My Sports Leagues</td>
			</tr>	

			<tr>
				<td><CFIF getleaguereg.recordcount EQ 0>Currently this household does not have any active THPRD youth sports leagues.<br><br><CFELSE>
				<ul>
				<CFLOOP query="getleaguereg">
				<CFSET thispatronID = getleaguereg.patronid>
				<CFQUERY name="getleaguePatron" dbtype="query">
					select firstname, lastname from GetPatrons
					where secondarypatronid = #getleaguereg.patronid#
				</CFQUERY>
				<li><CFOUTPUT>#getleaguePatron.firstname# #getleaguePatron.lastname# - #getleaguereg.description#</CFOUTPUT></li>
				</CFLOOP>
				</ul></CFIF></td>
			</tr>	

			
			<tr>
				<td ><span class="pghdr">League Information</span><br>
				
				<CFIF GetAppTypeLeagueFees.recordcount EQ 0>
					<font color="red"><b>Online league registration is now closed.<br>For assistance please call the Athletic Center at 503/629-6330.</b></font>
					</td>
					</tr>
				
				<CFINCLUDE template="leaguefooter.cfm">
				<cfabort>
				</CFIF>
				
								<ul>
                                        <!--->
					<li><a target="_blank" href="http://www.thprd.org/document/3232/5th8th-winter-basketball-parent-info">2015-16 5th - 8th Grade Basketball</a></li>				
				<li><a target="_blank" href="http://www.thprd.org/document/3251/2016-high-school-winter-basketball-parent-and-coach-registration-information">2015-16 High School Basketball</a></li>	--->
                    <CFOUTPUT query="docs">
                    	<CFSCRIPT>
                         urlname = rereplacenocase(docs.name,'[^A-Za-z0-9 ]','','all');
					urlname = replacenocase(urlname,'  ',' ','all');
                         urlname = lcase(replacenocase(urlname,' ','-','all'));
					</CFSCRIPT>
                         <CFIF trim(docs.name) NEQ "Online Medical Information & Consent Form" and trim(docs.name) NEQ "Volunteer Application">
                    <li><a target="_blank" href="http://www.thprd.org/document/#docs.id#/#urlname#">#docs.name#</a>
                    	</CFIF>
                    </CFOUTPUT>
                    
                    
                    
                    </ul>
                    
                    <!---
                    <span class="pghdr">Verify League Information</span><br>
                    Please take a moment to verify that your contact information is current. THPRD staff and coaches will use this information
                    --->
				</td>
				</tr>
				
				<!---
				<tr>
				<td>
				<span class="pghdr">2010 Boys & Girls 5th Grade/Middle School Spring Basketball</span><br>
				<br>
				
				<span class="sectionhdr">General Information</span><br>
				
				<CFIF GetAppTypeLeagueFees.recordcount EQ 0>
					<font color="red"><b>Online Basketball registration is now closed.<br>For assistance please call the Athletic Center at 503/629-6330.</b></font>
					</td>
					</tr>
				
				<CFINCLUDE template="leaguefooter.cfm">
				<cfabort>
				</CFIF>
				
<ul style="margin-top:0px;">
<li>Spring league online registration will be accepted from February 11, 2010 - March 21, 2010</li>
<li>Team rosters are due on March 22, 2010.</li>
<li>Preseason practices will start the week of April 5, 2010</li>
<li>League games will begin the week of April 12th through June 3rd.</li>
<li>2010 Spring Assessment required for out-of-district players.</li>
</ul>		
				</td>
			</tr>
			<tr>
				<td  class="sectionhdr">Documents & Forms</td>
			</tr>	
			<tr>
				<td>
				<ul>
					<li><a href="http://www.thprd.org/pdfs/document551.pdf" target="_blank">Parent Information Packet</a></li>
					<li><a href="http://www.thprd.org/pdfs/document70.pdf" target="_blank">Emergency Medical Consent Forms</a></li>
				</ul>
				</td>
			</tr>

			<cfif OfferShirts is 1>
				<tr>
					<td><span class="sectionhdr">Basketball League Shirt Sizes</span></td>
				</tr>
			</cfif>

			<tr>
				<td>
<cfif OfferShirts is 1>
	<ul>
	<li>5th Grade Program: Youth or Adult sizes available</li>
	<li>Middle School Program: Adult sizes only</li>
	</ul>
</cfif>

<span class="sectionhdr">Team Registration & Player Eligibility</span><br>				
Teams are responsible to secure their own coaches. Coaches entering a team into this league will need to submit a team roster to the Athletic Center by March 22, 2010.

<ol type="A">
	<li><p>Participants must currently reside within THPRD boundaries or reside within the Beaverton
School District #48 boundaries and attend a Beaverton school. Private school or home school
participants residing within the THPRD and BSD boundaries are eligible to participate in this
program.</p></li>

<li><p><b><font color="red">NEW</b> Teams must be comprised of players residing within the THPRD boundaries, be in the same grade, of the same gender and <em><strong>all</strong></em> from within the same BSD high school attendance area.</font><br>
<br>
The roster needs to carry a minimum of 10 and a maximum of 12 players. Coaches will
predetermine their level of competition (competitive or recreational) on their team roster.<br>
<br>
(Exception: Mixed teams formed by THPRD that are returning from the THPRD winter league will
be accepted.)</p></li>
</ol>

For any questions concerning a player's eligibility please contact Julie Pacarro Stout or Mike Luyten at
503-629-6330 prior to placement.<br>
<br>

<span class="sectionhdr">Individual Registration</span><br>
Players not currently on a Spring team can still register individually. These players will be placed on teams that are in need of players and will be contacted with their team assignment by April 4th. Once teams are established, coaches will contact their players. Under no circumstances will players be reassigned after being placed on a team. Late registrants will be placed on a team depending on space availability.<br>
<br>				
				
				</td>
			</tr>		


			<tr>
				<td ><span class="sectionhdr">School Pathing</span><br>
					Select from the school selection list by your elementary, middle school and high school attendance areas.
				</td>
			</tr>
--->
			<tr>
				<td>
				<!--- start application specific code --->
<cfoutput>


<cfquery datasource="#application.dopsds#" name="CheckForClassesInSession">
	SELECT   reg.classid
	FROM     dops.reg
	WHERE    reg.sessionid is not null
	AND      reg.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">
	limit    1
</cfquery>

<cfif CheckForClassesInSession.recordcount eq 1>
	There currenty one or more classes in your shopping cart.
	These must be finished or removed to continue.
	<CFINCLUDE template="leaguefooter.cfm">
	<cfabort>
</cfif>

<span class="pghdr">Register Now</span><br>
After reading the league information above, select league and school pathing below. School pathing refers to your elementary, middle school and high school attendance areas. Only one sport for each patron per invoice. To register for multiple sports simply repeat the registration process.<br>

<cfif IsDefined("stoppage")>
<br>
<font color="red"><strong>ALERT:</strong> This household has been detected to be OUT-OF-DISTRICT and does not have an appropriate assessment. <br><br>To register the league with lower IN-DISTRICT RATE, you must go to the <strong>Assessments</strong> section at left and obtain either quarterly assessment or an annual assessment that covers the league start and end dates.</font></strong>

<p><strong>Appropriate Assessments For League Registration</strong>
<ul>
<CFLOOP query="getAssessments">
<li>#name#</li>
</CFLOOP>
</ul>
</p>
</cfif>

<!--- <CFELSEIF datecompare(now(),"02/11/2010") GT 0 AND datecompare(now(),"03/21/2010") LTE 0> --->
<cfif GetAppTypeLeagueFees.recordcount gt 0>

<form name="f" method="POST" action="processleague1.cfm">
<input name="huserid" value="0" type="hidden">
<input name="OfferShirts" value="#OfferShirts#" type="hidden">

<cfset startcredit = 0.00>
<input name="primarypatronid" value="#primarypatronid#" type="hidden">

<br>
<table cellpadding="2" cellspacing="1" border="0">
<CFSET catbg = "##eeeeee">
<cfloop query="GetPatrons">

<CFIF datecompare(GetPatrons.dob[GetPatrons.currentrow],leagueages.themaxage) GT 0>
<tr>
	<td valign="middle" bgcolor="#catbg#"><strong>Participant</strong></td>
	<td rowspan="4">&nbsp;</td>
	<td valign="middle">#GetPatrons.lastname#, #GetPatrons.firstname#</td>
</tr>
<tr>
	<td valign="middle" bgcolor="#catbg#"><strong>League</strong></td>
	<td valign="middle">
		<cfset calcstr = "">

		<select name="SelectAppType" class="form_input">
			<option selected value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^0^0">#StringPad("Select League and Rate", 20)#
			<cfset calcstr = calcstr & "if (document.f.SelectAppType.selectedIndex==0) {document.f.baserate.value=0.00};">

			<cfloop query="GetAppTypeLeagueFees">
			<!--- lookup patron specific fee with new function --->
               <CFQUERY name="getfee" datasource="#application.dopsdsro#">
               select getyouthleagrate(#getPatrons.primarypatronid#, #getPatrons.secondarypatronid#, '#GetAppTypeLeagueFees.facid#',#GetAppTypeLeagueFees.typecode#, 'false') as val
               </CFQUERY>
               

               
               <CFSET thispatronfee = getfee.val>
               

				<cfif (GetPatrons.gender[GetPatrons.currentrow] is "M" and FindNoCase("Boy", description) gt 0) or (GetPatrons.gender[GetPatrons.currentrow] is "F" and FindNoCase("Girl", description) gt 0)>

					<CFIF datecompare(GetPatrons.dob[GetPatrons.currentrow],mindob) LT 0>
                         	<option value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^0^0">#description# (Patron exceeds age max.)
                              
                         <CFELSEIF datecompare(GetPatrons.dob[GetPatrons.currentrow],maxdob) GT 0>
                         	<option value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^0^0">#description# (Patron does not meet age min.)

					<CFELSE>

					<!--- check enrollment vs. maxqty --->
					<cfif enrolledcount lt maxqty>
						<option value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^#typecode#^#offershirt#">#description# (#DollarFormat(thispatronfee)#<cfif IsInDevMode> - Max: #maxqty#</cfif>) <CFIF offershirt EQ 0>* No Shirt</CFIF>
					<cfelse>
						<option value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^0^0">#description# (full - contact #facid#<cfif IsInDevMode> - Max: #maxqty#</cfif>)
					</cfif>
                         
                         </CFIF>

				</cfif>

			</cfloop>
		
		</select> <!---&nbsp;&nbsp;&nbsp;<a href="javascript:void(0);" onClick="window.open('http://www.thprd.org/sports/youth/basketballleagues.html','photos','width=400, height=300, status=yes, scrollbars=yes, toolbars=no, noresize');" title="Which One?">Help</a>--->
	</td>
</tr>

<cfif OfferShirts is 1>
	<tr>
		<td valign="middle" bgcolor="#catbg#"><strong>Shirt Size</strong></td>
		<td valign="middle">
		<select name="selectshirt" class="form_input">
				<option value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^N/A">#StringPad("Select Shirt", 4)#
				<cfloop query="GetLeaguePatronShirtSizes">
					<option value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^#sizecode#">#sizedescription#
				</cfloop>
                    <option  value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^NA">No Shirt
			</select><!--- &nbsp;&nbsp;&nbsp;<a href="javascript:void(0);" onClick="window.open('http://www.thprd.org/sports/youth/basketballshirts.html','photos','width=400, height=300, status=yes, scrollbars=yes, toolbars=no, noresize');" title="More Info">Available Sizes</a>--->
		</td>
	</tr>

<cfelse>
	<input name="selectshirt" type="Hidden" value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^NA">

</cfif>

<tr>
	<td valign="middle" bgcolor="#catbg#"><strong>School Pathing</strong></td>
	<td valign="middle">
		<select name="selectschool" class="form_input">
		<option value="0^0" >#StringPad("School Path Options", 27)#

		<cfloop query="GetSchools1">
			<option value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^#rn#"><cfif schoolname is not "ISB">#schoolname# Elementary -> </cfif>#middle# Middle -> #high#
		</cfloop>

		</select>
	</td>
</tr>

<tr><td colspan="3">&nbsp;</td></tr>
<CFELSE>


<input type="hidden" name="SelectAppType" value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^0^0" >
<input type="hidden" name="selectschool" value="0^0" >
<input type="hidden" name="selectshirt" value="#GetPatrons.secondarypatronid[GetPatrons.currentrow]#^N/A">



</CFIF>
</cfloop>

<tr><td></td><td colspan="2" align="center"><input type="submit" name="ProceedToNextStep" value="Continue To Next Step" class="form_input" style="background-color:##FFFF99;font-size:12px;"></td></tr>

</table>

</form>

<CFELSE>	
	Registration is currently offline.
</cfif>

</cfoutput>
<!--- end application specific code --->
<CFINCLUDE template="leaguefooter.cfm">


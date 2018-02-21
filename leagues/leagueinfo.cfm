<CFSILENT>
<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
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
	SELECT   typecode, description, fee, offershirt  
	FROM     th_leaguetype 
	WHERE    facid = <cfqueryparam value="#SelectFacility#" cfsqltype="CF_SQL_VARCHAR">
	and      available
	and      current_date between startdate and cutoffdate
	ORDER BY description
</cfquery>

<cfset OfferShirts = 0>

<cfloop query="GetAppTypeLeagueFees">

	<cfif offershirt is 1>
		<cfset OfferShirts = 1>
		<cfbreak>
	</cfif>

</cfloop>

<cfquery datasource="#application.dopsdsro#" name="GetPatrons">
	SELECT   patronrelations.secondarypatronid, 
	         secondary.lastname, 
	         secondary.firstname, 
	         secondary.middlename, 
	         secondary.gender
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
		and      <cfqueryparam value="2010-07-15" cfsqltype="CF_SQL_DATE"> between assmteffective and assmtexpires
		and      valid
		limit    1
	</cfquery>
	
	<cfif CheckForAssessment.recordcount is 0>
		<cfset stoppage = 1>
	</cfif>

</cfif>

</CFSILENT>
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
	<title>Sports League Registration</title>
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
			<tr>
				<td >
				<!---
				<span class="pghdr">Registration Information</span><br>
				<ul>
					<li><a href="leagueinfo.cfm?league=summerBB">2010 Summer Boys Basketball Leagues</a></li>
					<!---<li>2010 Summer Boys Skills Training</li>--->
					<li><a href="leagueinfo.cfm?league=summerBB">2010 Summer Girls Basketball Leagues</a></li>
					<!---<li>2010 Summer Girls Basketball Skills Training</li>!--->
					<li><a href="leagueinfo.cfm?league=summerVB">2010 Summer Girls Volleyball Leagues</a></li>
				</ul>
				--->
				<CFOUTPUT>
				<CFINCLUDE template="leagueinfo/#url.league#.cfm">
				</CFOUTPUT>
				
			







<!--- end application specific code --->
<CFINCLUDE template="leaguefooter.cfm">

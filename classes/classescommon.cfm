<cfquery name="csGetFacilities" datasource="dopsdsro" cachedwithin="#CreateTimeSpan(1,0,0,0)#">
	select   pk, facid, name,altname
	from     facilities
	where    ShowInReg = true
	and      facid != 'WWW'
     
	ORDER BY altname
</cfquery>

<!--- fetch only instructors scheduled for open terms --->
<cfquery datasource="#application.dopsdsro#" name="csGetInstructors" cachedwithin="#CreateTimeSpan(0,6,0,0)#">
	SELECT   instructorschedule.instructorid, instructors.firstname || ' ' || instructors.lastname as name
	FROM     instructorschedule 
	         INNER JOIN locationschedule locationschedule ON instructorschedule.termid=locationschedule.termid AND instructorschedule.facid=locationschedule.facid AND instructorschedule.activity=locationschedule.activity
	         INNER JOIN instructors instructors ON instructorschedule.instructorid=instructors.instructorid 
	WHERE    instructorschedule.startdt >= now() 
	AND      instructors.lastname != <cfqueryparam value="Staff" cfsqltype="CF_SQL_VARCHAR">
	AND      instructors.firstname != <cfqueryparam value="Staff" cfsqltype="CF_SQL_VARCHAR">
	GROUP BY instructorschedule.instructorid, instructors.firstname || ' ' || instructors.lastname
	ORDER BY instructors.firstname || ' ' || instructors.lastname
</cfquery>


<cfquery datasource="#application.dopsdsro#" name="csGetAllAvailTerms" >
select termid, termname, classshowdate as websearchavailable, allowweb as startdt, allowoddt
from webterms
order by termid asc
</cfquery>










<!---can we get this from slave? or put into session 
<CFIF NOT structKeyExists(session,"GetPatrons")>
<cfquery datasource="#application.classsearchproduction_dsn#" name="session.GetPatrons">
	select   secondarypatronid, patrons.lastname, patrons.firstname, patrons.dob, relationtype,
	         instrlevela, instrleveld, instrlevelt
	from     patronrelations
	         inner join patrons on secondarypatronid=patrons.patronid
	where    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
	order by patrons.firstname
</cfquery>
</CFIF>

<CFSET getPatrons = session.GetPatrons>
--->
<cfquery datasource="#application.classsearchproduction_dsn#" name="GetPatrons">
	select   secondarypatronid, patrons.lastname, patrons.firstname, patrons.dob, relationtype,
	         instrlevela, instrleveld, instrlevelt,ismil
	from     patronrelations
	         inner join patrons on secondarypatronid=patrons.patronid
	where    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
	order by patrons.firstname
</cfquery>

<!--- level inclusion --->
<cfparam name="SelectClassType" default="">
<cfparam name="SelectClassLevel" default="">

<cfquery name="csGetClassLevels" datasource="#application.classsearchproduction_dsn#" cachedwithin="#CreateTimeSpan(0,12,0,0)#">
	SELECT   leveltext 
	FROM     levels
	where    leveltext is not null
	and      leveltext != '' 
     and      leveltext not like '%1/2%'
	ORDER BY listorder
</cfquery>


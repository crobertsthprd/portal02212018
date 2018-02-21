<cfquery datasource="#application.dopsdsro#" name="GetPatrons">
	SELECT   patronrelations.primarypatronid,
     	    patronrelations.secondarypatronid,
	         secondary.lastname,
	         secondary.firstname,
	         secondary.middlename,
	         secondary.gender,
	         patronrelations.faeligible,
	         patronrelations.sessionavailablefa,
	         0 as activethisinvoice
	FROM     patronrelations
	         INNER JOIN patrons primarypatron ON patronrelations.primarypatronid=primarypatron.patronid
	         INNER JOIN patrons secondary ON patronrelations.secondarypatronid=secondary.patronid
	WHERE    patronrelations.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
     <!--- added 04/26/2016  CR must match query on index.cfm --->
     ORDER by patronrelations.secondarypatronid
</cfquery>

<cfset appstruct = structnew()>
<cfset schstruct = structnew()>
<cfset shistruct = structnew()>

<cfloop from="1" to="#listlen(form.selectshirt)#" index="j">
	<cfset variable.shirtstr = listgetat(form.selectshirt, j, ',')>
	<cfset variable.schoolstr = listgetat(form.selectschool, j, ',')>
	<cfset variable.appstr = listgetat(form.selectapptype, j, ',')>

	<cfset variable.a = structinsert( shistruct, listgetat(variable.shirtstr, 1, '^'), listgetat(variable.shirtstr, 2, '^'), true )>
	<cfset variable.b = structinsert( appstruct, listgetat(variable.appstr, 1, '^'), listgetat(variable.appstr, 2, '^'), true )>
	<cfset variable.c = structinsert( schstruct, listgetat(variable.schoolstr, 1, '^'), listgetat(variable.schoolstr, 2, '^'), true )>
</cfloop>

<cfset content = "contentds">
<cfparam name="primarypatronid" default="#cookie.uID#">
<cfparam name="huserid" default="0">
<cfparam name="SelectAppType" default="0">
<cfparam name="SelectFacility" default="AC">
<cfparam name="localfac" default="WWW">

<cfif form.othercreditused gt 0>
<cfquery datasource="#application.dopsdsro#" name="getCards">
		SELECT   isfa
		FROM     othercredithistorysums
		where    cardid = <cfqueryparam value="#form.OTHERCREDITCARDID#" cfsqltype="CF_SQL_INTEGER">
</cfquery>
</cfif>
<cfset hadactivity = 0>

<!--- MUST be the same as leaguefees.cfm --->
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
<cfquery datasource="#application.contentdsro#" name="GetAppTypeLeagueFees">
		SELECT   facid,
		         typecode,
		         description,
		         fee,
		         offershirt,
		         assmtcheckdate,
		         maxqty,
		         acctid, --(
		0 as enrolledcount

		--SELECT   coalesce( count(*), 0 )
		--FROM     content.th_league_enrollments_view
		--WHERE    th_league_enrollments_view.leaguetype = th_leaguetype.typecode
		--AND      th_league_enrollments_view.valid
		--AND      not th_league_enrollments_view.isvoided) as enrolledcount

		FROM     th_leaguetype
		WHERE    facid = <cfqueryparam value="#SelectFacility#" cfsqltype="CF_SQL_VARCHAR">
		AND      available
		ORDER BY description
</cfquery>

<cfquery datasource="#application.contentdsro#" name="GetLeaguePatronShirtSizes">
		SELECT   sizecode,
		sizedescription
		FROM     th_shirtsize
		order by displayorder
</cfquery>

<cfif form.othercreditused gt 0>
		<cfset thisoc = form.giftcarddebitamount>
</cfif>
<!--- load final array --->
<cfset FinalArray = ArrayNew(2)>
<!--- <cfdump var="#form#" label="form after finalappyinit"> --->

<cfloop query="GetPatrons" >
	<cfset FinalArray[currentrow][1] = 0><!--- patronid --->
    <cfset FinalArray[currentrow][1] = getPatrons.secondarypatronid>
	<cfset FinalArray[currentrow][2] = shistruct[getPatrons.secondarypatronid]><!--- shirt size --->
	<cfif structkeyexists(schstruct, getPatrons.secondarypatronid)>
			<cfset FinalArray[currentrow][3] = schstruct[getPatrons.secondarypatronid]><!--- school pathing code --->
	<cfelse>
			<cfset FinalArray[currentrow][3] = 0><!--- school pathing code --->
	</cfif>
	<cfset FinalArray[currentrow][4] = appstruct[getPatrons.secondarypatronid]><!--- activity code --->
    <cfset FinalArray[currentrow][5] = "">
    <!--- school pathing names --->
    <cfset FinalArray[currentrow][6] = 0>
    <!--- fee --->
    <cfset FinalArray[currentrow][7] = "">
    <!--- activity description --->
    <cfset FinalArray[currentrow][8] = 0>
    <!--- elementary school id --->
    <cfset FinalArray[currentrow][9] = 0>
    <!--- middle school id --->
    <cfset FinalArray[currentrow][10] = 0>
    <!--- high/option school id --->
    <cfset FinalArray[currentrow][11] = 0>
    <!--- type code --->
	<cfset FinalArray[currentrow][12] = 0>
	<cfset FinalArray[currentrow][13] = 0>
		

    <cfloop query="GetSchools1">
               		<cfif FinalArray[GetPatrons.currentrow][3] is rn>
                    	<cfset FinalArray[GetPatrons.currentrow][5] = schoolname & " Elementary -> " & middle & " Middle -> " & high & " High">
                    	<cfset FinalArray[GetPatrons.currentrow][8] = schoolid>
                    	<cfset FinalArray[GetPatrons.currentrow][9] = feederms>
                    	<cfset FinalArray[GetPatrons.currentrow][10] = feederhs>
                    	<cfbreak>
               		</cfif>
    </cfloop>

    <cfloop query="GetAppTypeLeagueFees">
			<!--- lookup patron specific fee with new function --->
            <CFQUERY name="getfee" datasource="#application.dopsdsro#">
               		select getyouthleagrate(#getPatrons.primarypatronid#, #getPatrons.secondarypatronid#, '#GetAppTypeLeagueFees.facid#',#GetAppTypeLeagueFees.typecode#, 'false') as val
            </CFQUERY>
            <CFSET thispatronfee = getfee.val>



			<cfif typecode is appstruct[getPatrons.secondarypatronid]>
                <!--- CHANGE 10.22.2014 <cfset FinalArray[GetPatrons.currentrow][6] = fee> --->
                <cfset FinalArray[GetPatrons.currentrow][6] = thispatronfee>
                <!--- activity fee --->
                <cfset FinalArray[GetPatrons.currentrow][7] = description>
                <!--- activity description --->
                <cfset FinalArray[GetPatrons.currentrow][11] = typecode>
                <cfset FinalArray[GetPatrons.currentrow][13] = acctid>
                <!--- acctid --->
			<cfif form.othercreditused gt 0>
				<cfif getcards.isfa>
					<cfset FinalArray[GetPatrons.currentrow][12] = min(thispatronfee,GetPatrons.sessionavailablefa[GetPatrons.currentrow])>
				<cfelse>
					<!--- use max possible gift card --->
					<cfset FinalArray[GetPatrons.currentrow][12] = min(thisoc, thispatronfee)>
					<cfset thisoc = thisoc - min(thisoc, thispatronfee)>
				</cfif>
				
				<!--- oc available --->
			<cfelse>
				<cfset FinalArray[GetPatrons.currentrow][12] = 0>
			</cfif>
                    	<cfbreak>
            </cfif>
	</cfloop>
</cfloop>
	<cfif 0>
		<cfdump var="#finalarray#" label="firstinit">
	</cfif>


<cfif NOT structkeyexists(cookie,"uID")>
	<cflocation url="../index.cfm?msg=3&page=queryclasses">
	<cfabort>
</cfif>

<!--- check open call --->
<CFINCLUDE template="/portalINC/checkopencall.cfm">


<cfoutput>
	<cfif IsDefined("gomain")>
		<cfinclude template="index.cfm">
		<cfabort>
	</cfif>
</cfoutput>

<CFPARAM name="form.agesearch" default="all">
<CFPARAM name="form.SelectInstructor" default="">
<CFPARAM name="form.selectclasslevel" default="">
<CFPARAM name="form.vieworder" default="classid">
<CFPARAM name="form.SearchMode" default="All">
<CFPARAM name="form.WeekdayInclusion" default="Any">
<CFPARAM name="form.startm1" default="">
<CFPARAM name="form.startd1" default="">
<CFPARAM name="form.starty1" default="">
<CFPARAM name="form.endm1" default="">
<CFPARAM name="form.endd1" default="">
<CFPARAM name="form.endy1" default="">


<cfset CallingProgram = "queryclasses.cfm">
<cfset tc = gettickcount()>

<cfset TableWidth = 600>
<cfset TableBorderWidth = 0>
<cfset bgcolor = "ededed">
<cfset primarypatronid = cookie.uID>
<CFIF structkeyexists(form,"dc") and form.dc NEQ "">
	<cfinclude template="dropclass.cfm">
</CFIF>

<!---
<cfif IsDefined("dc") and dc is not "">
	<cfinclude template="dropclass.cfm">
</cfif>
--->

<cfparam name="SelectSearchTerm" default="0000">

<!--- <cfif IsDefined("getclasses")>

	<cfif not IsDefined("SelectSearchTerm")>
		<BR><BR>
		<strong>No term was selected. Go <A href="javascript:;" onClick="history.back()">back</A> and try again.</strong>
		<cfabort>
	</cfif>

	<cfif not IsDefined("IncludeDOB")>
		<BR><BR>
		<strong>No patrons were selected. Go <A href="javascript:;" onClick="history.back()">back</A> and try again.</strong>
		<cfabort>
	</cfif>

</cfif> --->

<!---
<cfif cookie.loggedin is not 'yes'>
	<cflocation url="../index.cfm?msg=3">
	<cfabort>
</cfif>
--->

<cfif not isdefined('form.getclasses') AND not isdefined('url.classlist')>
	<cflocation url="index.cfm">
	<cfabort>
</cfif>

<cfinclude template="classescommon.cfm">

<CFIF structkeyexists(url,"classlist")>
<CFPARAM name="form.keywords" default="">
<CFPARAM name="form.getclasses" default="">

<CFPARAM name="form.SELECTINSTRUCTOR" default="">
<CFSET form.getclasses = "Search By Number">
<CFSET SelectSearchTerm = QuotedValueList(csGetAllAvailTerms.termid)>


</CFIF>

<html>
<head>
<title>Tualatin Hills Park and Recreation District </title>
<META HTTP-EQUIV="CACHE-CONTROL" CONTENT="NO-CACHE">
<META HTTP-EQUIV="PRAGMA" CONTENT="NO-CACHE">
<meta http-equiv="Expires" content="Sat, 01 Dec 2001 00:00:00 GMT">

<meta http-equiv="Content-Type" content="text/html;">
<SCRIPT language="javascript">
<!--
function chooseclass(classID,thisClassAction,uniqueID) {
	showclasses.thecID.value = classID;
	showclasses.uniqueID.value = uniqueID;
	// make sure we do not augment of decrement the classes we are currently viewing
	//alert(showclasses.thecID.value);
	showclasses.startclass.value = showclasses.currentstartclass.value;
	showclasses.endclass.value = showclasses.currentendclass.value;
	showclasses.getclasses.value = 'Retrieve Last Search';
	showclasses.classaction.value = thisClassAction;
	showclasses.submit();
}

//-->
</SCRIPT>
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
<cfoutput>


<form name="f" action="#cgi.script_name#" method="post">
<table border="#TableBorderWidth#" cellpadding="0" cellspacing="0" width="750">
<tr>
<td valign=top>
	<table border=#TableBorderWidth# cellpadding=2 cellspacing=0 width=749>
	<tr>
		<td colspan=2 class="pghdr">
		<!--- start header --->
		<CFINCLUDE template="/portalINC/dsp_header.cfm">
		<!--- end header --->
		</td>
	</tr>
	<tr>


	<!--- <cfquery name="GetReturnQtyReg" datasource="#application.dopsdsro#">
		select   varvalue::integer as s
		from     dops.systemvars
		where    varname = <cfqueryparam value="WebClassSearchReturnQtyRegMode" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>

	<cfset returnqty = GetReturnQtyReg.s>
	--->

	<!--- do not do a db call here  <cfset returnqty = getreturnqtyregmode()>--->
	<CFSET returnqty = request.searchreturnqty>

	<cfset primarypatronid = cookie.uID>
	<input type="Hidden" valid="#primarypatronid#" name="primarypatronid">

	<cfset clean_keywords = lTrim(rTrim(uCase(REReplaceNoCase(keywords, "[^A-Z 0-9 -]", " " ,"ALL"))))>
	<cfset clean_classlist = lTrim(rTrim(uCase(REReplaceNoCase(classlist, "[^A-Z 0-9]", " " ,"ALL"))))>

	<cfset ExcludeList = "0">

	<cfif IsDefined("IncludeDOB")>

		<cfloop index="x" list="#IncludeDOB#">
			<cfset ExcludeList = ExcludeList & ", " & mid(x, 10, 999)>
		</cfloop>

	</cfif>





	<cfif IsDefined("enrollclasses") and IsDefined("enrollments")>

		<CFPARAM name="form.loadtest" default="false">

		<!--- check element values --->
		<cfset verified = 1>


			<cfset enrollpaid = ListToArray(enrollments)>
			<cfset enrollmentpairs = ArrayNew(2)>
			<cfset enrollmentlist = "">
			<cfloop from="1" to="#ArrayLen(enrollpaid)#" step="1" index="x">
				<cfset t2 = ListToArray(enrollpaid[x], "^")>
				<cfif t2[1] + t2[2] is not t2[3]>
					<cfset verified = 0>
					<cfbreak>
				</cfif>
				<!--- array def: [class unique id][patronid] --->
				<cfset enrollmentpairs[x][1] = t2[1]>
				<cfset enrollmentpairs[x][2] = t2[2]>
				<cfset enrollmentlist = listappend(enrollmentlist,t2[1])>
			</cfloop>
			<cfif verified is 1>
				<cfinclude template="processreg.cfm">
			</cfif>
		<!---
		<CFIF form.loadtest EQ false>
		<CFELSE>
			<CFIF NOT structkeyexists(application,"getoneclass") >
				<CFQUERY name="application.getoneclass" datasource="#application.dopsds#">
					SELECT  uniqueid,
							termid,
							 facid,
							 classid
					FROM     dops.classes
					WHERE    termid = '0909'
					AND      enddt > now()
					<!---
					and      (
							 select   cnt
							 from     idreg
							 where    termid = classes.termid
							 and      facid = classes.facid
							 and      classid = classes.classid) <= classes.maxqty --->
					offset   random() * 2000
					limit    200
				</CFQUERY>
				<CFSET application.classcounter = 1>
			</CFIF>
			<cfset enrollmentpairs[1][1] = application.getoneclass.uniqueid[application.classcounter]>
			<cfset enrollmentpairs[1][2] = primarypatronid>
			<cfset enrollmentlist = application.getoneclass.uniqueid[application.classcounter]>
			<CFSET application.classcounter = application.classcounter + 1>
			<CFIF application.classcounter GT 200>
				<CFSET application.classcounter = 1>
			</CFIF>
			<cfinclude template="processreg.cfm">
		</CFIF>
		--->
	</cfif>

		<td valign=top>
			<table border=#TableBorderWidth# cellpadding=2 cellspacing=0>
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



	<cfif getclasses is "Search For Classes">

		<cfquery name="GetPatrons" dbtype="query">
			select  *
			from    GetPatrons
			where   secondarypatronid in ( #ExcludeList# )
		</cfquery>

	</cfif>

	<cfif getclasses is "Search For Classes" and GetPatrons.recordcount is 0>
		<cfset request.return0rows = 1>
	</cfif>

	<cfquery datasource="#application.dopsds#" name="GetRegistrations">
		SELECT   reg.patronid, classes.uniqueid, reg.regstatus
		FROM     reg
		         INNER JOIN classes classes ON reg.termid=classes.termid AND reg.facid=classes.facid AND reg.classid=classes.classid
		WHERE    reg.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		AND      position( reg.regstatus in ( <cfqueryparam value="EARWH" cfsqltype="cf_sql_varchar" list="no"> ) ) > <cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">
		AND      classes.status = <cfqueryparam value="A" cfsqltype="CF_SQL_VARCHAR">
		AND      reg.valid = <cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
		and      reg.patronid in ( <cfif GetPatrons.recordcount is 0>0<cfelse><cfqueryparam value="#ValueList(GetPatrons.secondarypatronid)#" cfsqltype="CF_SQL_INTEGER" list="Yes" separator=","></cfif> )
	</cfquery>

	<cfif IsDefined("nextclasses")>
		<cfset offset = offset + returnqty>
	<cfelseif IsDefined("prevclasses")>
		<cfset offset = max(offset - returnqty, 0)>
	<cfelseif isDefined("enrollclasses") or (isDefined("dc") and dc is not "")>
		<!--- do nothing to return to same page upon enrolling --->
	<cfelse>
		<cfset offset = 0>
	</cfif>

	<cfparam name="searchpageinstance" default="0">
	<cfparam name="dobsearch" default="">

<td valign=top>

	<table border="#TableBorderWidth#" cellpadding="0" cellspacing="0" width="749">
		<tr>
		<td valign=top height=300></td>
		<td valign=top class="bodytext">

		<!---// must confirm user is in WWW session before continuing //--->
		<CFSET checksession = sessioncheck(primarypatronid)>

		<CFIF checksession.sessionID NEQ 0>
			<CFSET CurrentSessionID = checksession.sessionID>
		<CFELSE>
			<CFSET CurrentSessionID = 0>
			<!--- generic alert page --->
			<CFLOCATION url="/portal/index.cfm?action=logout&sessioncatch=#urlencodedformat(checksession.message)#">
			<CFABORT>
		</CFIF>

		<cfset SuppressCart = 0>

		<cfif (not IsDefined("enrollclasses") and not IsDefined("dropclass")) and 0>
			<cfset SuppressCart = 1>

			<cfquery datasource="#application.dopsdsro#" name="GetNewRegistrations">
				select   reg.patronid, reg.termid, reg,facid, reg.classid, reg.regstatus
				from     reg
				where    SessionID = <cfqueryparam value="#CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>

		<cfelse>
			<cfinclude template="shownewregcheckout.cfm">
			#shoppingcart#
			<!---
			<CFIF cookie.insession EQ true>
				<cfinclude template="shownewreg.cfm">
			<CFELSE>
				<CFSET GetNewRegistrations = QueryNew("patronID", "Integer")>
				<cfset newRow = QueryAddRow(GetNewRegistrations, 1)>
				<cfset temp = QuerySetCell(GetNewRegistrations, "PatronID", 0, 1)>
			</CFIF>
			--->
		</cfif>

		<cfquery dbtype="query" name="GetNewRegistrations">
			select   *
			from     GetNewRegistrations
			where    patronid in (<cfif GetPatrons.recordcount is 0>0<cfelse>#ValueList(GetPatrons.secondarypatronid)#</cfif>)
		</cfquery>

		<cfset selectsearchtermvar = selectsearchterm>
		<!--- <cfset SelectSearchTermClassModeVar = SelectSearchTermClassMode> --->
		<cfset SelectSearchTermClassModeVar = QuotedValueList(csGetAllAvailTerms.termid)>

		<cfif IsDefined("keywords")>

		<cfset tc = gettickcount()>


		<!--- <cfinclude template="queryclassescore.cfm"> --->



<cfparam name="offset" default="0">





<!--- get true recordcount from filter option
to use, set "from"  below to 1 if obtaining total recordcount for filter is desired
if set to 1, the first pass will return recordcount. the second pass will obtain normal data
the variable request.classquerylooprecordcount will be the total recordcount if used
recommend coding so recordcount is run only the first time to keep performance high
--->

<cfloop from="2" to="2" index="request.classqueryloopcountnumber">

	<cfquery datasource="#application.classsearchslave_dsn#" name="QueryClasses" timeout="30" result="s">
		-- portal search /secure/portal/classes/queryclasses.cfm: QueryClasses: 2013.05.21
		SELECT

			<cfif request.classqueryloopcountnumber eq 1>
		         count(*) as c

			<cfelse>
		         classesview.ClassID,
		         classesview.Description,
		         classesview.TermID,
		         classesview.FacID,
		         length( classesview.ClassComments ) as ClassCommentsLength,
		         classesview.UniqueID,
		         classesview.Status,
		         coalesce( classesview.MaxAgeMonths,0 ) as MaxAgeMonths,
		         coalesce( classesview.MinAgeMonths,0 ) as MinAgeMonths,
		         classesview.maxdob,
		         classesview.mindob,
		         classesview.InDistRegFee,
		         classesview.InDistSenFee,
		         classesview.OutDistSenFee,
		         classesview.OutDistRegFee,
		         classesview.MiscFee,
		         classesview.MaxQty,
		         classesview.idDeposit,
		         classesview.odDeposit,
		         classesview.finalpaymentdue,
		         classesview.StartDT,
		         classesview.EndDT,
		         length( classesview.classtext ) as ClassTextLength,
		         dops.classesdow( SunCount, MonCount, TueCount, WedCount, ThuCount, FriCount, SatCount ) as wdlist,
		         classesview.TermName,
		         classesview.allowweb,
		         classesview.allowoddt,
		         ( now() >= classesview.allowweb ) as indistrictopen,
		         ( now() >= classesview.allowoddt ) as outdistrictopen,
		         classesview.name,
		         classesview.scmonths,
		         classesview.statusdesc,
		         classesview.regcount as allocated,
		         classesview.wlcount as waitlist,
		         classesview.ewpcount as ewpclassallocated,
		         classesview.levels,
		         now() as dbtime,
		         classesview.leveltypecode

					<cfif cookie.ds is 'Out Of District'>
						, dops.hasvalidassessmentforclass(
							<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
							classesview.termid,
							classesview.facid,
							classesview.classid ) as hasvalidassmt
					</cfif>
				<!---, dops.usescrate() as newval--->
				, false as newval
			</cfif>
		FROM     dops.Classesview
		where    classesview.uniqueid in (



		-- master where clause
		select   cv.uniqueid
          <!--- command prompt suggested changing to classes instead of classes view 04.05.2017
		Need to add SQL for waitlist count and registered count--->
		from     dops.classesview cv
		         INNER JOIN dops.terms on cv.facid=terms.facid and cv.termid=terms.termid
		WHERE    not cv.suppressonweb
		and      cv.status in (
			<cfqueryparam value="A" cfsqltype="cf_sql_char" maxlength="1" list="no">,
			<cfqueryparam value="X" cfsqltype="cf_sql_char" maxlength="1" list="no">
			)
		and      current_date >= Terms.StartDT - interval '40 days'
		and      cv.classid not like <cfqueryparam value="%~%" cfsqltype="cf_sql_varchar" list="no">

		<cfif form.getclasses is "Search By Number">
			-- by class id
			and      cv.termid in (

				select   webterms.termid
				from     dops.webterms )

			<cfset request.t = lTrim( rTrim( REReplaceNoCase( uCase( replace( classlist, chr( 13 ), " ", "all" ) ), "[^A-Z ,0-9]", "" ,"ALL" ) ) )>
			and      ( false

				<cfloop list="#request.t#" delimiters=" ," index="x">
					or       cv.classid like <cfqueryparam value="#x#%" cfsqltype="cf_sql_varchar" list="no">
				</cfloop>

			)

		<cfelse>
			-- normal filter

			and cv.termid = <cfqueryparam value="#form.SelectSearchTerm#" cfsqltype="CF_SQL_VARCHAR">

			<cfif IsDefined("form.nowaitlists")>
				-- nowaitlists
				and cv.wlcount = <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
			</cfif>

			<cfif IsDefined("form.notfilled")>
				-- notfilled
				and cv.regcount < MaxQty
			</cfif>

			<cfif not IsDefined("form.includestarted")>
				-- includestarted
				and cv.startdt > now()
			</cfif>

			<cfif not IsDefined("form.includecompleted")>
				-- includecompleted
				and cv.enddt > now()
				and cv.status = <cfqueryparam value="A" cfsqltype="CF_SQL_VARCHAR">
			</cfif>

			<cfif trim( form.keywords ) is not "">

				<cfif IsDefined( "form.SearchMode" ) and uCase( form.SearchMode ) eq "PHRASE">
					-- phrase: use description and classtext fields instead of classsearch as classsearch is a massaged value
					and regexp_replace( upper( cv.classid || cv.description || coalesce( cv.classtext, '' ) || cv.brochuresectiontitle1 || cv.brochuresectiontitle2 ), '[^A-Z0-9]', '', 'g' ) like <cfqueryparam value="%#REReplaceNoCase( uCase( form.keywords ), "[^A-Z0-9]", "", "all" )#%" cfsqltype="cf_sql_varchar" list="no">

				<cfelse>
					-- keyword search

					<cfif form.SearchMode is "any">
						<cfset request.qsearchmode = "or">
					<cfelse>
						<cfset request.qsearchmode = "and">
					</cfif>

					<cfset tArray = ListToArray( lTrim( rTrim( REReplace( uCase( form.keywords ), "[^A-Z ,0-9-]", " " ,"ALL" ) ) ), ", ")>
					<cfset includeArray = ArrayNew( 1 )>
					<cfset excludeArray = ArrayNew( 1 )>

					<!--- determine inclusions/exclusions --->
					<cfloop from="1" to="#ArrayLen( tArray )#" step="1" index="x">

						<!--- add inclusion --->
						<cfif len( tArray[ x ] ) gt 2 and left( tArray[ x ], 1 ) neq "-">
							<cfset ArrayAppend( includeArray, tArray[ x ] )>
						</cfif>

						<!--- add exclusion --->
						<cfif len( tArray[ x ] ) gt 3 and left( tArray[ x ], 1 ) eq "-">
							<cfset ArrayAppend( excludeArray, tArray[ x ] )>
						</cfif>

					</cfloop>

					<!--- inclusions --->
					<cfif ArrayLen( includeArray ) gt 0>
						-- inclusions
						and (

						<cfloop from="1" to="#ArrayLen( includeArray )#" step="1" index="x">
							<cfif x gt 1>#request.qsearchmode#</cfif>
							regexp_replace( cv.classsearch, '[^A-Z 0-9]', '', 'g' ) like <cfqueryparam value="%#includeArray[ x ]#%" cfsqltype="cf_sql_varchar" list="no">
						</cfloop>

						)
					</cfif>

					<!--- exclusions --->
					<cfif ArrayLen( excludeArray ) gt 0>
						-- exclusions: keywords preceded with a single -
						and (

						<cfloop from="1" to="#ArrayLen( excludeArray )#" step="1" index="x">
							<cfif x gt 1>and</cfif>
							regexp_replace( cv.classsearch, '[^A-Z 0-9]', '', 'g' ) not like <cfqueryparam value="%#mid( excludeArray[ x ], 2, 999 )#%" cfsqltype="cf_sql_varchar" list="no">
						</cfloop>

						)
					</cfif>

				</cfif>

			</cfif>

			<cfif IsDefined( "form.SelectStartHour" )>
				-- SelectStartHour
				and date_part( 'hour', cv.startdt ) = <cfqueryparam value="#form.SelectStartHour#" cfsqltype="CF_SQL_INTEGER">
			</cfif>

			<cfif IsDefined( "form.tod" )>
				-- tod

				<cfif listlen( form.tod, "," ) lt 3>
					and (

					<CFLOOP list="#form.tod#" index="stime">
						( date_part( 'hour', cv.startdt ) between <cfqueryparam value="#listfirst(stime,"|")#" cfsqltype="cf_sql_integer" list="no"> and <cfqueryparam value="#listlast(stime,"|")#" cfsqltype="cf_sql_integer" list="no"> )
						<CFIF stime NEQ listlast( form.tod, "," )>or</CFIF>
					</CFLOOP>

					)
				</cfif>

			</cfif>

			<!--- facility selection --->
			<cfif IsDefined("form.SelectFacility")>
				-- selected facs
				and cv.FacID in ( ''

				<cfloop list="#form.SelectFacility#" index="facindex">
					, <cfqueryparam value="#REReplace( facindex, "[^A-Z0-9]", "", "all" )#" cfsqltype="cf_sql_varchar" list="no">
				</cfloop>

				)
			</cfif>

			<!--- instructor selection --->
			<cfif form.SelectInstructor is not "">
				-- SelectInstructor
				and      position( <cfqueryparam value="-#form.SelectInstructor#-" cfsqltype="CF_SQL_VARCHAR"> in cv.instructorlist ) > <cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">
			</cfif>

			<cfif GetPatrons.recordcount gt 0 and (IsDefined("form.IncludeDOB") and not IsDefined("form.ignoreage") )>
				-- dob
				and (

				<cfloop query="GetPatrons">
					<cfqueryparam value="#GetPatrons.dob#" cfsqltype="cf_sql_date" list="no"> between cv.mindob and cv.maxdob
					<cfif recordcount neq currentrow>or</cfif>
				</cfloop>

				)
			</cfif>

			<!--- start and end date --->
			<CFSET request.startdate = "#evaluate('form.startm1')#/#evaluate('form.startd1')#/#evaluate('form.starty1')#">
			<CFSET request.enddate = "#evaluate('form.endm1')#/#evaluate('form.endd1')#/#evaluate('form.endy1')#">

			<CFIF Isdate( request.startdate )>
				-- start date
				AND cv.startdt::date >= <cfqueryparam value="#request.startdate#" cfsqltype="cf_sql_date" list="no">
			</cfif>

			<CFIF Isdate( request.enddate )>
				-- end date
				AND cv.enddt::date <= <cfqueryparam value="#request.enddate#" cfsqltype="cf_sql_date" list="no">
			</CFIF>

			<!--- day of week selection --->
			<cfif IsDefined("form.CBSun") or IsDefined("form.CBMon") or IsDefined("form.CBTue") or IsDefined("form.CBWed") or IsDefined("form.CBThu") or IsDefined("form.CBFri") or IsDefined("form.CBSat")>
				-- dow
				and (

				<cfif IsDefined("form.WeekdayInclusion") and form.WeekdayInclusion is "All">
					<cfset request.dj = "and">
				<cfelse>
					<cfset request.dj = "or">
				</cfif>

				<cfset request.UseOR = 0>

				<cfif IsDefined("form.CBSun")>
					<cfif request.UseOR is 1>#request.dj#</cfif> (cv.SunCount > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
					<cfset request.UseOR = 1>
				</cfif>

				<cfif IsDefined("form.CBMon")>
					<cfif request.UseOR is 1>#request.dj#</cfif> (cv.MonCount > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
					<cfset request.UseOR = 1>
				</cfif>

				<cfif IsDefined("form.CBTue")>
					<cfif request.UseOR is 1>#request.dj#</cfif> (cv.TueCount > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
					<cfset request.UseOR = 1>
				</cfif>

				<cfif IsDefined("form.CBWed")>
					<cfif request.UseOR is 1>#request.dj#</cfif> (cv.WedCount > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
					<cfset request.UseOR = 1>
				</cfif>

				<cfif IsDefined("form.CBThu")>
					<cfif request.UseOR is 1>#request.dj#</cfif> (cv.ThuCount > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
					<cfset request.UseOR = 1>
				</cfif>

				<cfif IsDefined("form.CBFri")>
					<cfif request.UseOR is 1>#request.dj#</cfif> (cv.FriCount > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
					<cfset request.UseOR = 1>
				</cfif>

				<cfif IsDefined("form.CBSat")>
					<cfif request.UseOR is 1>#request.dj#</cfif> (cv.SatCount > <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">)
				</cfif>

				)
			</cfif>

			<CFIF form.selectclasslevel NEQ "">
				-- levels
				and cv.levels like <cfqueryparam value="%-#form.selectclasslevel#-%" cfsqltype="cf_sql_varchar" list="no">
			</CFIF>

			and cv.classid NOT LIKE '%~%'
		</cfif>

		<cfif request.classqueryloopcountnumber eq 2>
			-- limits
			offset  #Max( 0, offset )#
			limit   #returnqty#
		</cfif>

		)

		<cfif request.classqueryloopcountnumber eq 2>

			<cfif getclasses is "Search By Number">
				order by classid
			<cfelse>

				<cfif form.ViewOrder is not "">
					ORDER BY upper( #form.ViewOrder# )
				<cfelse>
					order by classid
				</cfif>

			</cfif>

		</cfif>

	</cfquery>


	<cfif request.classqueryloopcountnumber eq 1>
		<cfset request.classquerylooprecordcount = QueryClasses.c>
	</cfif>

</cfloop>





<!--- show diags --->
<cfif IsDefined("cookie.showdebug") and cookie.showdebug eq 1>
	------------------
	<br><strong>ExecutionTime:</strong> #s.ExecutionTime#ms
	<br><strong>Recordcount:</strong> #s.recordcount#

	<cfif 1>
		<br><strong>SQL:</strong> #s.sql#
		<br><strong>Params:</strong> <cfdump var="#s.sqlparameters#">
	</cfif>

	<cfif 0>
		<br><strong>FORM:</strong> <cfdump var="#form#">
	</cfif>

	<br>------------------<br>
</cfif>
<!--- end show diags --->





<cfif not isdefined('QueryClasses.recordcount')><!--- session.class_struct --->
	<cflocation url="index.cfm">
	<cfabort>
</cfif>

<cfparam name="keywordlist" default="">
<CFSET recorddays = "">
<CFSET recordsorts= "">

<cfif IsDefined("IncludeDOB")>
	<input type="hidden" name="IncludeDOB" value="#IncludeDOB#">
</cfif>

<cfif IsDefined("nowaitlists")>
	<input type="hidden" name="nowaitlists" value="1">
	<cfset recordsorts = listappend(recordsorts,"No Wait Lists",',')>
</cfif>



<input type="hidden" name="searchpageinstance" value="#searchpageinstance#">
<input type="hidden" name="getclasses" value="#getclasses#">
<INPUT TYPE="hidden" NAME="keywords" value="#keywords#">
<INPUT TYPE="hidden" NAME="selectsearchterm" value="#selectsearchtermvar#">
<INPUT TYPE="hidden" NAME="selectsearchtermclassmode" value="#selectsearchtermclassmodevar#">
<input type="hidden" name="keywordlist" value="#keywordlist#">
<input type="hidden" value="#SelectInstructor#" name="SelectInstructor">
<input type="hidden" name="agesearch" value="#agesearch#">
<input type="hidden" name="dobsearch" value="#dobsearch#">
<input type="hidden" name="SearchMode" value="#SearchMode#">
<input type="hidden" name="classlist" value="#classlist#">
<input type="hidden" name="startm1" value="#startm1#">
<input type="hidden" name="startd1" value="#startd1#">
<input type="hidden" name="starty1" value="#starty1#">
<input type="hidden" name="endm1" value="#endm1#">
<input type="hidden" name="endd1" value="#endd1#">
<input type="hidden" name="endy1" value="#endy1#">
<input type="hidden" name="SelectClassLevel" value="#SelectClassLevel#">

<cfif IsDefined("WeekdayInclusion")>
	<input type="hidden" value="#WeekdayInclusion#" name="WeekdayInclusion">
	<CFSET weekdayqualifier = WeekdayInclusion>
<CFELSE>
	<CFSET weekdayqualifier = "">
</cfif>

<cfif isDefined("vieworder")>
	<input type="hidden" name="vieworder" value="#vieworder#">
</cfif>

<cfif isDefined("notstarted")>
	<input type="hidden" name="notstarted" value="1">
	<cfset recordsorts = listappend(recordsorts,"Not Started",',')>
</cfif>

<cfif isDefined("includecompleted")>
	<input type="hidden" name="includecompleted" value="1">
	<cfset recordsorts = listappend(recordsorts,"Include Completed",',')>
</cfif>

<cfif isDefined("notfilled")>
	<input type="hidden" name="notfilled" value="1">
	<cfset recordsorts = listappend(recordsorts,"Not Filled",',')>
</cfif>

<cfif isDefined("tod")>
	<input type="hidden" name="tod" value="#tod#">
	<cfset thetod = tod>
<CFELSE>
	<cfset thetod = "">
</cfif>

<cfif IsDefined("CBSun")>
	<input type="hidden" value="1" name="CBSun">
	<cfset recorddays = listappend(recorddays,"Sun",',')>
</cfif>

<cfif IsDefined("CBMon")>
	<input type="hidden" value="1" name="CBMon">
	<cfset recorddays = listappend(recorddays,"Mon",',')>
</cfif>

<cfif IsDefined("CBTue")>
	<input type="hidden" value="1" name="CBTue">
	<cfset recorddays = listappend(recorddays,"Tues",',')>
</cfif>

<cfif IsDefined("CBWed")>
	<input type="hidden" value="1" name="CBWed">
	<cfset recorddays = listappend(recorddays,"Wed",',')>
</cfif>

<cfif IsDefined("CBThu")>
	<input type="hidden" value="1" name="CBThu">
	<cfset recorddays = listappend(recorddays,"Thurs",',')>
</cfif>

<cfif IsDefined("CBFri")>
	<input type="hidden" value="1" name="CBFri">
	<cfset recorddays = listappend(recorddays,"Fri",',')>
</cfif>

<cfif IsDefined("CBSat")>
	<input type="hidden" value="1" name="CBSat">
	<cfset recorddays = listappend(recorddays,"Sat",',')>
</cfif>

<cfif IsDefined("ignoreage")>
	<input type="hidden" value="1" name="ignoreage">
	<cfset recordsorts = listappend(recordsorts,"Ignore Age",',')>
</cfif>

<cfif IsDefined("includestarted")>
	<input type="hidden" value="1" name="includestarted">
	<cfset recordsorts = listappend(recordsorts,"Include Started",',')>
</cfif>

<cfif IsDefined("SelectFacility")>
	<input type="hidden" name="SelectFacility" value="#SelectFacility#">
	<cfset facilityval = replacenocase(SelectFacility,"'","","all")>
<CFELSE>
	<cfset facilityval = "">
</cfif>

<!--- used for page ## plus back to original search params at bottom of page --->
<cfparam name="pagehist" default="0">
<cfset pagehist = pagehist + 1>

<!--- record search in db --->
<CFIF offset EQ 0>
	<CFSET startdaterecord = "#startm1#/#startd1#/#starty1#">
	<CFSET enddaterecord = "#endm1#/#endd1#/#endy1#">

	<cfif structkeyexists(form,"IncludeDOB") and trim(form.IncludeDOB) NEQ "">
		<CFSET agegroupval = form.IncludeDOB>
	<CFELSE>
		<CFSET agegroupval = "">
	</cfif>

	<CFQUERY name="savesearch" datasource="#application.classsearchslave_dsn#">
		INSERT INTO webclasssearch
			(ipaddress,
			searchdate,
			location,
			searchtype,
			term,
			facility,
			dayofweek,
			dayofweekqualifier,
			timeofday,
			classlevel,
			<CFIF Isdate(startdaterecord)>startdate,</CFIF>
			<CFIF Isdate(enddaterecord)>enddate,</CFIF>
			patronage,
			keywords,
			classnumber,
			sortcriteria,
			instructors,
			server,
			searchresultcount)
		VALUES
			(<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.remote_addr#">,
			now(),
			<cfqueryparam cfsqltype="cf_sql_varchar" value="Registration Portal">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#getclasses#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#selectsearchtermvar#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#facilityval#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#recorddays#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#weekdayqualifier#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#thetod#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#selectclasslevel#">,
			<CFIF Isdate(startdaterecord)><cfqueryparam cfsqltype="cf_sql_date" value="#startdaterecord#">,</CFIF>
			<CFIF Isdate(enddaterecord)><cfqueryparam cfsqltype="cf_sql_date" value="#enddaterecord#">,</CFIF>
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#agegroupval#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#clean_keywords#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#clean_classlist#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#recordsorts#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#SelectInstructor#">,
			<cfqueryparam cfsqltype="cf_sql_varchar" value="#cgi.server_addr#">,
			<cfqueryparam cfsqltype="cf_sql_numeric" value="#QueryClasses.recordcount#">)
	</CFQUERY>

</CFIF>

<!--- form submitted without any patrons selected --->

<cfif IsDefined("enrollclasses") and NOT IsDefined("enrollments")>
	<table style="padding-bottom:5px;">
	<tr>
		<td style="background:##C00;border-width:1px;border-color:##000;border-style:solid;padding:2px;color:##FFF"><strong>ALERT: You have attempted an enrollment without selecting any patrons. For each desired class, click on the patron or patrons you would like to enroll. Each patron will be highlighted after you have clicked his/her name. For more info see our <a HREF="javascript:void(window.open('/portal/searchvideo.cfm?id=2','','width=650,height=515,statusbar=0,scrollbars=1,resizable=0'))" style="color:##FF9;">video walkthrough</a>.</strong></td>
	</tr>
	</table>
	<script>alert('You have attempted an enrollment without selecting any patrons. For each desired class, click on the patron or patrons you would like to enroll. Each patron will be highlighted after you have clicked his/her name.');
	</script>

	</cfif>

	<cfif structkeyexists(variables,"opencallflag") and variables.opencallflag EQ true>
	<table style="padding-bottom:5px;">
	<tr>
		<td style="background:##C00;border-width:1px;border-color:##000;border-style:solid;padding:2px;color:##FFF"><strong>ALERT: Processor response is still pending. Cart contents cannot be modified at the current time. Please contact any THPRD center for further assistance. Please note that we have reserved a spot for each for the items in your basket - you will not lose your classes even though the checkout process has been halted.</strong></td>
	</tr>
	</table>
	<script>alert('Currently, an unresolved bank call exists. Cart contents cannot be modified at the current time. Please contact any THPRD center for further assistance. Please note that we have reserved a spot for each for the items in your basket - you will not lose your classes even though the checkout process has been halted.');
	</script>

</cfif>

	<cfif structkeyexists(url,"emptycart") and url.emptycart EQ true>
     <table style="padding-bottom:5px;">
     	<tr>
          	<td style="background:##C00;border-width:1px;border-color:##000;border-style:solid;padding:2px;color:##FFF"><strong>ALERT: Your cart is empty. There is nothing to process at checkout.</strong>
               </td>
          </tr>
     </table>
	<script>alert('Your cart is empty. There is nothing to process at checkout.');
	</script>

	</cfif>



<CFPARAM name="cookie.assessalert" default="false">


<CFIF cookie.ds is 'Out Of District' and structkeyexists(queryclasses,"hasvalidassmt") EQ true>

	<CFIF listfind(valuelist(queryclasses.hasvalidassmt),'false') GT 0>

		<table style="padding-bottom:5px;" width="100%">
		<tr>
			<td style="background:##00C;border-width:1px;border-color:##000;border-style:solid;padding:2px;color:##FFF"><strong>CLASS PRICING: Out-of-District patrons may either pay a 25% surcharge or purchase an assessment to pay in-district rates.<br>
               <a href="https://www.thprd.org/portal/history/patronhistory.cfm?DisplayMode=A" style="color:##FF9;">Click here to purchase an assessment</a>.</strong> In order to purchase an assessment, shopping cart must be empty.</td>
		</tr>
		</table>

		<CFIF cookie.assessalert EQ "false">
			<script>alert('CLASS PRICING: Out-of-District patrons may either pay a 25% surcharge or purchase an assessment to pay in-district rates. To purchase and assessment, please click the Assessments link in the lefthand navigation menu.');
			</script>
			<CFSET cookie.assessalert = "true">
		</cfif>

	</CFIF>

</CFIF>



			<TABLE border="#TableBorderWidth#" WIDTH="750" cellpadding=1 cellspacing=0>
			<TR>

			<cfset BadDOBs = "">

			<cfif IsDefined("agesearch") and agesearch is "yes" and GETCLASSES is "Search For Classes">
				<!--- check dobs --->

				<cfloop index="x" list="#dobsearch#">

					<cfif not IsDate(x)>
						<cfset BadDOBs = BadDOBs & x & " ">
					</cfif>

				</cfloop>

			</cfif>

			<td valign=top class="bodytext" align=left>
				<!--- START CLASS CONTENT --->
				<span class="pghdr">Class Search Results</span><br>
				<input type="hidden" name="pagehist" value="#pagehist#">
				* Dates and Times subject to change.<br>

				<cfif UseNewCodeMethod is 0>
					Class enrollments are not guaranteed until the completion of the <strong>'Check-out</strong>' process and a receipt has been created. When you submit your registrations, the system will verify all of your selections to confirm that space is still available. If a class or program fills before you checkout, the system will place you on a waitlist and note that on your receipt. You will not be charged for any classes you are waitlisted on.<br><br>
					<b><font color="red">Adding a class to the shopping basket does not reserve or 'hold' a class opening. Class availability is determined at completion of checkout. High-demand classes selected and added to the shopping cart may not be available - even if only a minimal  interval elapses - by the time payment information is submitted.</font></b><br>
					<br>
				</cfif>

			</TD>

			<td align="right" valign="middle"><!--- &nbsp;&nbsp;<strong><cfif QueryClasses.recordcount gt 0><a href="javascript:window.print();" class="greentext">Print Results</a>&nbsp;&nbsp;|</cfif>&nbsp;&nbsp;<a href="index.cfm" class="greentext">New Search / Registration Home</a></strong> ---><!--- &nbsp;&nbsp;|&nbsp;&nbsp;<a onClick="window.open('/activities/regpush.cfm','regpush','width=920,height=675,scrollbars=yes,status=yes,toolbars=no,noresize');" href="javascript:void(0);" class="lgnmsg" style="text:decoration=none;"><strong>Register!</strong></a> --->


			<cfif GetPatrons.recordcount gt 0>



			<cfelseif getclasses is "Search For Classes" and GetPatrons.recordcount is 0>
				<strong style="color: Red;">No patrons were selected</strong>

			</cfif>

			<cfif SelectSearchTerm is "0000">
				&nbsp;&nbsp;&nbsp;&nbsp;<strong style="color: Red;">No term was selected</strong>&nbsp;&nbsp;&nbsp;&nbsp;
			</cfif>
			&nbsp;&nbsp;<A HREF="javascript:void(window.open('searchhelp.cfm','','width=500,height=500,statusbar=0,scrollbars=1,resizable=1'))">Help</A>&nbsp;&nbsp;&nbsp;&nbsp;
			</td>
			<CFIF GetPatrons.recordcount gt 0 AND QueryClasses.recordcount gt 0><td bgcolor="##FFFFCC" align="center" class="patronpick"><strong>Click Patron(s) To Select</strong><br>Highlight patron to enroll</td><CFELSE><td></td></CFIF>
			</TR>

				<tr>
					<td colspan="3" style="height: 5px;"></td>
				</tr>
			<cfset counter = 1>
			<cfset FoundValidClasses = 0>
			<cfset FoundDepositClass = 0>
			<cfset showreset = 0>
			<cfset disableprocbutton = 1>

			<cfif GetPatrons.recordcount gt 0>

			<cfloop query="QueryClasses"><!---  startrow="#startclass#" endrow="#endclass#" ---><!--- session.class_struct.records --->

			<cfif iddeposit + oddeposit gt 0 and now() lt finalpaymentdue>
				<cfset FoundDepositClass = 1>
			</cfif>

			<cfif 1 is 12>
				<cfset wdlist = "">
				<cfif SunCount greater than 0><cfset wdlist = listappend(wdlist,'Su')></cfif>
				<cfif MonCount greater than 0><cfset wdlist = listappend(wdlist,'M')></cfif>
				<cfif TueCount greater than 0><cfset wdlist = listappend(wdlist,'Tu')></cfif>
				<cfif WedCount greater than 0><cfset wdlist = listappend(wdlist,'W')></cfif>
				<cfif ThuCount greater than 0><cfset wdlist = listappend(wdlist,'Th')></cfif>
				<cfif FriCount greater than 0><cfset wdlist = listappend(wdlist,'F')></cfif>
				<cfif SatCount greater than 0><cfset wdlist = listappend(wdlist,'Sa')></cfif>
			</cfif>

			<!--- use to check if keywords are in class title --->
			<cfset newtitle = description>

			<!---
			<cfif keywords is not ''>
				<cfset keywordlist = listchangedelims(keywords,' ',',')>
				<cfset KeyStringArray = ListToArray(keywordlist," ")>
				<cfset tempkw = "">

				<cfloop from="1" to="#arraylen(KeyStringArray)#" index="keyword">

					<cfif tempkw is not KeyStringArray[keyword] and len(KeyStringArray[keyword]) gt 1>
						<cfset newtitle = replacenocase(newtitle,'#KeyStringArray[keyword]#','<span class="bodytext_red">#ucase(KeyStringArray[keyword])#</span>','all')>
					</cfif>

					<cfset tempkw = KeyStringArray[keyword]>
				</cfloop>

			</cfif>
			--->

			<cfif startdt lt now() or statusdesc is "Canceled" or now() lt allowweb>
				<cfset st = 0>
			<cfelse>
				<cfset st = 1>
				<cfset showreset = 1>
			</cfif>



			<tr bgcolor="#bgcolor#">
				<td class="lgnusr" nowrap valign=top><strong>#newtitle#</strong>
				<cfif levels is not "" and listlen(levels) LT 20>
					<br>Level(s): #replace(replace(levels, "-", "", "all"), ",", ", ", "all")#<br>
				</cfif></TD>
				<!---
				<cfif now() gt enddt and statusdesc is not "Canceled">
					<TD align="right"><span class="redtext">Class has completed</span></TD>
				<cfelseif startdt lt now() and statusdesc is not "Canceled">
					<TD align="right"><span class="redtext">Class has started</span></TD>
				<cfelse>
					<TD>&nbsp;</TD>
				</cfif>
				--->
				<TD class="lgnusr" valign=top><strong>#classID# - #TermName#</strong></td>
				<CFIF bgcolor EQ "ffffff"><CFSET thisbg = "##ffffee"><CFELSE><CFSET thisbg = "##ffffcc"></CFIF>
				<TD rowspan="4"  bgcolor="#bgcolor#" class="patronpick" align="center">

				<select style="width: 200px;font-family: Courier;Courier New;Consolas;monospace;Lucida Console;font-size:12px;" multiple size="5" <cfif st is 0>disabled</cfif> name="enrollments" class="form_input">

<!--- testing 03/025/2015 --->


					<cfif statusdesc is "Canceled">
						<option disabled value="0^0^0" style="color:##CCCCCC;">Not Available
						<option disabled value="0^0^0" style="color:##CCCCCC;">Class Canceled

					<cfelseif cookie.ds is 'Out Of District' and outdistrictopen EQ false>
						<option disabled value="0^0^0" style="color:##CCCCCC;">Not Available Until
						<option disabled value="0^0^0" style="color:##CCCCCC;">#DateFormat(allowoddt, "mm/dd")# #lCase(timeformat(allowoddt, "hh:mmtt"))#
						<option disabled value="0^0^0" style="color:##CCCCCC;">(Out Of District)
					<!---
					<cfelseif cookie.ds is 'Out Of District' and hasvalidassmt is 0 AND (allocated - EWPClassAllocated LT MaxQTY OR Waitlist EQ 0)>
						<option disabled value="0^0^0" style="color:##CCCCCC;">Not Available
						<option disabled value="0^0^0" style="color:##CCCCCC;">Assessment Required
					--->



					<cfelseif indistrictopen EQ false and 1 is 1>
						<option disabled value="0^0^0" style="color:##CCCCCC;">Not Available Until
						<option disabled value="0^0^0" style="color:##CCCCCC;">#DateFormat(allowweb, "mm/dd")# #lCase(timeformat(allowweb, "hh:mmtt"))#

					<cfelseif now() gt enddt>
						<option disabled value="0^0^0" style="color:##CCCCCC;">Not Available
						<option disabled value="0^0^0" style="color:##CCCCCC;">Class Completed

					<cfelseif startdt lt now()>
						<option disabled value="0^0^0" style="color:##CCCCCC;">Not Available
						<option disabled value="0^0^0" style="color:##CCCCCC;">Class Started

					<cfelse><!--- if startdt gt now() and QueryClasses.statusdesc[QueryClasses.currentrow] is "A" --->



						<cfset FoundValidClasses = 1>
						<CFSET theoptcolor = "FFFFFF">
						<cfloop query="GetPatrons">
							<cfset go = 1>
							<cfset l = "">

							<cfif FindNoCase("summer", QueryClasses.TermName[QueryClasses.currentrow]) is 0 and relationtype is 4>
								<!--- check for grandchild and summer classes ONLY --->
								<cfif IsDefined("ignoreage")>
									<option disabled value="0^0^0" style="color:##CCCCCC;">#Firstname# (Grandchild N/A)
								</CFIF>
								<cfset go = 0>
							<cfelseif dob gt QueryClasses.maxdob[QueryClasses.currentrow] or dob lt QueryClasses.mindob[QueryClasses.currentrow]>
								<!--- check for age vs class age restriction --->
								<cfset go = 0>

								<cfif IsDefined("ignoreage")>
									<option disabled value="0^0^0" style="color:##CCCCCC;">#Firstname# (Age Violation)
								</cfif>

							<cfelse>
								<!--- check for already enrolled --->
								<cfset showasinrolled = 0>
                                        <cfset showaswaitlist = 0>
								<!--- completed enrollments --->
								<cfloop query="GetRegistrations">

									<cfif ListFind(ValueList(GetPatrons.secondarypatronid), patronid) gt 0>

										<cfif patronid is GetPatrons.secondarypatronid[GetPatrons.currentrow] and uniqueid is QueryClasses.uniqueid[QueryClasses.currentrow]>
											<cfset showasinrolled = 1>
                                                       	<CFIF findnocase('W',getRegistrations.regstatus)>
                                                            	<cfset showaswaitlist = 1>
                                                            </CFIF>
											<cfbreak>
										</cfif>

									</cfif>

								</cfloop>
								<!--- shopping cart --->
								<cfloop query="GetNewRegistrations">

									<cfif ListFind(ValueList(GetPatrons.secondarypatronid), patronid) gt 0>

										<cfif patronid is GetPatrons.secondarypatronid[GetPatrons.currentrow] and termid is QueryClasses.termid[QueryClasses.currentrow] and facid is QueryClasses.facid[QueryClasses.currentrow] and classid is QueryClasses.classid[QueryClasses.currentrow]>
											<cfset showasinrolled = 1>
                                                       	<CFIF findnocase('W',getNewRegistrations.regstatus)>
                                                            	<cfset showaswaitlist = 1>
                                                            </CFIF>
											<cfbreak>
										</cfif>

									</cfif>

								</cfloop>

								<cfif showaswaitlist is 1>
									<option disabled value="0^0^0" style="color:##CCCCCC;">#Firstname# (Waitlist)
									<cfset go = 0>


								<cfelseif showasinrolled is 1>
									<option disabled value="0^0^0" style="color:##CCCCCC;">#Firstname# (Enrolled)
									<cfset go = 0>
								</cfif>

							</cfif>






							<cfif go is 1 and Find(QueryClasses.leveltypecode[QueryClasses.currentrow], "ADT") gt 0>

								<!--- A=Aquatics N=None T=Tennis D=Diving --->
								<cfset FoundLevel = 0>

                                        <!--- if instrlevela is NULL set to 1 --->
                                        <CFIF ltrim(rtrim(instrlevela)) is "">
                                        	<CFSET GetPatrons.instrlevela = "1">
                                        </CFIF>


								<cfif (QueryClasses.leveltypecode[QueryClasses.currentrow] is "A" and Find(ltrim(rtrim("-" & instrlevela & "-")), QueryClasses.levels[QueryClasses.currentrow]) gt 0)>
									<cfset FoundLevel = 1>
									<cfset l = instrlevela>

								<cfelseif (QueryClasses.leveltypecode[QueryClasses.currentrow] is "D" and Find(ltrim(rtrim(instrleveld)), QueryClasses.levels[QueryClasses.currentrow]) gt 0)>
									<cfset FoundLevel = 1>
									<cfset l = instrleveld>

								<cfelseif (QueryClasses.leveltypecode[QueryClasses.currentrow] is "T" and Find(ltrim(rtrim("-" & instrlevelt & "-")), QueryClasses.levels[QueryClasses.currentrow]) gt 0)>
									<cfset FoundLevel = 1>
									<cfset l = instrlevelt>

								</cfif>



								<cfif FoundLevel is 0>

									<cfif QueryClasses.leveltypecode[QueryClasses.currentrow] is "A" and ltrim(rtrim(instrlevela)) is "">								<!--- Aquatics wants level set to one if patron has no record --->
										<cfset FoundLevel = 0>
										<cfset l = instrlevela>
									</cfif>

									<cfif QueryClasses.leveltypecode[QueryClasses.currentrow] is "D" and ltrim(rtrim(instrleveld)) is "">
										<cfset FoundLevel = 1>
										<cfset l = instrleveld>
									</cfif>

									<cfif QueryClasses.leveltypecode[QueryClasses.currentrow] is "T" and ltrim(rtrim(instrlevelt)) is "">
										<cfset FoundLevel = 1>
										<cfset l = instrlevelt>
									</cfif>

                                             <!--- redundant? --->
									<cfif l is "">

										<cfif QueryClasses.leveltypecode[QueryClasses.currentrow] is "A">
											<cfset l = instrlevela>
										</cfif>

										<cfif QueryClasses.leveltypecode[QueryClasses.currentrow] is "D">
											<cfset l = instrleveld>
										</cfif>

										<cfif QueryClasses.leveltypecode[QueryClasses.currentrow] is "T">
											<cfset l = instrlevelt>
										</cfif>

									</cfif>

								</cfif>

								<cfif FoundLevel is 0>
									<option disabled value="0^0^0" style="color:##CCCCCC;">#Firstname#<cfif ltrim(rtrim(l)) is not ""> (Level #l#)</cfif>
									<cfset go = 0>
								</cfif>

							</cfif>

							<cfif go is 1>

                                   <!--- do price and misc fee lookup for each patron --->
                                   <cfquery datasource="#application.dopsds#" name="GetClassRate">
 select   dops.getregrate( #primarypatronid#::integer, #secondarypatronid#::integer, '#QueryClasses.TermID[QueryClasses.currentrow]#'::varchar, '#QueryClasses.FacID[QueryClasses.currentrow]#'::varchar, '#QueryClasses.ClassID[QueryClasses.currentrow]#'::varchar ) as v
</cfquery>
<cfset classcost = GetClassRate.v>

<cfquery datasource="#application.dopsds#" name="GetDeposit">
 select   dops.getregrate( #primarypatronid#::integer, #secondarypatronid#::integer, '#QueryClasses.TermID[QueryClasses.currentrow]#'::varchar, '#QueryClasses.FacID[QueryClasses.currentrow]#'::varchar, '#QueryClasses.ClassID[QueryClasses.currentrow]#'::varchar, true) as d
</cfquery>
<cfset deposit = GetDeposit.d>
<cfset cost = replacenocase(numberformat(classcost + QueryClasses.miscfee[QueryClasses.currentrow],"___.__"),' ','&nbsp;','all')>


								<option value="#QueryClasses.UniqueID[QueryClasses.currentrow]#^#secondarypatronid#^#QueryClasses.UniqueID[QueryClasses.currentrow] + secondarypatronid#" style="background-color:###theoptcolor#;border-bottom-width:1px;border-bottom-style:solid;border-bottom-color:##CCC;color:##000;"><cfif l is not ""><CFSET leveldisp = '(Level #l#)'><CFELSE><CFSET leveldisp = ''></cfif>#replacenocase(ljustify(firstname & leveldisp,15),' ','&nbsp;','all')# $#cost#<CFIF deposit NEQ 0>*</CFIF></option>


															<CFIF theoptcolor EQ "FFFFFF">
                                   	<CFSET theoptcolor = "FFF">
                                   <CFELSE>
                                   	<CFSET theoptcolor = "FFFFFF">
                                   </CFIF>

								<cfset disableprocbutton = 0>
							</cfif>

						</cfloop>

					</cfif>

				</select>
                                   <CFIF Structkeyexists(variables,"deposit") and deposit NEQ 0>
               	<div style="width:200px;background:##FC0;padding:2px;margin-top:2px;margin-bottom:2px;text-align:left;color:##000;">

                    <div style="background:##333;color:##fff;padding:2px"><strong>Deposit Available: $#decimalformat(deposit)#</strong></div>
                    <div  align="center">
                    <input type="checkbox" value="#QueryClasses.ClassID[QueryClasses.currentrow]#" name="UseDepositMode"> Enroll as <strong>'Deposit Only' (D)</strong></div>
                    </div>

               </CFIF>

				</TD>
			</tr>
			<tr bgcolor="#bgcolor#">
				<td class="bodytext" nowrap valign=top style="padding-right: 5px;">#DateFormat(StartDT,"mmm d, yyyy")#<cfif DateFormat(StartDT,"mmm d, yyyy") is not DateFormat(EndDT,"mmm d, yyyy")> - #DateFormat(EndDT,"mmm d, yyyy")#</cfif>&nbsp;&nbsp;&nbsp;#lCase(TimeFormat(StartDT,"h:mmtt"))# to #lCase(TimeFormat(EndDT,"h:mmtt"))#<br>
				<strong>Day(s):</strong>&nbsp;&nbsp;<cfif wdlist is ''>N/A<cfelse>#wdlist#</cfif>
				<cfset _VarYears = int(MinAgeMonths/12)>
				<cfset _VarMonths = MinAgeMonths - (_VarYears * 12)>

				&nbsp;&nbsp;&nbsp;<strong>Ages:</strong>&nbsp;&nbsp;#int(MinAgeMonths/12)# yrs, #evaluate(MinAgeMonths - (int(MinAgeMonths/12) * 12))# mths <cfif  MaxAgeMonths gte 99 * 12>and up<cfelse>to #int(MaxAgeMonths/12)# yrs, #evaluate(MaxAgeMonths - (int(MaxAgeMonths/12) * 12))# mths</cfif></td>
				<td class="bodytext" nowrap valign=top><span class="lgnmsg">#name#</span><br>
					<strong>Status:</strong>&nbsp;&nbsp;

					<cfif statusdesc is not 'Canceled' and enddt lt now()>
						Completed
					<cfelseif statusdesc is not 'Active'>
						<span style="color:##ff0000; font-weight:bold">#statusdesc#</span>
					<cfelseif allocated - EWPClassAllocated GTE MaxQTY OR waitlist GT 0>
						<span style="color:##ff0000; font-weight:normal">Full / Wait List Available</span>
					<cfelse>
						#statusdesc#
					</cfif>

				</td>
			</tr>
			<tr bgcolor="#bgcolor#">
				<td nowrap valign=top class="bodytext"><strong>ID:</strong>&nbsp;<cfif MinAgeMonths lt scmonths>Regular $#DecimalFormat(InDistRegFee)#<cfif MaxAgeMonths gte scmonths>, </cfif></cfif><cfif MaxAgeMonths gte scmonths>Senior $#DecimalFormat(InDistSenFee)#</cfif><cfif decimalformat(iddeposit) gt 0>, <strong>Dep $#decimalformat(iddeposit)#</strong></cfif>&nbsp; &nbsp;&nbsp;<strong>OD:</strong>&nbsp;<cfif MinAgeMonths lt scmonths>Regular ($#DecimalFormat(OutDistRegFee)#)<cfif MaxAgeMonths gte scmonths>, </cfif></cfif><cfif MaxAgeMonths gte scmonths>Senior $#DecimalFormat(OutDistSenFee)#</cfif><cfif decimalformat(oddeposit) gt 0>, Dep $#decimalformat(oddeposit)#</cfif> <cfif DecimalFormat(MiscFee) gt 0>&nbsp;-&nbsp;<strong>Misc. Fee</strong> $#DecimalFormat(MiscFee)#</cfif></td>
				<td><cfif startdt lt now() and statusdesc is not "Canceled"><span style="color:##ffffff; font-weight:bold; background-color:##ff0000;">&nbsp;Class has started&nbsp;</span></CFIF></td>
			</tr>
			<tr bgcolor="#bgcolor#">

			<!--- <cfset tmpinstr = "">
			<cfset IsFirstInstructor = 1>

			<cfif IsDefined("GetInstructorsForThisSet.recordcount")>

				<cfloop query="GetInstructorsForThisSet">

					<cfif termid is QueryClasses.termid[QueryClasses.currentrow] and facid is QueryClasses.facid[QueryClasses.currentrow] and activity is QueryClasses.classid[QueryClasses.currentrow]>

						<cfif IsFirstInstructor is 0>
							<cfset tmpinstr = tmpinstr & ", ">
						</cfif>

						<cfset tmpinstr = tmpinstr & InstructorName>
						<cfset IsFirstInstructor = 0>
					</cfif>

				</cfloop>

			</cfif> --->

			<td nowrap valign=top>
				<strong>Instructor(s):</strong>&nbsp;&nbsp;


			<cfquery datasource="#application.dopsds#" name="GetInstructorNames">
				select    dops.getclassinstructorsaslist( '#termid#', '#facid#', '#classid#' ) as InstructorNames
			</cfquery>


			<cfif GetInstructorNames.InstructorNames is "">N/A<cfelse>#GetInstructorNames.InstructorNames#</cfif>




			</td>
			<td nowrap valign=top><cfif ClassTextLength gt 0><A HREF="javascript:void(window.open('cdescription.cfm?cID=#uniqueID#&keywords=#keywords#','description','width=400,height=300,statusbar=0,scrollbars=1,resizable=0'))" class="greentext">View Description</a></cfif><cfif ClassCommentsLength gt 0 and ClassTextLength gt 0>&nbsp;&nbsp;|&nbsp;&nbsp;</cfif><cfif ClassCommentsLength gt 0><A HREF="javascript:void(window.open('ccomments.cfm?cID=#uniqueID#','comments','width=400,height=300,statusbar=0,scrollbars=1,resizable=0'))" class="greentext">View Comments</A></cfif>&nbsp;&nbsp;</td>
			</tr>

			<cfif counter lt QueryClasses.recordcount>
				<tr>
					<td colspan="3" style="height: 5px;"></td>
				</tr>
			</cfif>

			<cfset counter = counter + 1>

			<cfif bgcolor is 'ededed'>
				<cfset bgcolor = "ffffff">
			<cfelse>
				<cfset bgcolor = "ededed">
			</cfif>

			</cfloop>

			</cfif>

			<tr>
				<td colspan="3" style="height: 5px;"></td>
			</tr>
			<tr>
			<td valign="top" align="left">

			<cfif QueryClasses.recordcount gt 0 and showreset is 1 and GetPatrons.recordcount gt 0>
				<input type="button" value="Clear Selections" class="form_submit" onClick="javascript:form.reset()">
			</cfif>

			<input type="submit" value="Modify Search" class="form_submit" name="gomain"><!--- onClick="javascript:;history.go(-#pagehist#)" --->
			<!--- <input type="submit" value="test" class="form_submit" name="gomain"> --->
			</td>
			<TD align="right"  valign="top">

			<cfif QueryClasses.recordcount lt returnqty>
				<strong>No further class matches</strong>&nbsp;&nbsp;&nbsp;&nbsp;
			</cfif>

			<cfif offset gt 0>
				<input type="submit" name="prevclasses" value="<< Previous" class="form_submit" style="width: 85px;">
			</cfif>

			<input type="hidden" name="offset" value="#offset#">

			<cfif QueryClasses.recordcount gte returnqty and QueryClasses.recordcount gt 0>
				<input type="submit" name="nextclasses" value="More >>" class="form_submit" style="width: 75px;">&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;
			</cfif>
			</td>
			<cfif QueryClasses.recordcount gt 0 and GetPatrons.recordcount gt 0>
			<td  align="center" class="patronpick" bgcolor="##ffffcc">

				<input type="submit" name="enrollclasses" value="Enroll Selected Patron(s)" style="background-color:##0000cc;font-weight:bold;font-size:12px;color:##ffffff;padding:2px;"<cfif FoundValidClasses is 0 or disableprocbutton is 1> disabled</cfif>>

                    <!---
                    <cfif QueryClasses.recordcount gt 0>
					<input style="background-color:##666;font-weight:normal;font-size:10px;color:##FFFFFF;" type="button" value="Clear" class="form_submit" onClick="javascript:form.reset()">&nbsp;&nbsp;&nbsp;

				</cfif>--->
<!---
			<cfif FoundDepositClass is 1>
			<table width="100%"><tr><td  align="center"><input type="checkbox" name="UseDepositMode">Enroll as <strong><u>Deposit Only</u> (D)</strong></td></tr></table><cfelse></cfif>--->


			</td>
			<CFELSE>
			<td></td>
			</cfif>
			</tr>
			</TABLE>

		 </td>
		</tr>
		</table>

	</cfif>

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
</form>

</cfoutput>

<CFINCLUDE template="/portalINC/googleanalytics.cfm">



</body>
</html>

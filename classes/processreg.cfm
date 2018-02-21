<cfif not IsDefined("enrollmentpairs")>

     <td><br />
     <strong>No enrollment data found.</strong>
	</td>
  </tr>
 <tr>
   <td colspan="2" valign="top">&nbsp;</td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">
</table>
</body>
</html>

	<cfabort>
</cfif>

<cfset primarypatronid = cookie.uID>
<CFPARAM name="variables.opencallflag" default="false">

<!---// must confirm user is in WWW session before continuing //--->
<CFSET checksession = sessioncheck(primarypatronid)>
<CFIF checksession.sessionID NEQ 0>
	<CFSET CurrentSessionID = checksession.sessionID>
<CFELSE>
	<CFSET CurrentSessionID = 0>
				<td valign="top">
				<table>
				<tr>
				<td><br><br><br>
				Error determining session. <strong>Please log out and log back in</strong>. <a href="javascript:history.back();"><< </a> <a href="javascript:history.back();">Go back</a><br />
				<br>
				If the error persists, <a href="mailto:webadmin@thprd.org"><font color="red"><strong>please contact IT</strong></font></a> as soon as possible. <br />
				Please include your THPRD ID, Browser, computer operating system and the class ID.<br>Thank you for your assistance.<br />
				<CFMAIL to="webadmin@thprd.org" from="webadmin@thprd.org" subject="WWW Portal Session Catch" type="html">
				Error determining session. Session ID not found.<br />
				Server Address: #cgi.server_addr#<br />

				The patronID passed in the query is: #PrimaryPatronID#.<br />
				The patron IP address is: #cgi.remote_addr#.<br />

				<CFDUMP var="#form#">

				<CFDUMP var="#cookie#">

				<CFDUMP var="#checksession#">

				</CFMAIL>
				<CFHTTP url="https://www.thprd.org/portal/sessioncatch.cfm?ipaddress=#cgi.remote_addr#"></CFHTTP>
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
</html>
				<CFABORT>
</CFIF>

<!--- do not allow changes to cart if in limbo --->
<cfquery name="CheckForOpenCall" datasource="#application.dopsds#">
	select dops.hasopencall( #PrimaryPatronID#::integer ) as call
</cfquery>

<cfif CheckForOpenCall.call and 0>

<CFMAIL to="webadmin@thprd.org" from="webadmin@thprd.org" cc="dhayes@thprd.org" subject="Shopping Cart Locked: Open Call" type="html">
This was sent by processreg.cfm
<CFDUMP var="#form#">
<CFDUMP var="#cookie#">
<CFDUMP var="#checksession#">
</CFMAIL>

<cfset opencallflag = "true">
<cfset errormsg = 1>
<CFSET dc="">

</cfif>



<!--- enable for production --->
<cfset EnableEmail = 0>

<!---
<cfif cookie.insession EQ "false">
<!---No session detected for logged in user. This can be due to THPRD staff taking control of this session. If this is not the case, try clicking <strong>Class Search</strong> again.<br />
<br />
<strong>Creating session.</strong><br />
--->
<cfset t_session = cookie.sessionID>
<CFQUERY name="loadhousehold" datasource="#application.dopsds#">
select dops.webloadhousehold(#primarypatronid#, '#t_session#') as sessionlogin
</CFQUERY>
<CFCOOKIE name="insession" value="true">
</cfif>
--->

<cfset tc = gettickcount()>

<!--- <cfset tArray = ArrayNew(1)>
<cfset ArrayAppend(tArray, gettickcount())> --->

<!--- toggle for allowing Wl to be created --->
<cfset AllowWL = 1>
<cfset localfac = "WWW">
<cfset localnode = "W1">
<cfset EWPRelinquishEmail = 0>
<cfset huserid = 0>

<cfif cookie.ds is 'Out of District'>
	<cfset PrimaryPatronInDistrict = 0>
<cfelse>
	<cfset PrimaryPatronInDistrict = 1>
</cfif>

<!--- <cfinclude template="reg_functions.cfm"> --->

<cfif not IsDefined("GetPatrons")>

	<cfquery datasource="#application.dopsds#" name="GetPatrons">
		select   secondarypatronid, patrons.lastname, patrons.firstname, patrons.dob, relationtype, patrons.ismil
		from     patronrelations
		         inner join patrons on secondarypatronid=patrons.patronid
		where    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="CF_SQL_INTEGER">
		order by patrons.firstname
	</cfquery>

</cfif>



<CFIF opencallflag EQ false>

<!--- use array enrollmentpairs  1: class uniqueid  2: patronid--->
<cfloop from="1" to="#ArrayLen(enrollmentpairs)#" step="1" index="q">
	<cfset thispatrondob = "">
	<cfset patronid = 0>

	<cfloop query="GetPatrons">

		<cfif secondarypatronid is enrollmentpairs[q][2]>
			<cfset thispatrondob = dob>
			<cfset patronid = secondarypatronid>
               <cfset patronismil = getPatrons.ismil>
			<cfbreak>
		</cfif>

	</cfloop>

	<cfif patronid gt 0>

		<cftransaction action="BEGIN" isolation="READ_COMMITTED">



		<!--- <CFQUERY name="createlock" datasource="#application.dopsdsro#">
			SELECT  uniqueid<!--- pg_advisory_lock(uniqueid) --->
			FROM    dops.classes
			where   uniqueid = <cfqueryparam value="#enrollmentpairs[q][1]#" cfsqltype="CF_SQL_INTEGER">
			for     update
		</CFQUERY> --->

		<!--- get class data --->
		<!--- skip any that patron is already enrolled in --->
		<cfquery datasource="#application.dopsds#" name="GetClassData">
			select   classesview.uniqueid,
			         classesview.termid,
			         classesview.facid,
			         classesview.classid,
			         classesview.maxqty,
			         classesview.startdt,
			         classesview.enddt,
			         classesview.BusinessCenterID,
			         classesview.indistregfee,
			         classesview.outdistregfee,
			         classesview.indistsenfee,
			         classesview.outdistsenfee,
			         classesview.miscfee,
			         classesview.iddeposit,
			         classesview.oddeposit,
			         classesview.finalpaymentdue,
			         classesview.scmonths,
			         classesview.wlcount,
			         classesview.glacctid,
			         classesview.glmiscacctid,
			         classesview.regcount + wlcount as allocated,
			         classesview.ewpcount,
			         0 as senior
			from     dops.ClassesView
			where    ClassesView.uniqueid = <cfqueryparam value="#enrollmentpairs[q][1]#" cfsqltype="CF_SQL_INTEGER" list="no">
			and      not exists(

			select   reg.pk
			from     dops.reg
			where    reg.patronid = <cfqueryparam value="#enrollmentpairs[q][2]#" cfsqltype="CF_SQL_INTEGER" list="no">
			and      reg.termid = classesview.termid
			and      reg.facid = classesview.facid
			and      reg.classid = classesview.classid
			and      position( reg.regstatus in <cfqueryparam value="EARHW" cfsqltype="cf_sql_varchar" list="no"> ) > <cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no"> )
		</cfquery>

		<cfif GetClassData.recordCount gt 1>
			<BR><BR><strong>Error in determining unique class. Try searching again.</strong>
			<cfabort>
		</cfif>

		<cfif GetClassData.recordcount is 1>
			<cfset ThisClassAllocated = GetClassData.allocated>
			<cfset ThisClassWLCount = GetClassData.wlcount>
			<cfset LoadClassDataAgin = 0>

			<cfif DateAdd("m", (-1 * GetClassData.scmonths), GetClassData.startdt) gt thispatrondob>
				<cfset QuerySetCell(GetClassData, "senior", 1)>
			</cfif>

			<CFIF cookie.ds EQ "In District">
				<CFSET theds = "1">
			<CFELSE>
				<CFSET theds = "0">
			</CFIF>

               <!---
			<cfset classcost = GetRate("R", GetClassData.indistregfee, GetClassData.indistsenfee, GetClassData.outdistregfee, GetClassData.outdistsenfee, PrimaryPatronID, thisPatronDOB, GetClassData.facid, GetClassData.BusinessCenterID, theds, GetClassData.Startdt, GetClassData.Enddt)>
			--->

               <cfquery datasource="#application.dopsds#" name="CheckRate">
			select dops.getregrate( #primarypatronid#::integer, #enrollmentpairs[q][2]#::integer, '#GetClassData.termid#'::varchar, '#GetClassData.facid#'::varchar, '#GetClassData.classID#'::varchar) as v
               </cfquery>
			<cfset classCost = CheckRate.v>



			<cfif PrimaryPatronInDistrict is 1>
				<cfset depositrequired = GetClassData.iddeposit>
			<cfelse>
				<cfset depositrequired = GetClassData.oddeposit>
			</cfif>

			<cfif depositrequired is 0>
				<cfset AllowDeposit = 0>
			<cfelse>
				<cfset AllowDeposit = 1>
			</cfif>

			<cfif now() gt GetClassData.finalpaymentdue>
				<cfset AllowDeposit = 0>
			</cfif>

			<cfif AllowDeposit is 0>
				<cfset depositrequired = 0>
			</cfif>

			<cfset patronid = enrollmentpairs[q][2]>

			<!--- get registrations flagged as GetWaitListCount
			<cfquery datasource="#application.dopsds#" name="GetWaitListCount">
				select  coalesce(count(*),0) as GetWaitListCount
				from    Reg
				where   TermID = <cfqueryparam value="#GetClassData.TermID#" cfsqltype="CF_SQL_VARCHAR">
				and     FacID = <cfqueryparam value="#GetClassData.FacID#" cfsqltype="CF_SQL_VARCHAR">
				and     ClassID = <cfqueryparam value="#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">
				and     RegStatus = <cfqueryparam value="W" cfsqltype="CF_SQL_CHAR">
			</cfquery> --->

			<!--- pass 1 checks for any standby registrations and deletes if needed --->
			<!--- pass 2 loads data and continues to normal registration--->
			<cfloop from="1" to="2" step="1" index="z">
				<!--- get class allocated --->

				<cfif LoadClassDataAgin is 1>
					<!--- get new allocations --->
					<cfquery datasource="#application.dopsds#" name="GetClassAllocated2">
						<!--- SELECT   coalesce(count(*),0) AS Allocated
						FROM     REG REG
						WHERE    REG.TERMID = <cfqueryparam value="#GetClassData.TermID#" cfsqltype="CF_SQL_VARCHAR">
						AND      REG.FACID = <cfqueryparam value="#GetClassData.FacID#" cfsqltype="CF_SQL_VARCHAR">
						AND      REG.CLASSID = <cfqueryparam value="#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">
						AND      REG.REGSTATUS in ('E','W','A','R','H') --->

						SELECT   wlcount, regcount + wlcount AS Allocated
						FROM     dops.classesview
						WHERE    TERMID = <cfqueryparam value="#GetClassData.TermID#" cfsqltype="CF_SQL_VARCHAR">
						AND      FACID = <cfqueryparam value="#GetClassData.FacID#" cfsqltype="CF_SQL_VARCHAR">
						AND      CLASSID = <cfqueryparam value="#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">
					</cfquery>

					<cfset ThisClassAllocated = GetClassAllocated2.Allocated>
					<cfset ThisClassWLCount = GetClassAllocated2.wlcount>
				</cfif>

				<cfif z is 2>
					<cfbreak>

				<cfelseif GetClassData.allocated gte GetClassData.maxqty and GetClassData.ewpcount gt 0>
					<!--- relinquish newest registration, if needed --->
					<cfquery datasource="#application.dopsds#" name="GetLastStandbyRegAllocated">
						SELECT   REG.PRIMARYPATRONID, REG.REGID, reg.patronid, reg.indistrict
						FROM     REG
						         INNER JOIN REGHISTORY ON REG.PRIMARYPATRONID=REGHISTORY.PRIMARYPATRONID AND REG.REGID=REGHISTORY.REGID
						         INNER JOIN CLASSES ON REG.TERMID=CLASSES.TERMID AND REG.FACID=CLASSES.FACID AND REG.CLASSID=CLASSES.CLASSID
						WHERE    REG.TERMID = <cfqueryparam value="#GetClassData.TermID#" cfsqltype="CF_SQL_VARCHAR">
						AND      REG.FACID = <cfqueryparam value="#GetClassData.FacID#" cfsqltype="CF_SQL_VARCHAR">
						AND      REG.CLASSID = <cfqueryparam value="#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">
						AND      REG.REGSTATUS = <cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">
						AND      REG.ISSTANDBY
						AND      REG.RELINQUISHDT is NULL
						AND      CLASSES.STARTDT > now()
						ORDER BY REGHISTORY.DT DESC
						limit    1
					</cfquery>

					<cfif GetLastStandbyRegAllocated.recordcount is 1 and (ThisClassAllocated gte GetClassData.maxqty or ThisClassWLCount gt 0)>
						<!--- relinquish registration --->

						<cfquery datasource="#application.dopsds#" name="GetLastStandbyRegAllocated">
							SELECT   REG.PRIMARYPATRONID, REG.REGID, reg.patronid, FACILITIES.NAME,
							         PATRONS.LASTNAME, PATRONS.FIRSTNAME, reg.indistrict
							FROM     REG
							         INNER JOIN REGHISTORY ON REG.PRIMARYPATRONID=REGHISTORY.PRIMARYPATRONID AND REG.REGID=REGHISTORY.REGID
							         INNER JOIN FACILITIES ON REG.FACID=FACILITIES.FACID
							         INNER JOIN PATRONS ON REG.PATRONID=PATRONS.PATRONID
							         INNER JOIN CLASSES ON REG.TERMID=CLASSES.TERMID AND REG.FACID=CLASSES.FACID AND REG.CLASSID=CLASSES.CLASSID
							WHERE    REG.TERMID = <cfqueryparam value="#GetClassData.TermID#" cfsqltype="CF_SQL_VARCHAR">
							AND      REG.FACID = <cfqueryparam value="#GetClassData.FacID#" cfsqltype="CF_SQL_VARCHAR">
							AND      REG.CLASSID = <cfqueryparam value="#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">
							AND      REG.REGSTATUS = <cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">
							AND      REG.ISSTANDBY
							AND      REG.RELINQUISHDT is NULL
							AND      CLASSES.STARTDT > now()
							ORDER BY REGHISTORY.DT DESC
							limit    1
						</cfquery>

						<cfquery datasource="#application.dopsds#" name="CheckForInvoiced">
							SELECT   REGHISTORY.INVOICENUMBER
							FROM     REG
							         INNER JOIN REGHISTORY ON REG.PRIMARYPATRONID=REGHISTORY.PRIMARYPATRONID AND REG.REGID=REGHISTORY.REGID
							WHERE    REG.PRIMARYPATRONID = <cfqueryparam value="#GetLastStandbyRegAllocated.PRIMARYPATRONID#" cfsqltype="CF_SQL_INTEGER">
							AND      REG.REGID = <cfqueryparam value="#GetLastStandbyRegAllocated.REGID#" cfsqltype="CF_SQL_INTEGER">
						</cfquery>

						<cfquery datasource="#application.dopsds#" name="InsertRegHistory">
							select dops.insertregproc(<cfqueryparam value="#GetLastStandbyRegAllocated.PRIMARYPATRONID#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="#GetLastStandbyRegAllocated.REGID#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="R" cfsqltype="CF_SQL_CHAR">, <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="W1" cfsqltype="CF_SQL_VARCHAR">)
						</cfquery>

						<cfif CheckForInvoiced.INVOICENUMBER is "">
							<!--- drop non-invoiced class --->
							<!--- <cfquery datasource="#application.dopsds#" name="GetAdjToDelete">
								select   EC
								from     reghistory
								where    RegID = <cfqueryparam value="#GetLastStandbyRegAllocated.RegID#" cfsqltype="CF_SQL_INTEGER">
								and      primarypatronid = <cfqueryparam value="#GetLastStandbyRegAllocated.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
								and      action = <cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">
								and      finished = <cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
							</cfquery> --->

							<cfquery datasource="#application.dopsds#" name="DropClass">
								delete   from reghistory
								where    RegID = <cfqueryparam value="#GetLastStandbyRegAllocated.RegID#" cfsqltype="CF_SQL_INTEGER">
								and      PrimaryPatronID = <cfqueryparam value="#GetLastStandbyRegAllocated.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
								and      action = <cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">
								and      finished = <cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
								;
								delete   from reg
								where    RegID = <cfqueryparam value="#GetLastStandbyRegAllocated.RegID#" cfsqltype="CF_SQL_INTEGER">
								and      PrimaryPatronID = <cfqueryparam value="#GetLastStandbyRegAllocated.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
							</cfquery>

						<cfelse>
							<!--- drop invoiced class --->
							<cfset NextEC = GetNextEC()>

							<!--- if money was tendered, put back as DC credit on new drop invoice --->
							<cfquery datasource="#application.dopsds#" name="GetFeePaid">
								SELECT   coalesce(REGHISTORY.AMOUNT,0) as amount
								FROM     REGHISTORY REGHISTORY
								WHERE    REGHISTORY.PRIMARYPATRONID = <cfqueryparam value="#GetLastStandbyRegAllocated.PRIMARYPATRONID#" cfsqltype="CF_SQL_INTEGER">
								AND      REGHISTORY.REGID = <cfqueryparam value="#GetLastStandbyRegAllocated.REGID#" cfsqltype="CF_SQL_INTEGER">
							</cfquery>

							<cfif GetFeePaid.recordcount is 0>
								<strong>Error in determining relinquishment. Go back and try again. Contact THPRD if problem persists.</strong><br><br>
								<cfabort>
							</cfif>

							<cfset LoadClassDataAgin = 1>

							<cfif (GetFeePaid.recordcount gt 0 and GetFeePaid.amount gt 0) or 1 is 1><!--- remove override is want to suppress $0 invoice --->
								<cfset NextRelInvoice = GetNextInvoice()>
							</cfif>

							<cfquery datasource="#application.dopsds#" name="RelinquishThisReg">
								update reg
								set
									relinquishdt = now(),
									regstatus = <cfqueryparam value="D" cfsqltype="CF_SQL_CHAR">,
									relinquishuser = <cfqueryparam value="#huserid#" cfsqltype="CF_SQL_INTEGER">,
									dropreason = <cfqueryparam value="Relinquished. Class had #ThisClassAllocated# registrations." cfsqltype="CF_SQL_VARCHAR">
								where primarypatronid = <cfqueryparam value="#GetLastStandbyRegAllocated.PRIMARYPATRONID#" cfsqltype="CF_SQL_INTEGER">
								and   regid = <cfqueryparam value="#GetLastStandbyRegAllocated.REGID#" cfsqltype="CF_SQL_INTEGER">
								;
								update activity
								set
									relinquished = <cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
								where RegID = <cfqueryparam value="#GetLastStandbyRegAllocated.RegID#" cfsqltype="CF_SQL_INTEGER">
								and   PrimaryPatronID = <cfqueryparam value="#GetLastStandbyRegAllocated.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
								;
								insert into Activity
									(TermID,
									FacID,
									Activity,
									ActivityCode,
									PatronID,
									InvoiceFacID,
									InvoiceNumber,
									Debit,
									Credit,
									line,
									EC,
									primarypatronid,
									regid,
									isstandby,
									relinquished)
								values
									(<cfqueryparam value="#GetClassData.TermID#" cfsqltype="CF_SQL_VARCHAR">,
									<cfqueryparam value="#GetClassData.FacID#" cfsqltype="CF_SQL_VARCHAR">,
									<cfqueryparam value="#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">,
									<cfqueryparam value="CD" cfsqltype="CF_SQL_CHAR">,
									<cfqueryparam value="#PatronID#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
									<cfif GetFeePaid.recordcount gt 0 and GetFeePaid.amount gt 0 or 1 is 1><cfqueryparam value="#NextRelInvoice#" cfsqltype="CF_SQL_INTEGER"><cfelse><cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER"></cfif>,
									<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">,
									<cfif GetFeePaid.recordcount gt 0 and GetFeePaid.amount gt 0 or 1 is 1><cfqueryparam value="#GetFeePaid.amount#" cfsqltype="CF_SQL_MONEY"><cfelse><cfqueryparam value="0" cfsqltype="CF_SQL_MONEY"></cfif>,
									<cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#GetLastStandbyRegAllocated.primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#GetLastStandbyRegAllocated.regid#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
									<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">)
								;
								insert into reghistory
									(PrimaryPatronID,
									RegID,
									invoicefacid,
									invoicenumber,
									amount,
									action,
									finished,
									ec,
									userid)
								values
									(<cfqueryparam value="#GetLastStandbyRegAllocated.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#GetLastStandbyRegAllocated.RegID#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
									<cfif GetFeePaid.recordcount gt 0 and GetFeePaid.amount gt 0 or 1 is 1><cfqueryparam value="#NextRelInvoice#" cfsqltype="CF_SQL_INTEGER"><cfelse><cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER"></cfif>,
									<cfif GetFeePaid.recordcount gt 0 and GetFeePaid.amount gt 0 or 1 is 1><cfqueryparam value="#GetFeePaid.amount#" cfsqltype="CF_SQL_MONEY"><cfelse><cfqueryparam value="0" cfsqltype="CF_SQL_MONEY"></cfif>,
									<cfqueryparam value="D" cfsqltype="CF_SQL_CHAR">,
									<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
									<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#huserid#" cfsqltype="CF_SQL_INTEGER">)
							</cfquery>

							<cfif (GetFeePaid.recordcount gt 0 and GetFeePaid.amount gt 0) or 1 is 1><!--- remove override is want to suppress $0 invoice --->

								<cfquery datasource="#application.dopsds#" name="GetRelAddress">
									SELECT   ADDRESSID, MAILINGADDRESSID, INDISTRICT
									FROM     PATRONRELATIONS
									WHERE    PRIMARYPATRONID = <cfqueryparam value="#GetLastStandbyRegAllocated.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
									AND      RELATIONTYPE = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
								</cfquery>

								<cfquery datasource="#application.dopsds#" name="GetPrimaryPatronLookup">
									select   patronlookup
									from     patrons
									where    patronid = <cfqueryparam value="#GetLastStandbyRegAllocated.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
								</cfquery>

								<cfset thisdrop = GetDistrictStatus(GetLastStandbyRegAllocated.PrimaryPatronID)>

								<cfquery datasource="#application.dopsds#" name="InsertInvoice">
									insert into invoice
										(InvoiceFacID,
										InvoiceNumber,
										PrimaryPatronID,
										AddressID,
										mailingaddressid,
										InDistrict,
										insufficientid,
										startingbalance,
										NewCredit,
										Node,
										userid,
										dt,
										PRIMARYPATRONLOOKUP,
										invoicetype)
									values
										(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#NextRelInvoice#" cfsqltype="CF_SQL_INTEGER">,
										<cfqueryparam value="#GetLastStandbyRegAllocated.PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
										<cfqueryparam value="#GetRelAddress.addressid#" cfsqltype="CF_SQL_INTEGER">,
										<cfif GetRelAddress.mailingaddressid is ""><cfqueryparam value="#GetRelAddress.addressid#" cfsqltype="CF_SQL_INTEGER"><cfelse><cfqueryparam value="#GetRelAddress.mailingaddressid#" cfsqltype="CF_SQL_INTEGER"></cfif>,
										<cfqueryparam value="#tf(thisdrop[1])#" cfsqltype="CF_SQL_BIT">,
										<cfqueryparam value="#tf(thisdrop[2])#" cfsqltype="CF_SQL_BIT">,
										<cfqueryparam value="#GetAccountBalance(GetLastStandbyRegAllocated.PrimaryPatronID)#" cfsqltype="CF_SQL_MONEY">,
										<cfqueryparam value="#GetFeePaid.amount#" cfsqltype="CF_SQL_MONEY">,
										<cfqueryparam value="#LocalNode#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="#huserID#" cfsqltype="CF_SQL_INTEGER">,
										now(),
										<cfqueryparam value="#GetPrimaryPatronLookup.patronlookup#" cfsqltype="CF_SQL_VARCHAR">,
										<cfqueryparam value="-REGDROP-" cfsqltype="CF_SQL_VARCHAR">)
								</cfquery>

								<cfset EWPDropInvoice = LocalFac & "-" & NextRelInvoice>

								<cfif GetFeePaid.amount gt 0>

									<cfquery datasource="#application.dopsds#" name="GetGLDistCredit" cachedwithin="#CreateTimeSpan(0,1,0,0)#">
										select   AcctID
										from     GLMaster
										where    InternalRef = <cfqueryparam value="DC" cfsqltype="CF_SQL_VARCHAR">
									</cfquery>

									<cfquery datasource="#application.dopsds#" name="InsertClassGL2">
										insert into GL
											(Debit,
											AcctID,
											InvoiceFacID,
											InvoiceNumber,
											EntryLine,
											ec,
											activitytype,
											activity)
										values
											(<cfqueryparam value="#GetFeePaid.amount#" cfsqltype="CF_SQL_MONEY">,
											<cfqueryparam value="#GetClassData.GLAcctID#" cfsqltype="CF_SQL_INTEGER">,
											<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
											<cfqueryparam value="#NextRelInvoice#" cfsqltype="CF_SQL_INTEGER">,
											<cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">,
											<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
											<cfqueryparam value="R" cfsqltype="CF_SQL_CHAR">,
											<cfqueryparam value="#GetClassData.TermID#-#GetClassData.FacID#-#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">)
										;
										insert into GL
											(Credit,
											AcctID,
											InvoiceFacID,
											InvoiceNumber,
											EntryLine,
											ec,
											activitytype,
											activity)
										values
											(<cfqueryparam value="#GetFeePaid.amount#" cfsqltype="CF_SQL_MONEY">,
											<cfqueryparam value="#GetGLDistCredit.acctID#" cfsqltype="CF_SQL_INTEGER">,
											<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
											<cfqueryparam value="#NextRelInvoice#" cfsqltype="CF_SQL_INTEGER">,
											<cfqueryparam value="2" cfsqltype="CF_SQL_INTEGER">,
											<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
											<cfqueryparam value="R" cfsqltype="CF_SQL_CHAR">,
											<cfqueryparam value="#GetClassData.TermID#-#GetClassData.FacID#-#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">)
									</cfquery>

								</cfif>

							</cfif>

							<cfquery datasource="#application.dopsds#" name="GetGLErrorRelInvoice">
								select dops.getglerror(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="#NextRelInvoice#" cfsqltype="CF_SQL_INTEGER">) as tmp
							</cfquery>

							<cfif GetGLErrorRelInvoice.tmp is not 0>
								<cftransaction action="ROLLBACK">
								<BR><BR><strong>An error occurred at final check processing this enrollment. Go back and try again.</strong>
								<BR><BR>
								<input type="Button" class="GoButton" onClick="history.back()" value="Go Back" style="width: 200px;">
								<cfabort>
							</cfif>

						</cfif>

						<cfif EWPRelinquishEmail is 1>
							<!--- send email to primary and patron (distinct), if set --->
							<cfquery datasource="#application.dopsds#" name="GetContactData">
								SELECT   CONTACTDATA
								FROM     PATRONCONTACT
								WHERE    CONTACTTYPE = <cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">
								AND      PATRONID in (<cfqueryparam value="#GetLastStandbyRegAllocated.PRIMARYPATRONID#" cfsqltype="CF_SQL_INTEGER">,<cfqueryparam value="#GetLastStandbyRegAllocated.PATRONID#" cfsqltype="CF_SQL_INTEGER">)
								group by CONTACTDATA
							</cfquery>

							<cfif GetContactData.recordcount gt 0>
								<cfset SendTo = ValueList(GetContactData.CONTACTDATA,';')>

								<cfif application.maildebugmode is not "">
									<cfset SendTo = application.maildebugmode>
								</cfif>

<cfif EnableEmail is 1>

								<cfmail to="#SendTo#" from="Registration_Relinquish_Notification" subject="THPRD Class Registration Relinquishment"  spoolenable="Yes" timeout="30">THPRD Registration Relinquishment Notice

We are sorry to inform you that your standby registration for #GetLastStandbyRegAllocated.LastName#, #GetLastStandbyRegAllocated.FirstName#, class #GetClassData.ClassID# at #GetLastStandbyRegAllocated.NAME# MAY have been relinquished.

Class had #ThisClassAllocated# registrations at the time of relinquishment.

Date/Time of action: #dateformat(now(),"mm/dd/yyyy")# #timeformat(now(),"hh:mmtt")#

Invoice: #EWPDropInvoice#
								</cfmail>

</cfif>

							</cfif>

						</cfif>

					</cfif>

				</cfif>
				<!--- end relinquishment process --->

			</cfloop>





			<cfquery datasource="#application.dopsds#" name="GetNextRegID">
				select   dops.getnextregid( #primarypatronid#::integer ) as tmp, dops.getregrate( #primarypatronid#::integer, #PatronID#::integer, '#GetClassData.TermID#'::varchar, '#GetClassData.FacID#'::varchar, '#GetClassData.ClassID#'::varchar, false, true ) as therate
			</cfquery>







			<!--- OK to enroll --->
			<cfif (ThisClassAllocated lt GetClassData.MaxQty) and (ThisClassWLCount is 0)>
				<cfset DoEnrollment = 1>

				<cfif DoEnrollment is 1>

					<cfquery name="AddToReg" datasource="#application.dopsds#">
						insert into reg
							(RegID,
							TermID,
							FacID,
							ClassID,
							PatronID,
							PrimaryPatronID,
							RegStatus,
							DepositOnly,
							Deferred,
							feebalance,
							SessionID,
							costbasis,
							miscbasis,
							indistrict,
							isstandby,
                                   senior,
							mil,
							ratemethod )
						values
							(<cfqueryparam value="#GetNextRegID.tmp#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#GetClassData.TermID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#GetClassData.FacID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#PatronID#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">,
							<cfif IsDefined("UseDepositMode") and AllowDeposit is 1 and listfind(UseDepositMode,GetClassData.ClassID) GT 0>
                                   <cfqueryparam value="true" cfsqltype="CF_SQL_BIT"><cfelse><cfqueryparam value="false" cfsqltype="CF_SQL_BIT"></cfif>,
							<cfif IsDefined("UseDeferredMode")><cfqueryparam value="true" cfsqltype="CF_SQL_BIT"><cfelse><cfqueryparam value="false" cfsqltype="CF_SQL_BIT"></cfif>,
							<cfif IsDefined("UseDepositMode") and AllowDeposit is 1><cfqueryparam value="#ClassCost+GetClassData.MiscFee-DepositRequired#" cfsqltype="CF_SQL_MONEY"><cfelse><cfqueryparam value="0" cfsqltype="CF_SQL_MONEY"></cfif>,

							 <cfqueryparam value="#CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">,
							<!---
							(
							select   sessionid
							from     sessionpatrons
							where    patronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
							and      relationtype = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
							limit    1
							),--->

							<cfqueryparam value="#ClassCost#" cfsqltype="CF_SQL_MONEY">,
							<cfqueryparam value="#GetClassData.MiscFee#" cfsqltype="CF_SQL_MONEY">,
							<cfif PrimaryPatronInDistrict is 1>true<cfelse>false</cfif>,
							<cfif IsDefined("UseEWPName")><cfqueryparam value="true" cfsqltype="CF_SQL_BIT"><cfelse><cfqueryparam value="false" cfsqltype="CF_SQL_BIT"></cfif>,
                                   (dops.usescrate( <cfqueryparam value="#patronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#GetClassData.startdt#" cfsqltype="cf_sql_date" list="no">, <cfqueryparam value="#GetClassData.termid#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="#GetClassData.facid#" cfsqltype="cf_sql_varchar" list="no"> ) ),
							(dops.usemilrate( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#patronid#" cfsqltype="cf_sql_integer" list="no"> ) ),
							(dops.getregrate( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#PatronID#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#GetClassData.TermID#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="#GetClassData.FacID#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="#GetClassData.ClassID#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">, <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no"> ))
                                   )
							;
					<cfset NextEC = GetNextEC()>

					<cfif IsDefined("UseDepositMode") and AllowDeposit is 1>
							insert into reghistory
							(amount,
							action,
							primarypatronid,
							EC,
							RegID,
							balance,
							depositonly,
							pending,
							userid)
						values
							(<cfqueryparam value="#DepositRequired#" cfsqltype="CF_SQL_MONEY">,
							<cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">,
							<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#nextec#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#GetNextRegID.tmp#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#ClassCost+GetClassData.MiscFee-DepositRequired#" cfsqltype="CF_SQL_MONEY">,
							<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
							<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
							<cfqueryparam value="#huserid#" cfsqltype="CF_SQL_INTEGER">)
							;
					<cfelse>

						insert into reghistory
							(amount,
							action,
							primarypatronid,
							EC,
							RegID,
							deferred,
							balance,
							pending,
							userid)
						values
							(<cfif IsDefined("UseEWPName")>
								<cfif GetClassData.truecost is "">
									<cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
								<cfelse>
									<cfqueryparam value="#GetClassData.truecost#" cfsqltype="CF_SQL_MONEY">
								</cfif>
							<cfelse>
								<cfqueryparam value="#ClassCost#" cfsqltype="CF_SQL_MONEY">
							</cfif>,
							<cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">,
							<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#nextec#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#GetNextRegID.tmp#" cfsqltype="CF_SQL_INTEGER">,
							<cfif IsDefined("WasDeferredName")><cfqueryparam value="true" cfsqltype="CF_SQL_BIT"><cfelse><cfqueryparam value="false" cfsqltype="CF_SQL_BIT"></cfif>,
							<cfqueryparam value="#ClassCost+GetClassData.MiscFee#" cfsqltype="CF_SQL_MONEY">,
							<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">,
							<cfqueryparam value="#huserid#" cfsqltype="CF_SQL_INTEGER">)
						;

						<cfif not IsDefined("UseEWPName")>

							<cfif GetClassData.MiscFee gt 0>
								<cfset NextEC = GetNextEC()>

								insert into reghistory
									(amount,
									action,
									primarypatronid,
									EC,
									RegID,
									IsMiscFee,
									pending,
									userid)
								values
									(<cfif IsDefined("UseEWPName")>
										<cfif GetClassData.truecost is "">
											<cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
										<cfelse>
											<cfqueryparam value="#GetClassData.truecost#" cfsqltype="CF_SQL_MONEY">
										</cfif>
									<cfelse>
										<cfqueryparam value="#GetClassData.MiscFee#" cfsqltype="CF_SQL_MONEY">
									</cfif>,
									<cfqueryparam value="E" cfsqltype="CF_SQL_CHAR">,
									<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#nextec#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="#GetNextRegID.tmp#" cfsqltype="CF_SQL_INTEGER">,
									<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
									<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">,
									<cfqueryparam value="#huserid#" cfsqltype="CF_SQL_INTEGER">)
								;
							</cfif>

						</cfif>

					</cfif>

						select dops.insertregproc(<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="#GetNextRegID.tmp#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="W1" cfsqltype="CF_SQL_VARCHAR">) as regok
					</cfquery>



					<!--- verify registration did not overfill --->
					<cfif not AddToReg.regok>
						<td>
                              <br><br><strong>An attempted insertion of the class <cfoutput>#GetClassData.ClassID#</cfoutput>
						failed due to the net registration count being larger than the max qty of said class.</strong>
						<br><br><strong>Go back and try again.</strong>
						<br><br>
						<< <a href="javascript:history.back();">Go back</a>

                              <br />

	</td>
  </tr>
 <tr>
   <td colspan="2" valign="top">&nbsp;</td>
  </tr>
  <cfinclude template="/portalINC/footer.cfm">
</table>
</body>
</html>


                              <cfabort>

					</cfif>
					<!--- end verify registration did not overfill --->



				</cfif>





			<cfelseif AllowWL is 1>
				<cfset ThisClassWLCount = ThisClassWLCount + 1>
				<cfset ThisStatus = "W">

				<!--- enrollment (wait list) --->
				<cfquery name="AddToRegWL" datasource="#application.dopsds#">
					insert into reg
						(RegID,
						TermID,
						FacID,
						ClassID,
						PatronID,
						waswl,
						PrimaryPatronID,
						RegStatus,
						Deferred,
						DeferredPaid,
						DepositOnly,
						SessionID,
						indistrict,
                              senior,
                              mil,
                              ratemethod)
					values
						(<cfqueryparam value="#GetNextRegID.tmp#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#GetClassData.TermID#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#GetClassData.FacID#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#GetClassData.ClassID#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#PatronID#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
						<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#ThisStatus#" cfsqltype="CF_SQL_CHAR">,
						<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">,
						<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">,
						<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">,

						<cfqueryparam value="#CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">,
							<!---
							(
							select   sessionid
							from     sessionpatrons
							where    patronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
							and      relationtype = <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
							limit    1
							),--->
						<cfif PrimaryPatronInDistrict is 1><cfqueryparam value="true" cfsqltype="CF_SQL_BIT"><cfelse><cfqueryparam value="false" cfsqltype="CF_SQL_BIT"></cfif>,
                              (dops.usescrate( <cfqueryparam value="#patronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#GetClassData.startdt#" cfsqltype="cf_sql_date" list="no">, <cfqueryparam value="#GetClassData.termid#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="#GetClassData.facid#" cfsqltype="cf_sql_varchar" list="no"> ) ),
						(dops.usemilrate( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#patronid#" cfsqltype="cf_sql_integer" list="no"> ) ),
						(dops.getregrate( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#PatronID#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#GetClassData.TermID#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="#GetClassData.FacID#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="#GetClassData.ClassID#" cfsqltype="cf_sql_varchar" list="no">, <cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">, <cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no"> ))
                              )
					;
					insert into reghistory
						(action,
						primarypatronid,
						RegID,
						EC,
						pending,
						userid)
					values
						(<cfqueryparam value="W" cfsqltype="CF_SQL_CHAR">,
						<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#GetNextRegID.tmp#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#GetNextEC()#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,
						<cfqueryparam value="#huserid#" cfsqltype="CF_SQL_INTEGER">)
					;
					select dops.insertregproc(<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="#GetNextRegID.tmp#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="W1" cfsqltype="CF_SQL_VARCHAR">)
				</cfquery>

			</cfif>

		</cfif>
<!---
				<CFQUERY name="checkSession" datasource="#application.dopsds#">
					select sessionID from reg
					where regID = #GetClassData.NextRegID#
					and primarypatronID = #PrimaryPatronID#
					and sessionID IS NOT NULL
				</CFQUERY>
				<CFIF checkSession.recordcount EQ 0>
				<td valign="top">
				<table>
				<tr>
				<td><br><br><br>
				Error adding item to cart. <a href=""><< <a href="javascript:history.back();">Go back</a><br />
				<br>
				If the error persists, <a href="mailto:webadmin@thprd.org"><font color="red"><strong>please contact IT</strong></font></a> as soon as possible.<br />
				Please include your THPRD ID, Browser, computer operating system and the class ID.<br>Thank you for your assistance.<br />
				<CFMAIL to="webadmin@thprd.org" from="webadmin@thprd.org" subject="Shopping Cart Error" type="html">
				Error adding item to cart. Session ID not found. #cgi.server_addr#

				<CFDUMP var="#form#">

				<CFDUMP var="#cookie#">


				</CFMAIL>
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
</html>
				<CFABORT>
				</CFIF>
				--->

		</cftransaction>

		<!--- <CFQUERY name="createunlock" datasource="#application.dopsdsro#">
			SELECT  pg_advisory_unlock(uniqueid)
			FROM    dops.classes
			where   uniqueid = <cfqueryparam value="#enrollmentpairs[q][1]#" cfsqltype="CF_SQL_INTEGER">
		</CFQUERY> --->

	</cfif>

</cfloop>

</cfif>

<!--- dis[play enrollment processing time --->
<cfif 0>
	<cfoutput>procreg tc: #gettickcount() - tc#</cfoutput>
</cfif>

<cfif 0>
	<cfabort>
</cfif>

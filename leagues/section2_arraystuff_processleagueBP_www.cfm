<!--- form validation --->
<cfset GLCode = 7>
<!--- load account balance --->
<cfquery datasource="#application.dopsdsro#" name="GetStartingBalance">
	select dops.primaryaccountbalance(<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp) as b
</cfquery>

<cfset StartCredit = GetStartingBalance.b>
<!---
<cfset ccExp = ccExpMonth & ccExpYear>
<cfset ccNum = ccNum1 & ccNum2 & ccNum3 & ccNum4>
--->

<cfif dollarround( form.totalfees - form.creditused - form.othercreditused ) neq dollarround( form.adjustednetdue )>
	<CFSAVECONTENT variable="message">
	Specified monies do not calculate as expected. Go back and try again.<br>

	<cfif 1>
		<BR>
		<cfoutput>
			#dollarround(totalfees - creditused - othercreditused)# vs. #dollarround(adjustednetdue)#<BR>
			totalfees = #dollarround(totalfees)#<BR>
			othercreditused = #dollarround(othercreditused)#<BR>
			adjustednetdue = #dollarround(adjustednetdue)#
		</cfoutput>
		<BR>
	</cfif>

	<!---<cfoutput>Netdue: #netdue# | Other Credit Used: #othercreditused# | Adjusted Net Due: #adjustednetdue#</cfoutput>--->
	</CFSAVECONTENT>
	<CFSET nobackbutton = false>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</cfif>

<!---
<cfif AdjustedNetDue gt 0 and (ccExp is "" or ccNum is "" or ccv is "")>
	<strong>No credit card information was found. Go back and try again.</strong>
	<BR><BR>
	<a href="javascript:history.go(-1);"><strong><< Go back and try again.</strong></a>

	<cfabort>
</cfif>
--->

<cfif AvailableCredit is not StartCredit>
	<CFSAVECONTENT variable="message">
	Starting Credit did not match true account balance. Go back and try again.<br>
	</CFSAVECONTENT>
	<CFSET nobackbutton = false>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>
</cfif>

<cfset alreadyenrolled = 0>
<cfloop from="1" to="#ArrayLen(FinalArray)#" step="1" index="x">
		<cfset QtyChkArray[x][1] = FinalArray[x][11]>

		<cfif FinalArray[x][10] gt 0 and FinalArray[x][5] is not "" and FinalArray[x][7] is not "">

			<!--- insert enrollment data --->
			<cfquery datasource="#application.dopsds#" name="CheckForEnrollments">
				SELECT   th_league_enrollments.pk, patrons.firstname,
				         th_leaguetype.description,
				         invoice.dt
				FROM     content.th_league_enrollments th_league_enrollments
				         INNER JOIN invoice invoice ON th_league_enrollments.invoicefacid=invoice.invoicefacid AND th_league_enrollments.invoicenumber=invoice.invoicenumber
				         INNER JOIN patrons patrons ON th_league_enrollments.patronid=patrons.patronid
				         INNER JOIN content.th_leaguetype th_leaguetype ON th_league_enrollments.leaguetype=th_leaguetype.typecode
				WHERE    th_league_enrollments.patronid = <cfqueryparam value="#FinalArray[x][1]#" cfsqltype="CF_SQL_INTEGER">
				AND      th_league_enrollments.leaguetype = <cfqueryparam value="#FinalArray[x][11]#" cfsqltype="CF_SQL_INTEGER">
				AND      th_league_enrollments.elementary = <cfqueryparam value="#FinalArray[x][8]#" cfsqltype="CF_SQL_INTEGER">
				AND      th_league_enrollments.middle = <cfqueryparam value="#FinalArray[x][9]#" cfsqltype="CF_SQL_INTEGER">
				AND      th_league_enrollments.high = <cfqueryparam value="#FinalArray[x][10]#" cfsqltype="CF_SQL_INTEGER">
				AND      valid
				AND      not invoice.isvoided
				limit    1
			</cfquery>

			<cfif CheckForEnrollments.recordcount is 1>
				<cfset alreadyenrolled = 1>
				<cfset FinalArray[x][1] = 0>
				<cfset FinalArray[x][2] = CheckForEnrollments.firstname>
				<cfset FinalArray[x][3] = CheckForEnrollments.description>
				<cfset FinalArray[x][4] = CheckForEnrollments.dt>
			</cfif>

		</cfif>

	</cfloop>

	<cfif 0>
		<cfdump var="#FinalArray#" label="section2">
	</cfif>

	<cfif alreadyenrolled is 1>
     <CFSAVECONTENT variable="message">
		One or more attempted enrollments were already found. This may be due to the invoice already being processed, possibly caused by the refreshing your browser.

		<BR><BR>
		<strong>Offending enrollments:</strong><br>
		<br>

		<cfloop from="1" to="#ArrayLen(FinalArray)#" step="1" index="x">

			<cfif FinalArray[x][1] is 0><CFOUTPUT>
				#FinalArray[x][2]# for #FinalArray[x][7]# (enrolled #dateformat(FinalArray[x][4],"mm/dd/yyyy")# #lcase(timeformat(FinalArray[x][4], "hh:mmtt"))#)<BR></CFOUTPUT>
			</cfif>

		</cfloop>
	</CFSAVECONTENT>
	<CFSET nobackbutton = false>
	<CFINCLUDE template = "includes/layout.cfm">
	<cfabort>

	</cfif>
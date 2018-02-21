<cfoutput>

<cfif form.creditused gt 0>

	<cfquery datasource="#application.dopsds#" name="GetDCAcctid">
		SELECT   acctid
		FROM     dops.glmaster
		WHERE    internalref = <cfqueryparam value="DC" cfsqltype="cf_sql_varchar" list="no">
	</cfquery>

	<cfif GetDCAcctid.recordcount eq 0>
		<cfsavecontent variable="message">
				Could not find district credit data.
				<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</cfsavecontent>	
          <cfinclude template="includes/layout.cfm">
		<cfabort>
	</cfif>

</cfif>

<cfquery datasource="#application.dopsds#" name="GetBasketPasses">
	SELECT   *,
	         0 as acctid
	FROM     dops.sessionpasses
	         INNER JOIN dops.passtype ON sessionpasses.passtype=passtype.passtype
	WHERE    sessionpasses.sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
	and      sessionpasses.isnewpass
	order by sessionpasses.ec
</cfquery>

<cfif GetBasketPasses.recordcount eq 0>
		<cfsavecontent variable="message">
				No passes found in basket
				<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</cfsavecontent>	
          <cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>

<!--- set GLs --->
<cfloop query="GetBasketPasses">
	<!--- get GL --->
	<cfquery datasource="#application.dopsds#" name="GetPassGL">
		select   acctid
		from     dops.passtypegl
		where    facid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
		and      passtype = <cfqueryparam value="#GetBasketPasses.PassType#" cfsqltype="CF_SQL_VARCHAR">
		and      acctid is not null
	</cfquery>

	<cfif GetPassGL.RecordCount neq 1>
		<cfset errormsg = "Error in fetching data for pass.">
	<cfelse>
		<cfset QuerySetCell( GetBasketPasses, "acctid", GetPassGL.acctid, GetBasketPasses.currentrow )>
	</cfif>

</cfloop>

<cfif IsDefined("variables.errormsg")>
		<cfsavecontent variable="message">
				#variables.errormsg#
				<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</cfsavecontent>	
          <cfinclude template="includes/layout.cfm">
	<cfabort>
</cfif>
<!--- end set GLs --->
<cfif 0>
	<cfdump var="#GetBasketPasses#">
</cfif>


<!--- get oc card data --->
<cfif form.tenderedoc gt 0>
	<cfif form.OCCardNumber eq "">
		<cfset errormsg = "Gift Card funds were specified but no card was found.">
	<cfelse>
		<cfset ocNum = REReplace( form.OCCardNumber, "[^0-9]", "", "all" )>
		<cf_cryp type="en" string="#variables.ocNum#" key="#variables.key#">

		<cfif cryp.value eq "">
			<cfset errormsg = "Gift card number did not properly decode.">
		<cfelse>
			<cfset enOtherCreditData = cryp.value>

			<!--- lookup card by id - improves speed --->
			<cfquery datasource="#application.dopsds#" name="getCardData">
				SELECT   cardid,
				         activated,
				         valid,
				         primarypatronid,
				         holdforreview,
				         isfa,
				         faappid,
				         acctid
				FROM     dops.othercredithistorysums
				where    othercreditdata = <cfqueryparam value="#variables.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>

			<cfif getCardData.recordcount eq 0>
				<cfset errormsg = "Gift Card funds were specified but no card was found.">
			<cfelse>

				<cfif getCardData.holdforreview or not getCardData.valid>
					<cfset errormsg = "Gift card was found but is not valid.">
				</cfif>

			</cfif>

		</cfif>

	</cfif>

</cfif>
<!--- end get oc card data --->

<cfif IsDefined("variables.errormsg")>
	<TR>
		<TD colspan="99">
			#variables.errormsg#
			<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</td>
	</tr>
	<cfabort>
</cfif>



<!--- create invoice then update as needed --->
<cfset nextinvoice = GetNextInvoice()>
<cfset GLLineNo = 0>

<!---init is code --->
<cfif form.adjustednetdue gt 0>
	<cfinclude template="FunctionTranx2.cfc">

	<cfset thistranxpk = invoicetranxprecheck(
		gethousehold.primarypatronid[1],
		form.sid,
		form.adjustednetdue,
		form.ccfirstname,
		form.cclastname,
		"",
		"")>

	<!--- convert back to integer response --->
	<cfset origthistranxpk = variables.thistranxpk>
	<cfset thistranxpk = val( variables.thistranxpk )>

	<cfif variables.thistranxpk eq 0>
		<TR>
			<TD colspan="99">
				Error in determining transaction initialization code.<BR><BR>#variables.origthistranxpk#<BR><BR>Go back and try again or contact THPRD for assistance.
				<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
			</td>
		</tr>
		<cfabort>
	</cfif>

</cfif>








<cftransaction action="begin" isolation="repeatable_read">

<cfquery datasource="#application.dopsds#" name="InsertInvoice">
	insert into dops.invoice
		( invoicefacid,
		invoicenumber,
		node,
		totalfees,
		othercreditused,
		othercreditusedcardid,
		faappid,
		tenderedcc,
		usedcredit,
		firstname,
		lastname,
		userid,
		primarypatronid,
		addressid,
		mailingaddressid,
		indistrict,
		insufficientid,
		startingbalance,
		invoicetype )
	values
		( <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">, -- InvoiceFacID
		<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- InvoiceNumber
		<cfqueryparam value="W1" cfsqltype="CF_SQL_VARCHAR">, -- LocalNode
		<cfqueryparam value="#form.totalfees#" cfsqltype="CF_SQL_MONEY">, -- TotalFees
		<cfqueryparam value="#form.tenderedoc#" cfsqltype="CF_SQL_MONEY">, -- tendered oc

		<cfif form.tenderedoc gt 0>
			<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">, -- oc card id
		<cfelse>
			null, -- oc card not used
		</cfif>

		<cfif form.tenderedoc gt 0 and GetCardData.faappid neq "">
			<cfqueryparam value="#GetCardData.faappid#" cfsqltype="CF_SQL_INTEGER">, -- fa app id
		<cfelse>
			null, -- fa not used
		</cfif>

		<cfqueryparam value="#form.AdjustedNetDue#" cfsqltype="CF_SQL_MONEY">, --Tendered CC
		<cfqueryparam value="#form.creditused#" cfsqltype="CF_SQL_MONEY">, ( -- creditused

		select   firstname
		from     dops.patrons
		where    patronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), ( -- primary first name

		select   lastname
		from     dops.patrons
		where    patronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), -- primary last name

		<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">, --huserID
		<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">, (

		select   addressid
		from     dops.patronrelations
		where    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		and      secondarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), (

		select   mailingaddressid
		from     dops.patronrelations
		where    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		and      secondarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), (

		SELECT   indistrict
		FROM     dops.patronrelations
		WHERE    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		AND      secondarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), (

		SELECT   patrons.insufficientid
		FROM     dops.patronrelations patronrelations
		         INNER JOIN dops.patrons patrons ON patronrelations.secondarypatronid=patrons.patronid
		WHERE    patronrelations.primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		AND      patronrelations.secondarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ), (

		select   dops.primaryaccountbalance(<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)),
		<cfqueryparam value="-PASS-" cfsqltype="CF_SQL_VARCHAR"> ) -- PASS invoice type

		<!--- update card holder name if supplied --->
		<cfif IsDefined("form.ccFirstName") and IsDefined("form.ccLastName") and trim( form.ccLastName ) & trim( form.ccFirstName ) neq "">
			;
			update   dops.invoice
			set
				firstname =

				<cfif trim( form.ccFirstName ) eq "">
					null,
				<cfelse>
					<cfqueryparam value="#trim( form.ccFirstName )#" cfsqltype="CF_SQL_VARCHAR">,
				</cfif>

				lastname =

				<cfif trim( form.ccLastname ) eq "">
					null
				<cfelse>
					<cfqueryparam value="#trim( form.ccLastname )#" cfsqltype="CF_SQL_VARCHAR">
				</cfif>

			where   invoicefacid = <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">
			and     invoicenumber = <cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">
		</cfif>

		<!--- intert DC GL usage  --->
		<cfif form.creditused gt 0>
			<cfset GLLineNo = variables.GLLineNo + 1>
			;

			insert into dops.gl
				( invoicefacid,
				invoicenumber,
				entryline,
				ec,
				acctid,
				debit,
				activitytype,
				activity )
			values
				( <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">, -- LocalFac
				<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- NextInvoice
				<cfqueryparam value="#variables.GLLineNo#" cfsqltype="CF_SQL_INTEGER">, -- GLLineNo
				<cfqueryparam value="#GetNextEC()#" cfsqltype="CF_SQL_INTEGER">, -- EC
				<cfqueryparam value="#GetDCAcctid.acctid#" cfsqltype="CF_SQL_INTEGER">, -- acctid
				<cfqueryparam value="#form.creditused#" cfsqltype="CF_SQL_MONEY">, -- DC used
				<cfqueryparam value="DC" cfsqltype="CF_SQL_VARCHAR">, -- activity type
				<cfqueryparam value="Pass" cfsqltype="CF_SQL_VARCHAR">) -- usage desc
		</cfif>

</cfquery>






<cfset totalpassfee = 0>
<cfset runningtx = form.adjustednetdue>

<!--- insert passes --->
<cfloop query="GetBasketPasses">
	<cfset totalpassfee = variables.totalpassfee + GetBasketPasses.PassFee>

	<cfif variables.runningtx gt 0>
		<cfset nextprc = GetNextPRC()>
	</cfif>

	<cfquery datasource="#application.dopsds#" name="InsertPass">
		-- create new pass
		insert into dops.passes
			( ec,
			primarypatronid,
			invoicefacid,
			invoicenumber,
			passfee,
			passtype,
			passterm,
			passexpires,
			passallocation,
			passspan,
			passuses,
			assmtwasused

			<cfif variables.runningtx gt 0>
				, prc
			</cfif> )
		values
			( <cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="CF_SQL_INTEGER">,
			<cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
			<cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">,
			<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
			<cfqueryparam value="#GetBasketPasses.PassFee#" cfsqltype="CF_SQL_MONEY">,
			<cfqueryparam value="#GetBasketPasses.PassType#" cfsqltype="CF_SQL_VARCHAR">,
			<cfqueryparam value="#GetBasketPasses.PassTerm#" cfsqltype="CF_SQL_INTEGER">,
			<cfqueryparam value="#CreateODBCDate( GetBasketPasses.PassExpires )#" cfsqltype="CF_SQL_DATE">,
			<cfqueryparam value="#GetBasketPasses.PassAllocation#" cfsqltype="CF_SQL_INTEGER">,
			<cfqueryparam value="#GetBasketPasses.PassSpan#" cfsqltype="CF_SQL_VARCHAR">,
			<cfqueryparam value="#val( GetBasketPasses.PassUses )#" cfsqltype="CF_SQL_INTEGER">,
			<cfqueryparam value="#GetBasketPasses.assmtwasused#" cfsqltype="cf_sql_bit" list="no">

			<cfif variables.runningtx gt 0>
				, <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">
			</cfif> )
	</cfquery>

	<!--- insert GL --->
	<cfset GLLineNo = variables.GLLineNo + 1>

	<cfquery datasource="#application.dopsds#" name="InsertGL">
		insert into dops.gl
			( invoicefacid,
			invoicenumber,
			entryline,
			ec,
			acctid,
			credit,
			activitytype,
			activity )
		values
			( <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">, -- LocalFac
			<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- NextInvoice
			<cfqueryparam value="#variables.GLLineNo#" cfsqltype="CF_SQL_INTEGER">, -- GLLineNo
			<cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="CF_SQL_INTEGER">, -- EC
			<cfqueryparam value="#GetBasketPasses.acctid#" cfsqltype="CF_SQL_INTEGER">, -- acctid
			<cfqueryparam value="#GetBasketPasses.passfee#" cfsqltype="CF_SQL_MONEY">, -- Totalfees
			<cfqueryparam value="Pass" cfsqltype="CF_SQL_VARCHAR">, -- pass
			<cfqueryparam value="Pass Purchase" cfsqltype="CF_SQL_VARCHAR">) -- Pass purchase
	</cfquery>

	<!--- insert pass members --->
	<cfquery datasource="#application.dopsds#" name="GetBasketPassMembers">
		SELECT   patronid,
		         ocdist
		FROM     dops.sessionpassmembers
		WHERE    ec = <cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="cf_sql_integer" list="no">
		ORDER BY pk
	</cfquery>

	<cfquery datasource="#application.dopsds#" name="InsertThisMember">
		insert into dops.passmembers
			( primarypatronid,
			patronid,
			ec,
			dtadded )
		values

		<!--- loop over members --->
		<cfloop query="GetBasketPassMembers">
			( <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
			<cfqueryparam value="#GetBasketPassMembers.patronid#" cfsqltype="CF_SQL_INTEGER">,
			<cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="CF_SQL_INTEGER">,
			now() )

			<cfif GetBasketPassMembers.currentrow lt GetBasketPassMembers.recordcount>
				,
			</cfif>

		</cfloop>
		<!--- end loop over members --->

	</cfquery>
	<!--- end insert pass members --->

	<!--- insert oc dist --->
	<cfquery dbtype="query" name="GetBasketPassMembersOC">
		select   *
		from     GetBasketPassMembers
		where    ocdist > 0
	</cfquery>

	<cfif GetBasketPassMembersOC.recordcount gt 0>
		<cfset totalocdist = 0>

		<cfquery datasource="#application.dopsds#" name="InsertThisMemberOC">
			insert into dops.othercreditdist
				( invoicefacid,
				invoicenumber,
				cardid,
				patronid,
				activity,
				action,
				credit,
				passec )
			values

			<!--- loop over OC members --->
			<cfloop query="GetBasketPassMembersOC">
				( <cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#form.occardid#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#GetBasketPassMembersOC.patronid#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#GetBasketPasses.passtype#" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="PASS" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="#GetBasketPassMembersOC.ocdist#" cfsqltype="cf_sql_money" list="no">,
				<cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="cf_sql_integer" list="no"> )

				<cfif GetBasketPassMembersOC.currentrow lt GetBasketPassMembersOC.recordcount>
					,
				</cfif>

				<cfset totalocdist = variables.totalocdist + GetBasketPassMembersOC.ocdist>
			</cfloop>
			<!--- end loop over OC members --->
			;

			insert into dops.othercreditdatahistory
				( action,
				invoicefacid,
				invoicenumber,
				debit,
				userid,
				module,
				ec,
				cardid )
			values
				( <cfqueryparam value="U" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#variables.totalocdist#" cfsqltype="cf_sql_money" list="no">,
				<cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="DO" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#form.occardid#" cfsqltype="cf_sql_integer" list="no"> )
			;

			<cfset GLLineNo = variables.GLLineNo + 1>
			insert into dops.gl
				( invoicefacid,
				invoicenumber,
				entryline,
				ec,
				acctid,
				debit,
				activitytype,
				activity )
			values
				( <cfqueryparam value="WWW" cfsqltype="CF_SQL_VARCHAR">, -- LocalFac
				<cfqueryparam value="#variables.NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- NextInvoice
				<cfqueryparam value="#variables.GLLineNo#" cfsqltype="CF_SQL_INTEGER">, -- GLLineNo
				<cfqueryparam value="#GetNextEC()#" cfsqltype="CF_SQL_INTEGER">, -- EC
				<cfqueryparam value="#getCardData.acctid#" cfsqltype="CF_SQL_INTEGER">, -- acctid
				<cfqueryparam value="#variables.totalocdist#" cfsqltype="CF_SQL_MONEY">, -- Totalfees
				<cfqueryparam value="Pass" cfsqltype="CF_SQL_VARCHAR">, -- pass
				<cfqueryparam value="Pass Purchase" cfsqltype="CF_SQL_VARCHAR">) -- Pass purchase
		</cfquery>

	</cfif>

	<!--- end insert oc dist --->

	<!--- insert non-active patrons as invalid for family pass ONLY --->
	<cfif GetBasketPasses.passspan eq "F">
		<!--- loop over household --->
		<cfloop query="GetHousehold">

			<cfquery datasource="#application.dopsds#" name="CheckThisMember">
				select   pk
				from     dops.passmembers
				where    ec = <cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="cf_sql_integer" list="no">
				and      patronid = <cfqueryparam value="#GetHousehold.patronid#" cfsqltype="cf_sql_integer" list="no">
				limit    1
			</cfquery>

			<!--- insert if not already in pass members as invalid member --->
			<cfif CheckThisMember.recordcount eq 0>

				<cfquery datasource="#application.dopsds#" name="InsertThisInvalidMember">
					insert into dops.passmembers
						( primarypatronid,
						patronid,
						ec,
						valid,
						dtadded )
					values
						( <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#GetHousehold.patronid#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="false" cfsqltype="cf_sql_bit" list="no">,
						now() )
				</cfquery>

			</cfif>
			<!--- end insert if not already in pass members as invalid member --->

		</cfloop>
		<!--- end loop over household --->

	</cfif>
	<!--- end insert non-active patrons for family pass ONLY --->

	<!--- debug pass members --->
	<cfif 0>

		<cfquery datasource="#application.dopsds#" name="GetMembers">
			select   *
			from     dops.passmembers
			where    ec = <cfqueryparam value="#GetBasketPasses.ec#" cfsqltype="cf_sql_integer" list="no">
		</cfquery>

		<cfdump var="#GetMembers#" label="Pass Members">
	</cfif>
	<!--- end debug pass members --->

	<cfif variables.runningtx gt 0 and GetBasketPasses.passfee gt 0>
		<cfset ThisTranxAmount = min( variables.runningtx, GetBasketPasses.passfee )>

		<cfquery name="InsertIntoTranxHist" datasource="#application.dopsds#">
			update dops.passes
			set
				prc = <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">
			where  pk = <cfqueryparam value="#GetBasketPasses.pk#" cfsqltype="cf_sql_integer" list="no">
			;

			insert into dops.invoicetranxtrans
				( prc,
				pass )
			values
				( <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no"> )
			;

			insert into dops.invoicetranxdist
				( primarypatronid,
				reftype,
				invoicefacid,
				invoicenumber,
				prc,
				amount,
				action )
			values
				(<cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="PASS" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
				<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
				<cfqueryparam value="#variables.ThisTranxAmount#" cfsqltype="cf_sql_money" list="no">,
				<cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">)
		</cfquery>

		<cfset variables.runningtx = variables.runningtx - variables.ThisTranxAmount>
	</cfif>

</cfloop>





<!--- final checks --->
<cfinclude template="finalchecks.cfm">

<cfif IsDefined("variables.errormsg")>
	<TR>
		<TD colspan="99">
			#variables.errormsg#
			<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
			<cfinclude template="displayallinvoicetables.cfm">
		</td>
	</tr>
	<cfabort>
</cfif>
<!--- end final checks --->


<!--- debug final condition --->
<cfif IsDefined("form.selecttestmode") and form.selecttestmode eq "CODE">
	<BR><BR><BR>
	<cfinclude template="displayallinvoicetables.cfm">
	<cfabort>
</cfif>




<cfif hasopencall( GetSession.sessionid )>
	<TR>
		<TD colspan="99">
			ALERT: Processor response is still pending. Cart contents cannot be modified at this time. We have attempted to process your transaction and we are still waiting to hear back from the processor. Please go back, wait 2 minutes and try again.
			<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</td>
	</tr>
	<cfabort>
</cfif>




<cfset customer = StructNew()>
<cfset customer.name = form.ccFirstName & " " & form.ccLastName>
<cfset customer.address = "">
<cfset customer.city = "">
<cfset customer.state = "">
<cfset customer.zip = "">
<cfset customer.phone = "">

<cfif 1><!--- set to 0 in production --->
	<cfset ccsalemode = form.selecttestmode>
<cfelse>
	<cfset ccsalemode = "REAL">
</cfif>

<cfset result = ccsale_v2( variables.ccsalemode, variables.thistranxpk, sid, 'W1', 'WWW', variables.NextInvoice, form.ccNum, form.ccv, form.ccexpmon, form.ccexpyear, customer )>

<cfif 0>
	<cfdump var="#variables.result#">
	<cfinclude template="/securedops/displayallinvoicetables.cfm">
	<cfabort>
</cfif>

<cfif result.approvalcode neq "A">
	<cftransaction action="ROLLBACK" />
<cfelse>
	<!--- remove session pass data --->
	<cfquery datasource="#application.dopsds#" name="ClearSession">
		-- delete members
		delete   from dops.sessionpassmembers
		where    ec in (

		select   sessionpasses.ec
		from     dops.sessionpasses
		where    sessionpasses.sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no"> )
		;

		-- delete passes
		delete   from dops.sessionpasses
		where    sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
		;
	</cfquery>

	<!--- block current session --->
	<cfquery datasource="#application.dopsds#" name="ClearSession">
		-- create session blocking record
		insert into dops.sessionlock
			( sessionid,
			node,
			userid )
		values
			( <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="W1" cfsqltype="cf_sql_varchar" list="no">,
			<cfqueryparam value="0" cfsqltype="cf_sql_integer" list="no"> )
	</cfquery>

	<!--- VERY IMPORTANT! update sessionid so they can do another transaction --->
	<cfset newsessionid = uCase(removeChars(application.IDmaker.randomUUID().toString(), 24, 1))>

	<CFQUERY name="newsession" datasource="#application.dopsds#">
		insert into dops.sessions
			( sessionid )
		VALUES
			( <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> )
		;

		update sessionpatrons         set sessionid = <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> where sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">;
		update sessionpatronsorigdata set sessionid = <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> where sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">;
		update sessionquerylisting    set sessionid = <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> where sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">;
		update sessionquerywords      set sessionid = <cfqueryparam value="#variables.newsessionid#" cfsqltype="cf_sql_varchar" list="no"> where sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">;
	</CFQUERY>

</cfif>

</cftransaction>





<!--- evaluate results from processor call --->
<cfif IsDefined("variables.result") and result.approvalcode neq "A">
	<cfset CloseTranxCall( variables.result )>
	<TR>
		<TD colspan="99">
			Credit card charge attempt failed.
			Processor returned a response of "#variables.result.verbiage#".
			Go back and try again.
			A different credit card may be required.
			<A href="javascript:;" onClick=history.go(-1)>Go back and try again</a>
		</td>
	</tr>
	<cfabort>
</cfif>


<TR>
	<TD colspan="99">
		Processing is complete. <a href="/checkout/invoice/printinvoice.cfm?invoicelist=WWW-#variables.nextinvoice#" target="_blank">View Invoice</a><br><br>
	</td>
</tr>


</cfoutput>
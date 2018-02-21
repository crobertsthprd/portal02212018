


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

		select   dops.primaryaccountbalance( <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER"> ) ),
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
			<cfqueryparam value="#GetBasketPasses.passtype#" cfsqltype="CF_SQL_VARCHAR">) -- Pass type
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

	<!---<CFDUMP var="#GetBasketPassMembersOC#"><CFABORT>--->

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
				<cfqueryparam value="#GetBasketPasses.passtype#" cfsqltype="CF_SQL_VARCHAR">) -- activity
		</cfquery>

	</cfif>

	<!--- end insert oc dist --->
<!--- copy gethousehold query from passrates2.cfm file --->
<cfquery datasource="#application.slavedopsds#" name="GetHousehold">
        SELECT   sessionpatrons.primarypatronid,
                 patrons.patronlookup,
                 sessionpatrons.relationtype,
                 patrons.lastname,
                 patrons.firstname,
                 patrons.middlename,
                 patrons.dob,
                 extract( 'years' from age( current_date, patrons.dob )) as years,
                 extract( 'months' from age( current_date, patrons.dob )) as months,
                 sessionpatrons.indistrict,
                 patrons.patroncomment,
                 patrons.verified,
                 patrons.patronid,
                 dops.isid( <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no"> ) as indistrict,
                 dops.usescrate( sessionpatrons.patronid::integer, current_date) as issenior,
                 dops.usemilrate( <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">, sessionpatrons.patronid::integer ) as ismil
        FROM     dops.sessionpatrons
                 inner join dops.patrons on sessionpatrons.secondarypatronid=patrons.patronid
        WHERE    sessionpatrons.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
        AND      not patrons.inactive
        ORDER BY sessionpatrons.relationtype, upper(patrons.lastname), upper(patrons.firstname)
</cfquery>



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
		<cfinclude template="/common/invoicetranxupdatetxdist.cfm">
		<cfset variables.runningtx = variables.runningtx - variables.ThisTranxAmount>
	</cfif>

</cfloop>

		<cfset LocalFac = 'WWW'>
		<!---
                <cfset finalchecksmsg = finalcheck( variables.nextinvoice, form.netdue, val( form.othercreditcardid ), form.othercreditused )>


                <cfif variables.finalchecksmsg neq "OK" or 0>
                        <CFSET message = finalchecksmsg>

                        <cfif 1>
                                <cfinclude template="/portalINC/displayallinvoicetables.cfm">
                        </cfif>

                        <CFINCLUDE template = "includes/layout.cfm"><cfabort>

                </cfif>
		--->

                <!--- rollback and display data if testing --->
                <cfif IsDefined("TestMode") or 0>
                        <cfinclude template="/portalINC/displayallinvoicetables.cfm">
                        <cfabort>
                </cfif>


<!--- final checks --->
<cfinclude template="finalchecks.cfm">

<CFIF Isdefined("variables.errormsg")>
	<CFSAVECONTENT variable="message">
		   #variables.errormsg#
	 </CFSAVECONTENT>
<CFINCLUDE template = "includes/layout.cfm">
<cfabort>
</CFIF>



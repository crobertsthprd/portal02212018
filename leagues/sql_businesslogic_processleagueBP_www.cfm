

		<cfset ThisModule = "WWW">
		<cfset ActivityLine = 0>
		<cfset GLLineNo = 0>
		<!---cfset NextInvoice = GetNextInvoice()--->
        <cfset NextInvoice = GetNextInvoice()>


		<!--- verify starting credit --->
		<cfquery name="GetStartingAccountBalanceCheck" datasource="#application.dopsds#">
			select dops.primaryaccountbalance(<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)
		</cfquery>

		<cfif dollarRound(GetStartingAccountBalanceCheck.primaryaccountbalance) is not dollarRound(originalavailablecredit)>
			<CFSAVECONTENT variable="message">
			Starting account balance did not match true balance.<br>
			</CFSAVECONTENT>
			<CFSET nobackbutton = false>
			<CFINCLUDE template = "includes/layout.cfm">
			<cfabort>
		</cfif>


		<!--- ----------------- --->
        <!--- Other Credit used --->
        <!--- ----------------- --->
        <CFPARAM name = "form.othercreditused" default="0">
        <CFPARAM name = "form.othercreditdata" default="0">
        <CFSET variables.othercreditused = form.othercreditused>
        <CFSET variables.othercreditdata= form.othercreditdata>
        <cfif variables.othercreditused gt 0 and variables.OtherCreditData is not 0>
			<cfquery name="GetApplicableFAFunds" datasource="#application.dopsdsro#">
        			select   sum( sessionusedfa ) as sumsessionusedfa
       			 from     dops.patronrelations
        			where    primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>

			<cfif GetApplicableFAFunds.sumsessionusedfa gt 0>
        			<cfset otherfacreditlimit = GetApplicableFAFunds.sumsessionusedfa>
			</cfif>

			<!--- we validate and encrypt on the prior page --->
            <cfset enOtherCreditData = variables.OtherCreditData>
            <cfquery datasource="#application.dopsds#" name="getCardData">
                    SELECT   othercreditdesc,
                             cardid,
                             othercredittype,
                             isfa,
                             faapptype,
                             faappid,
                             acctid,
                             faappcurrent,
                             faloadacctid,
                             primarypatronid,
                             dops.getavailableocfunds(othercredithistorysums.cardid, othercredithistorysums.primarypatronid, <cfqueryparam value="#DollarRound(totalfees)#" cfsqltype="CF_SQL_NUMERIC">, <cfqueryparam value="#DollarRound(netdue)#" cfsqltype="CF_SQL_NUMERIC">,<cfqueryparam cfsqltype="cf_sql_bit" value="true" list="no"> <cfif IsDefined("otherfacreditlimit")>, <cfqueryparam value="#max(0, otherfacreditlimit)#" cfsqltype="cf_sql_numeric" list="no"></cfif>) as sumnet
                    FROM     dops.othercredithistorysums
                    where    valid

                    <cfif IsNumeric(variables.OtherCreditData) and variables.OtherCreditData lt 999999999999>
                         and   cardid = <cfqueryparam value="#variables.OtherCreditData#" cfsqltype="CF_SQL_INTEGER">
                    <cfelse>
                         and   othercreditdata = <cfqueryparam value="#variables.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
                    </cfif>
                         and   ((isfa IS true and current_date < faappexpiredate) OR isfa IS false)
            </cfquery>
<!--- <cfdump var="#getCardData#" label="@@@"> --->

            <cfif GetCardData.recordcount is not 1>
	               <CFSAVECONTENT variable="message">
	               <CFOUTPUT>#variables.othercreditdata# #IsNumeric(variables.OtherCreditData)# Error in fetching Gift Card or is invalid/not activated/on hold for review.</CFOUTPUT>
	               </CFSAVECONTENT>
	               <CFINCLUDE template = "includes/layout.cfm">
	               <cfabort>
            <cfelseif GetCardData.primarypatronid is not "">
                    <cfif not IsDefined("primarypatronid") or form.primarypatronid is not GetCardData.primarypatronid>
                    	<CFSAVECONTENT variable="message">
               			<CFOUTPUT>Specified Card is registered to another party, thus cannot be used this transaction.</CFOUTPUT>
               		</CFSAVECONTENT>
              		 	<CFINCLUDE template = "includes/layout.cfm">
              	 		<cfabort>
                    </cfif>
            </cfif>
            <cfif getCardData.recordcount is 0>
                    <cfif IsNumeric(variables.OtherCreditData) and variables.OtherCreditData lt 999999999999>

                    <cfelse>
                         <cf_cryp type="de" string="#variables.enOtherCreditData#" key="#key#">
                         <cfset AttemptedCard = cryp.value>
                    </cfif>
                    <CFSAVECONTENT variable="message">
               		<CFOUTPUT>Cannot determine Other card used (#variables.AttemptedCard#). Go back and try again.</CFOUTPUT>
               		</CFSAVECONTENT>
               		<CFINCLUDE template = "includes/layout.cfm">
              	 	<cfabort>
            </cfif>

            <cfset otherCreditGLAcctid = getCardData.acctid>
			<!--- include requires query getCardData and form.OtherCreditUsed --->
            <cfinclude template="/common/OCCardUsagePrefix.cfm">

        </cfif>

		<cfset TotalOtherCreditAmount = 0>

		<cfif IsDefined("primarypatronid") and primarypatronid gt 0>
			<cfset thisds = cookie.ds>
		</cfif>

		<cfset QtyChkArray = ArrayNew(2)>
		<cfset hadatleastoneenrollment = 0>

		<cfif variables.othercreditused gt 0 and variables.OtherCreditData is not 0>
               <CFSET GCremaining = variables.othercreditused>
          <cfelse>
              	<CFSET GCremaining = 0>
		</cfif>

		<cfif 0>
			<cfdump var="#form#">
			<cfdump var="#FinalArray#" label="finalarray">
		</cfif>

		<cfset runningtx = form.tenderedcharge>
		<cfset thistx = 0>

		<!--- <cfoutput>before: #thistx#===#runningtx#</cfoutput> --->
		<cfloop from="1" to="#ArrayLen(FinalArray)#" step="1" index="x">

			<cfset QtyChkArray[x][1] = FinalArray[x][11]>

			<cfif FinalArray[x][10] gt 0 and FinalArray[x][5] is not "" and FinalArray[x][7] is not "">
				<cfset tmp = "preferredcoach" & FinalArray[x][1]>
				<cfset preferredcoach = evaluate(tmp)>
				<cfset tmp = "comments" & FinalArray[x][1]>
				<cfset comments = evaluate(tmp)>
				<cfset tmp = "preferredphone" & FinalArray[x][1]>
				<cfset preferredphone = evaluate(tmp)>
				<cfset tmp = "preferredemail" & FinalArray[x][1]>
				<cfset preferredemail = evaluate(tmp)>

                <!--- <cfset thistx = min( FinalArray[x][6], runningtx )> --->
				<cfset thistx = FinalArray[x][6] - FinalArray[x][12]>
                <!--- <cfset runningtx = runningtx - thistx> --->
				<!--- <cfoutput>after: #thistx#===#runningtx#</cfoutput><br> --->


 			<!--- make sure contact phone is valid
			<cfif trim(preferredphone) EQ "" OR IsValid("telephone",preferredphone) EQ false>
               	<CFSAVECONTENT variable="message">
				<b style="color:red">Please enter a contact phone number for each league enrollment.</b><br>
				</CFSAVECONTENT>
				<CFSET nobackbutton = false>
				<CFINCLUDE template = "includes/layout.cfm">
				<cfabort>
			</cfif>

			<cfif trim(preferredemail) NEQ "" AND IsValid("email",preferredemail) EQ false>
				<CFSAVECONTENT variable="message">
				<b style="color:red">Contact email is not valid for one or more league enrollments.</b><br>
				</CFSAVECONTENT>
				<CFSET nobackbutton = false>
				<CFINCLUDE template = "includes/layout.cfm">
				<cfabort>

			</cfif>
			--->


				<!--- insert enrollment data --->
                    <CFSET theFee = FinalArray[x][6]>
                    <CFSET theAmt = theFee - GCremaining>



                    <CFIF theAmt GTE 0>
                    	<CFSET GCremaining = 0>
                    <CFELSE>
                    	<CFSET theAmt = 0>
                         <CFSET GCremaining = GCremaining - theFee>
                    </CFIF>

				<!--- <cfoutput><br>===gcremaining#gcremaining#===<br></cfoutput> --->
				<!--- get next enrollment pk - may be used for TX later --->
				<cfquery datasource="#application.dopsds#" name="GetNextEnrollmentPK">
					select  nextval('content.th_league_enrollments_pk_seq') as tmp
				</cfquery>

				<cfquery datasource="#application.dopsds#" name="InsertData">
					insert into content.th_league_enrollments
						(pk,
						invoicefacid,
						invoicenumber,
						leaguetype,
						patronid,
						fee,
						shirtsize,
						elementary,
						middle,
						high,
						preferredcoach,
						comments,
						preferredcontactphone,
						preferredcontactemail,
						mil,
						ratemethod)
					values
						( <cfqueryparam value="#GetNextEnrollmentPK.tmp#" cfsqltype="cf_sql_integer" list="no">,
						<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, -- invoicefacid,
						<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- invoicenumber,
						<cfqueryparam value="#FinalArray[x][11]#" cfsqltype="CF_SQL_INTEGER">, -- leaguetype,
						<cfqueryparam value="#FinalArray[x][1]#" cfsqltype="CF_SQL_INTEGER">, -- patronid,
						<cfqueryparam value="#FinalArray[x][6]#" cfsqltype="CF_SQL_MONEY">, -- fee,
						<cfqueryparam value="#FinalArray[x][2]#" cfsqltype="CF_SQL_VARCHAR">, -- shirtsize,
						<cfqueryparam value="#FinalArray[x][8]#" cfsqltype="CF_SQL_INTEGER">, -- elementary,
						<cfqueryparam value="#FinalArray[x][9]#" cfsqltype="CF_SQL_INTEGER">, -- middle,
						<cfqueryparam value="#FinalArray[x][10]#" cfsqltype="CF_SQL_INTEGER">, -- high
						<cfif preferredcoach is not ""><cfqueryparam value="#lTrim(rTrim(preferredcoach))#" cfsqltype="CF_SQL_VARCHAR"><cfelse>null</cfif>, -- preferred coach
						<cfif comments is not ""><cfqueryparam value="#lTrim(rTrim(comments))#" cfsqltype="CF_SQL_VARCHAR"><cfelse>null</cfif>, -- comments
						<cfqueryparam value="#preferredphone#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#preferredemail#" cfsqltype="CF_SQL_VARCHAR">,
						(dops.usemilrate( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">, <cfqueryparam value="#getPatrons.secondarypatronid#" cfsqltype="cf_sql_integer" list="no"> ) ),
						(dops.getyouthleagrate( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" >, <cfqueryparam value="#getPatrons.secondarypatronid#" cfsqltype="cf_sql_integer">, <cfqueryparam value="#GetAppTypeLeagueFees.facid#" cfsqltype="cf_sql_varchar" >,<cfqueryparam value="#GetAppTypeLeagueFees.typecode#" cfsqltype="cf_sql_integer" >, 'true') ) )
					;

					<cfset NextEC = GetNextEC()>
					<cfset GLLineNo = GLLineNo + 1>

					insert into dops.GL
						(Credit,
						AcctID,
						InvoiceFacID,
						InvoiceNumber,
						EntryLine,
						ec,
						activity)
					values
						(<cfqueryparam value="#FinalArray[x][6]#" cfsqltype="CF_SQL_MONEY">,
						<cfqueryparam value="#FinalArray[x][13]#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="League Fees" cfsqltype="CF_SQL_VARCHAR">)
				</cfquery>

				<cfset hadatleastoneenrollment = 1>

				<!--- do the invoicetranxdist --->
				<!---<CFIF theAmt GT 0>--->
				<!--- <cfif form.tenderedcharge GT 0> --->
				<cfset ccshouldpay = dollarRound( FinalArray[x][6] - FinalArray[x][12] )>
				<cfif ccshouldpay GT 0>
					<cfset nextprc = GetNextPRC()>

					<cfquery name="InsertIntoTranxHist" datasource="#application.dopsds#">
						insert into dops.invoicetranxtrans
							( prc,
							leag )
						values
							( <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no"> )
						;

						update content.th_league_enrollments
						set
							prc = <cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">
						where  pk = <cfqueryparam value="#GetNextEnrollmentPK.tmp#" cfsqltype="cf_sql_integer" list="no">
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
							<cfqueryparam value="LEAG" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="WWW" cfsqltype="cf_sql_varchar" list="no">,
							<cfqueryparam value="#variables.nextinvoice#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#variables.nextprc#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#min(runningtx,variables.ccshouldpay)#" cfsqltype="cf_sql_numeric" list="no">, <!--- this needs to be fixed --->
							<cfqueryparam value="S" cfsqltype="cf_sql_char" maxlength="1" list="no">)
						</cfquery>

						<cfset runningtx = variables.runningtx - variables.ccshouldpay>
						<!--- <cfoutput>runningtx: #runningtx#--#ccshouldpay#<br></cfoutput> --->
					<cfinclude template="/common/invoicetranxupdatetxdist.cfm">
				</CFIF>

			</cfif>

			<cfif dollarRound( FinalArray[x][12] ) gt 0>
					<cfquery datasource="#application.dopsds#" name="_InsertOCRecords">
						insert into othercreditdist (
							invoicefacid,
							invoicenumber,
							patronid,
							activity,
							action,
							cardid,
							debit,
							credit)
						values
							(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, -- invoicefacid
							<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, -- invoicenumber
							<cfif FinalArray[x][1] is "">null<cfelse><cfqueryparam value="#FinalArray[x][1]#" cfsqltype="CF_SQL_INTEGER"></cfif>, -- patronid
							<cfqueryparam value="#FinalArray[x][4]#" cfsqltype="CF_SQL_VARCHAR">, -- activity
							<cfqueryparam value="LEAG" cfsqltype="CF_SQL_VARCHAR">, -- action
							<cfqueryparam value="#form.OTHERCREDITCARDID#" cfsqltype="CF_SQL_INTEGER">, -- cardid
							<cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">, -- debit
							<cfqueryparam value="#FinalArray[x][12]#" cfsqltype="CF_SQL_MONEY">) -- credit
					</cfquery>
			</cfif>

		</cfloop>



		<cfset TenderedCharge = AdjustedNetDue>

		<cfquery datasource="#application.dopsds#" name="InsertInvoice">
			insert into invoice
				(InvoiceFacID,
				InvoiceNumber,
				TotalFees,
				usedcredit,
				othercreditused,
				othercreditusedcardid,
				faappid,
				TenderedCC,

				<cfif ccNum is not "">
					CCA,
					CCED,
					CEW,
					ccType,
					CCV,
				</cfif>

				Node,
				userid,
				primarypatronid,
				primarypatronlookup,
				addressid,
				MAILINGADDRESSID,
				indistrict,
				insufficientid,
				startingbalance,
				invoicetype)
			values
				(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, --InvoiceFacID
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">, --InvoiceNumber
				<cfqueryparam value="#totalfees#" cfsqltype="CF_SQL_MONEY">, --TotalFees
				<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">, --Used Credit
				<cfqueryparam value="#othercreditused#" cfsqltype="CF_SQL_MONEY">, --othercreditused

				<cfif othercreditused gt 0>
					<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">, --othercreditusedcardid
				<cfelse>
					null, ----othercreditusedcardid
				</cfif>

				<cfif othercreditused gt 0 and GetCardData.faappid is not "">
					<cfqueryparam value="#GetCardData.faappid#" cfsqltype="CF_SQL_INTEGER">, --faappid
				<cfelse>
					null, --faappid
				</cfif>

				<cfqueryparam value="#TenderedCharge#" cfsqltype="CF_SQL_MONEY">, --TenderedCC

				<cfif ccNum is not "">
					<cfqueryparam value="#ccd#" cfsqltype="CF_SQL_VARCHAR">, --CCA
					<cfqueryparam value="#ccExp#" cfsqltype="CF_SQL_VARCHAR">, --CCED
					<cfqueryparam value="#right(ccNum,4)#" cfsqltype="CF_SQL_VARCHAR">, --CEW
					<cfqueryparam value="#left(ccNum,1)#" cfsqltype="CF_SQL_VARCHAR">, --ccType
					<cfqueryparam value="#ccven#" cfsqltype="CF_SQL_VARCHAR">, --CCV
				</cfif>

				<cfqueryparam value="#LocalNode#" cfsqltype="CF_SQL_VARCHAR">, --LocalNode
				<cfqueryparam value="#huserID#" cfsqltype="CF_SQL_INTEGER">, --huserID
				<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">, (

				select   patronlookup
				from     patrons
				where    patronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

				select   addressid
				from     patronrelations
				where    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
				and      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

				select   mailingaddressid
				from     patronrelations
				where    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
				and      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

				SELECT   indistrict
				FROM     patronrelations
				WHERE    primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
				AND      secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

				SELECT   patrons.insufficientid
				FROM     patronrelations patronrelations
				         INNER JOIN patrons patrons ON patronrelations.secondarypatronid=patrons.patronid
				WHERE    patronrelations.primarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
				AND      patronrelations.secondarypatronid = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">), (

				select   dops.primaryaccountbalance(<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">, now()::timestamp)),

				<cfqueryparam value="-LEAG-" cfsqltype="CF_SQL_VARCHAR">)
			;

			select invoice_relation_fill(<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">, <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">) as inserted
		</cfquery>



		<cfif hadatleastoneenrollment is 0>
                    <CFSAVECONTENT variable="message">
               		<br>
			<strong style="background-color: Yellow;">It appears no enrollments were completed.
			This could be due to selection combinations not being correct.</strong>
			<BR><BR>

               	</CFSAVECONTENT>
                    <CFSET nobackbutton = false>
               	<CFINCLUDE template = "includes/layout.cfm">
                    <CFABORT>
			<cfabort>

		</cfif>

		<!--- these views are using content schema - rewrite to appropriate place --->

		<!--- check for enrollment qty violation. done here as invoice must be created for view. --->
		<cfloop from="1" to="#ArrayLen(FinalArray)#" step="1" index="x">

			<cfquery datasource="#application.dopsds#" name="CheckForQtyViolation">
				SELECT   patronid
				FROM     content.th_league_enrollments_view
				WHERE    th_league_enrollments_view.valid
				AND      not th_league_enrollments_view.isvoided
				AND      th_league_enrollments_view.leaguetype in (

				select   leaguetype
				from     content.th_league_enrollments_view v
				where    v.invoicefacid = <cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">
				and      v.invoicenumber = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">)

				and      (

				SELECT   count(*)
				FROM     content.th_league_enrollments_view v
				WHERE    th_league_enrollments_view.valid
				AND      not th_league_enrollments_view.isvoided
				AND      v.leaguetype = th_league_enrollments_view.typecode) > th_league_enrollments_view.maxqty
			</cfquery>

			<cfif CheckForQtyViolation.recordcount gt 0>


                    <CFSAVECONTENT variable="message">
               		<br>
				<strong style="background-color: Yellow;">Proposed operation exceeded maximum enrollment counts for one or more leagues.</strong>
				<BR><BR>
				<a href="javascript:history.go(-1);"><strong><< Go back, refresh page and remove offending enrollments as needed and try again.</strong></a>
               	</CFSAVECONTENT>
                    <CFSET nobackbutton = true>
               	<CFINCLUDE template = "includes/layout.cfm">
				<CFABORT>
			</cfif>

		</cfloop>





		<cfif InsertInvoice.inserted is 0>
			<CFSAVECONTENT variable="message">
			<strong>Could not insert active patrons for proposed invoice. Contact THPRD.</strong>
			</CFSAVECONTENT>
			 <CFSET nobackbutton = true>
               <CFINCLUDE template = "includes/layout.cfm">
			<cfabort>
		</cfif>

		<!--- check for duplicates. has to be done AFTER invoice insertion since it uses invoice.isvoided as a param --->
		<cfquery datasource="#application.dopsds#" name="Check4Dups">
			SELECT   th_league_enrollments_view.patronid,
			         th_league_enrollments_view.leaguedesc,
			         th_league_enrollments_view.e_school,
			         th_league_enrollments_view.m_school,
			         th_league_enrollments_view.h_school,
			         th_league_enrollments_view.lastname,
			         th_league_enrollments_view.firstname,
			         th_league_enrollments_view.middlename
			FROM     content.th_league_enrollments_view th_league_enrollments_view
			         INNER JOIN invoice invoice ON th_league_enrollments_view.invoicefacid=invoice.invoicefacid AND th_league_enrollments_view.invoicenumber=invoice.invoicenumber
			WHERE    th_league_enrollments_view.valid = true
			AND      th_league_enrollments_view.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
			AND      invoice.isvoided = false
			GROUP BY th_league_enrollments_view.e_school, th_league_enrollments_view.m_school, th_league_enrollments_view.h_school, th_league_enrollments_view.leaguedesc, th_league_enrollments_view.patronid, th_league_enrollments_view.lastname, th_league_enrollments_view.firstname, th_league_enrollments_view.middlename
			HAVING   count(*) > <cfqueryparam value="1" cfsqltype="CF_SQL_INTEGER">
		</cfquery>

		<cfif Check4Dups.recordcount gt 0>


			<CFSAVECONTENT variable="message">
               	<strong style="background-color: Yellow;">Duplicate patron / pathing / activity was found. All operations rolled back.</strong><BR><BR>
			<CFOUTPUT>#Check4Dups.lastname#, #Check4Dups.firstname#, #Check4Dups.leaguedesc#</CFOUTPUT>
			<BR><BR>

               	</CFSAVECONTENT>
                    <CFSET nobackbutton = false>
               	<CFINCLUDE template = "includes/layout.cfm">
				<CFABORT>
		</cfif>
		<!--- end check for duplicates --->



		<cfquery datasource="#application.dopsds#" name="updateactive">
			update  invoicerelations
			set
				activethisinvoice = true
			where   invoicefacid = <cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">
			and     invoicenumber = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">
			and     secondarypatronid in (<cfqueryparam value="#patronactivethisinvoice#" cfsqltype="CF_SQL_INTEGER" list="Yes" separator=",">)
			and     secondarypatronid != <cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
		</cfquery>




		<!--- ----------- --->
		<!--- used credit --->
		<!--- ----------- --->
		<cfif CreditUsed greater than 0>

			<cfquery datasource="#application.dopsds#" name="GetGLDistCredit">
				select   AcctID
				from     GLMaster
				where    InternalRef = <cfqueryparam value="DC" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>

               <!--- this is completely wrong 10/28/2016 CR. Updated on PRODUCTION
			<cfif GetGLDistCredit.RecordCount is not 1>
				<strong>Error in fetching account ID for District Credits. Contact THPRD.</strong>
				<CFINCLUDE template="leaguefooter.cfm">
				<cfabort>
			</cfif>--->

               <cfif GetGLDistCredit.RecordCount is not 1>
				<CFSET message = "<strong>Error in fetching account ID for District Credits. Contact THPRD.</strong>">
				<CFINCLUDE template = "includes/layout.cfm">
                    <cfabort>
			</cfif>

			<cfset KeepThisInvoice = 1>
			<cfset NextEC = GetNextEC()>
			<cfset ActivityLine = ActivityLine + 1>

			<cfquery datasource="#application.dopsds#" name="AddToActivity">
				insert into Activity
					(ActivityCode,
					PrimaryPatronID,
					PatronID,
					InvoiceFacID,
					InvoiceNumber,
					Debit,
					Credit,
					line,
					EC)
				values
					(<cfqueryparam value="CU" cfsqltype="CF_SQL_VARCHAR">,
					<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
					<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">,
					<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#ActivityLine#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">)
				;

				<cfset GLLineNo = GLLineNo + 1>

				insert into GL
					(Debit,
					AcctID,
					InvoiceFacID,
					InvoiceNumber,
					EntryLine,
					EC,
					activitytype,
					activity)
				values
					(<cfqueryparam value="#CreditUsed#" cfsqltype="CF_SQL_MONEY">,
					<cfqueryparam value="#GetGLDistCredit.acctid#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
					<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
					<cfqueryparam value="C" cfsqltype="CF_SQL_VARCHAR">,
					<cfqueryparam value="Credit" cfsqltype="CF_SQL_VARCHAR">)
			</cfquery>

		</cfif>



		<cfif othercreditused gt 0 and OtherCreditData is not "">
			<cfset dopsds = application.dopsds>
			<!--- <cfset SetOCUsage(LocalFac, NextInvoice)> --->

		</cfif>


		<!--- final check; do not use deprecated
		<cfinclude template="/portalINC/FinalChecks.cfm">othercreditdata
		--->
		<cfset finalchecksmsg = finalcheck( variables.nextinvoice, form.netdue, val( form.othercreditcardid ), form.othercreditused )>


		<cfif variables.finalchecksmsg neq "OK" or 0>
			<CFSET message = finalchecksmsg>

			<cfif 1>
				<cfinclude template="/portalINC/displayallinvoicetables.cfm">
			</cfif>

			<CFINCLUDE template = "includes/layout.cfm"><cfabort>

		</cfif>


		<!--- rollback and display data if testing --->
		<cfif IsDefined("TestMode") or 0>
			<cfinclude template="/portalINC/displayallinvoicetables.cfm">
			<cfabort>
		</cfif>

<!--- new registrations / conversions --->
<!--- returns one row per registration --->
<cfloop from="1" to="2" step="1" index="RegProcLoop">

	<cfif RegProcLoop is 1>

		<cfquery datasource="#application.dopsds#" name="ProcessReg">
			SELECT   reg.termid, reg.facid, reg.classid, reghistory.depositonly,
			         REGHISTORY.RegID, REGHISTORY.amount, REGHISTORY.action,
			         REG.patronid, REGHISTORY.ec, reg.deferredpaid, reg.sessionid as sessionid1,
			         reg.deferred, reg.overridden, reg.IsBeingConverted, reghistory.primarypatronid,
			         reg.isstandby
			FROM     reghistory REGHISTORY
			         INNER JOIN reg REG ON REGHISTORY.primarypatronid=REG.primarypatronid AND REGHISTORY.RegID=REG.RegID
			where    SessionID = <cfqueryparam value="#CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">
			and      not reghistory.IsMiscFee
			and      not reghistory.voided
		</cfquery>

		<cfquery querytype="query" name="ProcessRegForComments">
			select   *
			from     ProcessReg
		</cfquery>

		<cfif (IsDefined("NewRegCount") and ProcessReg.recordcount is not NewRegCount) or 0>
			<cftransaction action="ROLLBACK">
			<!--- changes detected due to EWP/other session drop --->
			<BR><BR>
			<cfoutput>
			#ProcessReg.recordcount# new registrations were detected while #NewRegCount# were expected.
			Go back and try again
			</cfoutput>
			<BR><BR><a href="javascript:history.back();">Go Back</a>
			<cfabort>
		</cfif>

		<cfset ThisIsBeingConverted = 0>
	<cfelse>
		<!--- registration conversions --->
		<cfquery datasource="#application.dopsds#" name="ProcessReg">
			SELECT   SESSIONREGCONVERT.*, REG.*
			FROM     sessionregconvert
			         INNER JOIN reg REG ON SESSIONREGCONVERT.primarypatronid=REG.primarypatronid AND SESSIONREGCONVERT.regid=REG.regid
			where    sessionregconvert.SessionID = <cfqueryparam value="#CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">
		</cfquery>

		<cfset ThisIsBeingConverted = 1>

		<cfif ProcessReg.recordcount gt 0>
			<BR><BR><strong>Error occured during final processing. Go back and try again.</strong>
			<BR><BR><a href="javascript:history.back();">Go Back</a>
			<cfabort>
		</cfif>

	</cfif>

	<cfif ProcessReg.RecordCount greater than 0>
		<cfset KeepThisInvoice = 1>

		<cfloop query="ProcessReg">
			<!--- <cfset converttodefer = 0>
			<cfset converttodeposit = 0> --->

			<cfif IsBeingConverted is 0 and (action is "W" or action is "A")><!---  or sessionid1 is not "" --->

				<cfif action is "W" or action is "E">
					<cfset ActivityLine = ActivityLine + 1>

					<cfquery datasource="#application.dopsds#" name="AddToActivity">
						insert into Activity
							(TermID,
							FacID,
							Activity,
							ActivityCode,
							PatronID,
							InvoiceFacID,
							InvoiceNumber,
							line,
							EC,
							primarypatronid,
							regid)
						values
							(<cfqueryparam value="#TermID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#FacID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#ClassID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="WL" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#PatronID#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#ActivityLine#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#EC#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#regid#" cfsqltype="CF_SQL_INTEGER">)
					</cfquery>

					<cfset FoundNew = 1>
				</cfif>

			<cfelse>

				<cfif IsBeingConverted is 1>

				<cfelse>
					<!--- new registration --->
					<cfset costec = ec>
					<cfset miscec = costec + 1>

					<cfquery datasource="#application.dopsds#" name="GetClassCost">
						select   coalesce(amount,0) as amount
						from     reghistory
						where    RegID = <cfqueryparam value="#RegID#" cfsqltype="CF_SQL_INTEGER">
						and      PrimaryPatronID = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
						and      action = <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">
						and      not IsMiscFee
					</cfquery>

					<cfquery datasource="#application.dopsds#" name="GetMiscFee">
						select   coalesce(sum(amount),0) as amount
						from     reghistory
						where    RegID = <cfqueryparam value="#RegID#" cfsqltype="CF_SQL_INTEGER">
						and      PrimaryPatronID = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
						and      action = <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">
						and      IsMiscFee
					</cfquery>

					<cfquery datasource="#application.dopsds#" name="GetDeposit">
						select   coalesce(sum(amount),0) as amount
						from     reghistory
						where    RegID = <cfqueryparam value="#RegID#" cfsqltype="CF_SQL_INTEGER">
						and      PrimaryPatronID = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
						and      action = <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">
						and      depositbalpaid
					</cfquery>

				</cfif>

				<!--- history entries --->
				<cfif ThisIsBeingConverted is 0>
					<cfset action1 = action>
					<cfset activity1 = "CE">
					<cfset FoundNew = 1>

				<cfelseif ThisIsBeingConverted is 1 and ProcessReg.IsDefer is 1>
					<cfset action1 = "E">
					<cfset activity1 = "PF">

				<cfelseif ThisIsBeingConverted is 1 and ProcessReg.IsDeposit is 1>
					<cfset action1 = "E">
					<cfset activity1 = "PB">

				<cfelseif ThisIsBeingConverted is 1 and ProcessReg.IsWL is 1>
					<cfset action1 = "E">
					<cfset activity1 = "CWL">

				<cfelse>
					<BR>Cannot determine activity. Go back and try again.
					<cftransaction action="ROLLBACK">
					<BR><BR><a href="javascript:history.back();">Go Back</a>
					<cfabort>

				</cfif>

				<cfset ActivityLine = ActivityLine + 1>

				<cfquery datasource="#application.dopsds#" name="AddToActivity">
					insert into Activity
						(TermID,
						FacID,
						Activity,
						ActivityCode,
						PatronID,
						InvoiceFacID,
						InvoiceNumber,
						Debit,
						line,
						EC,
						primarypatronid,
						regid,
						overridden,
						deferred,
						DepositOnly,
						isstandby)
					values
						(<cfqueryparam value="#TermID#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#FacID#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#ClassID#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#activity1#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#PatronID#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
						<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,

						<cfif IsDefined("ProcessReg.converttodefer") and ProcessReg.converttodefer is 1>
							<cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
						<cfelse>
							<cfqueryparam value="#GetClassCost.amount#" cfsqltype="CF_SQL_MONEY">
						</cfif>,

						<cfqueryparam value="#ActivityLine#" cfsqltype="CF_SQL_INTEGER">,

						<cfif IsDefined("ProcessReg.converttodefer") and ProcessReg.converttodefer is 1>
							<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
						<cfelse>
							<cfqueryparam value="#costec#" cfsqltype="CF_SQL_INTEGER">
						</cfif>,

						<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
						<cfqueryparam value="#regid#" cfsqltype="CF_SQL_INTEGER">,

						<cfif overridden is 1>
							<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
						<cfelse>
							<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
						</cfif>,

						<cfif (deferred is 1 and ThisIsBeingConverted is 0) or (IsDefined("ProcessReg.converttodefer") and ProcessReg.converttodefer is 1)>
							<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
						<cfelse>
							<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
						</cfif>,

						<cfif (IsDefined("ProcessReg.converttodposit") and ProcessReg.converttodeposit is 1 or DepositOnly is 1)>

							<cfif activity1 is "PB">
								<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
							<cfelse>
								<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
							</cfif>

						<cfelse>
							<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
						</cfif>,

						<cfif isstandby is 1>
							<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
						<cfelse>
							<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
						</cfif>)

				</cfquery>

				<!--- count misc fee rows for deferred entries --->
				<cfquery datasource="#application.dopsds#" name="CountMiscFeeRows">
					select   coalesce(count(*),0) as cnt
					from     reghistory
					where    RegID = <cfqueryparam value="#RegID#" cfsqltype="CF_SQL_INTEGER">
					and      PrimaryPatronID = <cfqueryparam value="#PrimaryPatronID#" cfsqltype="CF_SQL_INTEGER">
					and      action = <cfqueryparam value="E" cfsqltype="CF_SQL_VARCHAR">
					and      IsMiscFee
				</cfquery>

				<!--- misc fee if present --->
				<cfif GetMiscFee.amount is not 0 or CountMiscFeeRows.cnt is not 0>

					<cfset ActivityLine = ActivityLine + 1>

					<cfquery datasource="#application.dopsds#" name="AddToActivity">
						insert into Activity
							(TermID,
							FacID,
							Activity,
							ActivityCode,
							PatronID,
							InvoiceFacID,
							InvoiceNumber,
							Debit,
							line,
							EC,
							primarypatronid,
							regid,
							IsMiscFee,
							overridden,
							deferred)
						values
							(<cfqueryparam value="#TermID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#FacID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#ClassID#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#activity1#M" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#PatronID#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,

							<cfif IsDefined("ProcessReg.converttodefer") and ProcessReg.converttodefer is 1>
								<cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
							<cfelse>
								<cfqueryparam value="#GetMiscFee.amount#" cfsqltype="CF_SQL_MONEY">
							</cfif>,

							<cfqueryparam value="#ActivityLine#" cfsqltype="CF_SQL_INTEGER">,

							<cfif IsDefined("ProcessReg.converttodefer") and ProcessReg.converttodefer is 1>
								<cfqueryparam value="0" cfsqltype="CF_SQL_INTEGER">
							<cfelse>
								<cfqueryparam value="#miscec#" cfsqltype="CF_SQL_INTEGER">
							</cfif>,

							<cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#regid#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">,

							<cfif overridden is 1>
								<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
							<cfelse>
								<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
							</cfif>,

							<cfif (deferred is 1 and ThisIsBeingConverted is 0) or (IsDefined("ProcessReg.converttodefer") and ProcessReg.converttodefer is 1)>
								<cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
							<cfelse>
								<cfqueryparam value="false" cfsqltype="CF_SQL_BIT">
							</cfif>)
					</cfquery>

				</cfif>

				<cfquery datasource="#application.dopsds#" name="GetClassData">
					SELECT   CLASSES.glacctid, CLASSES.glmiscacctid
					FROM     reg REG
					         INNER JOIN classes CLASSES ON REG.termid=CLASSES.termid AND REG.facid=CLASSES.facid AND REG.classid=CLASSES.classid
					WHERE    reg.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
					AND      reg.regid = <cfqueryparam value="#regid#" cfsqltype="CF_SQL_INTEGER">
				</cfquery>

				<cfif GetClassCost.amount greater than 0>
					<cfset GLLineNo = GLLineNo + 1>

					<cfquery datasource="#application.dopsds#" name="InsertClassGL2">
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
							(<cfqueryparam value="#GetClassCost.amount#" cfsqltype="CF_SQL_MONEY">,
							<cfqueryparam value="#GetClassData.GLAcctID#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#costec#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="R" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#TermID#-#FacID#-#ClassID#" cfsqltype="CF_SQL_VARCHAR">)
					</cfquery>

				</cfif>

				<cfif GetMiscFee.amount greater than 0>
					<cfset GLLineNo = GLLineNo + 1>

					<cfquery datasource="#application.dopsds#" name="InsertClassMiscGL2">
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
							(<cfqueryparam value="#GetMiscFee.amount#" cfsqltype="CF_SQL_MONEY">,
							<cfqueryparam value="#GetClassData.GLMiscAcctID#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="#miscec#" cfsqltype="CF_SQL_INTEGER">,
							<cfqueryparam value="R" cfsqltype="CF_SQL_VARCHAR">,
							<cfqueryparam value="#TermID#-#FacID#-#ClassID#" cfsqltype="CF_SQL_VARCHAR">)
					</cfquery>

				</cfif>

			</cfif>

		</cfloop>

		<cfquery datasource="#application.dopsds#" name="UpdateRegEntry2">
			update  reg
			set
				SessionID = null
			where   primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
			and     SessionID = <cfqueryparam value="#CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">
			;
			update reghistory
			set
				amount = <cfqueryparam value="0" cfsqltype="CF_SQL_MONEY">
			where   primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
			and     not finished
			and     action = <cfqueryparam value="F" cfsqltype="CF_SQL_VARCHAR">
			;
			update  reghistory
			set
				INVOICEFACID = <cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
				INVOICENUMBER = <cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
				finished = <cfqueryparam value="true" cfsqltype="CF_SQL_BIT">
			where   primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="CF_SQL_INTEGER">
			and     invoicenumber is null
		</cfquery>

		<cfif RegProcLoop is 2>

			<cfquery datasource="#application.dopsds#" name="DeleteConvertSession">
				delete  from sessionregconvert
				where   sessionid = <cfqueryparam value="#CurrentSessionID#" cfsqltype="CF_SQL_VARCHAR">
			</cfquery>

		</cfif>

	</cfif>

</cfloop>
<!--- OC Prefix --->

<cfif OtherCreditUsed gt 0>

	<cfif GetCardData.othercredittype is "V">
		<cfset nextec = GetNextEC()>
	
		<cfquery datasource="#application.dopsds#" name="Voucher_Prep">
			insert into othercreditdatahistory
				(cardid,
				invoicefacid,
				invoicenumber,
				debit,
				action,
				userid,
				module,
				ec)
			values
				(<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#OtherCreditUsed#" cfsqltype="CF_SQL_MONEY">,
				<cfqueryparam value="U" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#huserid#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#ThisModule#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#nextec#" cfsqltype="CF_SQL_INTEGER">)

			;

			<cfset GLLineNo = GLLineNo + 1>
	
			insert into GL
				(debit,
				AcctID,
				InvoiceFacID,
				InvoiceNumber,
				EntryLine,
				EC,
				activitytype,
				activity)
			values
				(<cfqueryparam value="#OtherCreditUsed#" cfsqltype="CF_SQL_MONEY">, 
				<cfqueryparam value="#otherCreditGLAcctid#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#NextEC#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="BL" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="Voucher Benefit Load" cfsqltype="CF_SQL_VARCHAR">)
		</cfquery>
	
	
	
	<cfelseif GetCardData.othercredittype is "GC">
		<cfset nextec = GetNextEC()>
		
		<cfquery datasource="#application.dopsds#" name="GC_Prep">
			insert into othercreditdatahistory
				(cardid,
				invoicefacid,
				invoicenumber,
				debit,
				action,
				userid,
				module,
				ec)
			values
				(<cfqueryparam value="#GetCardData.cardid#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#OtherCreditUsed#" cfsqltype="CF_SQL_MONEY">,
				<cfqueryparam value="U" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#huserid#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#ThisModule#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#nextec#" cfsqltype="CF_SQL_INTEGER">)
			;

			<cfset GLLineNo = GLLineNo + 1>

			insert into GL
				(debit,
				AcctID,
				InvoiceFacID,
				InvoiceNumber,
				EntryLine,
				ec,
				activitytype,
				activity)
			values
				(<cfqueryparam value="#OtherCreditUsed#" cfsqltype="CF_SQL_MONEY">,
				<cfqueryparam value="#otherCreditGLAcctid#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#LocalFac#" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#NextInvoice#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#GLLineNo#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="#nextec#" cfsqltype="CF_SQL_INTEGER">,
				<cfqueryparam value="OCU" cfsqltype="CF_SQL_VARCHAR">,
				<cfqueryparam value="#GetCardData.othercreditdesc# Used" cfsqltype="CF_SQL_VARCHAR">)
		</cfquery>
	
	</cfif>


</cfif>
<!--- end OC Prefix --->

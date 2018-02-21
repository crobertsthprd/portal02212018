<!--- process oc usage for passes --->
<!--- uses getCardData.sumnet as available balance --->
<cfoutput>

<cfif IsDefined("OCFundsDist")>
	<cfset runningOC = getCardData.sumnet>

	<cfquery datasource="#application.dopsds#" name="GetBasketPassesForOC">
		SELECT   sessionpasses.passfee,
		         sessionpasses.ec,
		         passtype.passdescription,
		         sessionpasses.passterm,
		         sessionpasses.passallocation
		FROM     dops.sessionpasses sessionpasses
		         INNER JOIN dops.passtype passtype ON sessionpasses.passtype=passtype.passtype
		WHERE    sessionpasses.sessionid = <cfqueryparam value="#GetSession.sessionid#" cfsqltype="cf_sql_varchar" list="no">
		ORDER BY sessionpasses.ec
	</cfquery>

	<cfif getCardData.isfa and not GetHousehold.indistrict[1]>
		<TR>
			<TD colspan="99"><BR></td>
		</tr>
		<TR>
			<td colspan="99">
				Scholarship gift card has been detected.
				However, this type of gift card is only available for in district households.
				Specifify another card or contact THPRD for assisstance.
			</td>
		</tr>
		<cfabort>
	</cfif>

	<cfif getCardData.isfa>
		<TR>
			<TD colspan="99"><BR></td>
		</tr>
		<TR>
			<td colspan="99">
				Scholarship gift card has been detected.
				Available funds and allocated amount for each member is shown below.
			</td>
		</tr>
	</cfif>

	<cfset usedOC = 0>

	<cfloop query="GetBasketPassesForOC">

		<cfquery datasource="#application.dopsds#" name="GetBasketPassMembersForOC">
			SELECT   sessionpassmembers.pk,
			         sessionpassmembers.patronid,
			         patrons.lastname,
			         patrons.firstname,
			         extract( 'years' from age( current_date, patrons.dob ) ) as years,
			         extract( 'months' from age( current_date, patrons.dob ) ) as months
			FROM     dops.sessionpassmembers sessionpassmembers
			         INNER JOIN dops.patrons patrons ON sessionpassmembers.patronid=patrons.patronid
			WHERE    sessionpassmembers.ec = <cfqueryparam value="#GetBasketPassesForOC.ec#" cfsqltype="cf_sql_integer" list="no">
			ORDER BY patrons.lastname, patrons.firstname
		</cfquery>

		<cfset permemberprice = dollarCeiling( min( GetBasketPassesForOC.passfee, form.netdue ) / GetBasketPassMembersForOC.recordcount )>
		<cfset runningtotalOC = 0>

		<!--- create field for all members, even those with 0.00 usage --->
		<cfloop query="GetBasketPassMembersForOC">
			<cfset x = min( variables.permemberprice, variables.runningOC )>

			<!--- limit to FA grant this patron --->
			<cfif getCardData.isfa>

				<cfquery datasource="#application.dopsds#" name="getPatronFABalance">
					SELECT   dops.getfapatronbalance( <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">, <cfqueryparam value="#GetBasketPassMembersForOC.patronid#" cfsqltype="CF_SQL_INTEGER"> ) as avail
				</cfquery>

				<cfset x = min( variables.x, getPatronFABalance.avail )>

				<cfif GetBasketPassMembersForOC.currentrow eq 1>
					<TR style="background-color: bbbbbb;">
						<TD colspan="99">#GetBasketPassesForOC.passdescription#, #GetBasketPassesForOC.passterm# month</td>
					</tr>
					<TR style="background-color: bbbbbb;">
						<TD colspan="2">Patron</td>
						<TD align="right" width="1%">Available</td>
						<TD align="right" width="1%">Amount</td>
					</tr>
				</cfif>

				<!--- display FA OCs --->
				<TR>
					<TD colspan="2">
						#GetBasketPassMembersForOC.lastname#,
						#GetBasketPassMembersForOC.firstname#
						(#GetBasketPassMembersForOC.years#y, #GetBasketPassMembersForOC.months#m)
					</td>
					<TD align="right">#decimalformat( getPatronFABalance.avail )#</td>
					<TD align="right">
						<input name="OCFunds_#GetBasketPassMembersForOC.pk#" type="text" value="#decimalformat( variables.x )#" readonly style="text-align: right; width: #variables.moneywidth#px; background-color:white;" readonly>
					</td>
				</tr>
                    <!--- update session table --->
               	<cfquery datasource="#application.dopsds#" name="StuffOCAmount">
				update dops.sessionpassmembers
				set
					ocdist = <cfqueryparam value="#variables.x#" cfsqltype="cf_sql_money" list="no">
				where  pk = <cfqueryparam value="#GetBasketPassMembersForOC.pk#" cfsqltype="cf_sql_integer" list="no">
				</cfquery>
			<cfelse>
				<!--- hide non-FA OCs --->
				<input name="OCFunds_#GetBasketPassMembersForOC.pk#" type="hidden" value="#variables.x#">
			</cfif>

			<cfset runningtotalOC = variables.runningtotalOC + variables.x>
			<input name="OCFieldList" type="hidden" value="OCFunds_#GetBasketPassMembersForOC.pk#">
			<cfset runningOC = variables.runningOC - variables.x>
			<cfset usedOC = variables.usedOC + variables.x>
               

               
		</cfloop>

	</cfloop>

	<cfif getCardData.isfa>
		<TR>
			<TD colspan="3" align="right">Total</td>
			<TD align="right">#decimalformat( variables.runningtotalOC )#</td>
		</tr>
	</cfif>

	<cfif not getCardData.isfa>
		<TD align="right" colspan="3">
			less Gift Card

			<cfif getCardData.cardname neq "">
				named #getCardData.cardname#
			<cfelse>
				#ccformat( variables.ocNum )#
			</cfif>

		</td>
		<TD>
			<input name="tenderedoc" type="Text" value="#trim( numberformat( variables.usedOC, "999999.99" ))#" maxlength="7" style="text-align: right; width: #variables.moneywidth#px; background-color: #variables.inputcolor#;" title="Amount of gift card funds to be applied to current invoice.">
		</td>
	</cfif>

</cfif>

</cfoutput>

<cfoutput>
<!--- if wish to apply OC usage limit, define before calling this page --->
<cfset variables.inputcolor = "a6feff">
<cfparam name="PaymentSequence" default="1">
<cfparam name="moneywidth" default="65">
<cfparam name="OCCardNumber" default="">
<cfparam name="TenderedOC" default="0.00">
<cfset NetFees = variables.TotalFees - max( 0, min( variables.StartCredit, variables.TotalFees ) )>
<cfset NetDue = variables.NetFees>



<!--- note: empty tds are present to accomodate future columns --->
<table border="0" cellpadding="1" cellspacing="0" width="100%">
<TR>
	<td colspan="99"><BR></td>
</tr>
<TR align="right">
	<TD></td>
	<TD></td>
	<TD nowrap><strong>Starting Balance</strong></TD>
	<td align="right" width="1"><input name="AvailableCredit" value="#trim( NumberFormat(variables.StartCredit,'99999.99'))#" readonly="yes" tabindex="-1" style="text-align: right; background: white; width: #variables.moneywidth#px;" type="Text"></td>
</TR>
<TR align="right">
	<TD></td>
	<TD></td>
	<TD nowrap>Total Fees</TD>
	<td align="right" width="1"><input name="TotalFees" value="#trim( NumberFormat(variables.TotalFees,"999999.99"))#" type="Text" readonly="yes" tabindex="-1" style="text-align: right; background: white; width: #variables.moneywidth#px;"></td>
</TR>
<TR align="right">
	<TD></td>
	<TD></td>
	<td nowrap>District Credit Used</td>
	<td align="right" width="1"><input name="CreditUsed" readonly="yes" tabindex="-1" value="#trim( NumberFormat(max(0,min(StartCredit, TotalFees)),"999999.99"))#" type="Text" style="text-align: right; background: white; width: #variables.moneywidth#px;"></td>
</TR>
<TR align="right">
	<TD></td>
	<TD></td>
	<td align="right" nowrap><strong>Net Due</strong></td>
	<td width="1%" align="right"><input name="NetDue" value="#trim( NumberFormat( variables.NetFees, '99999.99' ))#" type="Text" readonly="yes" tabindex="-1" style="text-align: right; background: white; width: #variables.moneywidth#px;" title="Total of all new charges before any credits have been applied"></td>
</TR>

<cfset TenderedOC = max( 0, val( TenderedOC ))>

<cfif OCCardNumber neq "" and TenderedOC neq 0>
	<!--- verify amount to be used --->
	<cfset ocNum = REReplace( OCCardNumber, "[^0-9]", "", "all" )>
	<cf_cryp type="en" string="#variables.ocNum#" key="#variables.key#">
	<cfset enOtherCreditData = cryp.value>

	<!--- lookup card by id - improves speed --->
	<cfquery datasource="#application.dopsds#" name="getCardID">
		SELECT   cardid
		FROM     dops.othercredithistorysums
		where    othercreditdata = <cfqueryparam value="#variables.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
	</cfquery>

	<cfquery datasource="#application.dopsds#" name="getCardData">
		SELECT   othercreditdesc,
		         cardid,
		         cardname,
		         othercredittype,
		         isfa,
		         faapptype,
		         valid,
		         activated,
		         holdforreview,
		         dops.getavailableocfunds(
		         	othercredithistorysums.cardid,
		         	othercredithistorysums.primarypatronid,
		         	<cfqueryparam value="#DollarRound( variables.TotalFees )#" cfsqltype="cf_sql_numeric">,
		         	<cfqueryparam value="#DollarRound( variables.NetDue )#" cfsqltype="cf_sql_numeric">,
		         	<cfqueryparam value="#variables.useextensivemode#" cfsqltype="cf_sql_bit" list="no">
		         	<cfif IsDefined("variables.otherfacreditlimit")>
		         		, <cfqueryparam value="#max( 0, variables.otherfacreditlimit )#" cfsqltype="cf_sql_numeric" list="no">
		         	</cfif> ) as sumnet
		FROM     dops.othercredithistorysums
		where    cardid = <cfqueryparam value="#getCardID.cardid#" cfsqltype="cf_sql_integer">

		<cfif not GetHousehold.indistrict[1]>
			and      not isfa
		</cfif>

	</cfquery>

	<cfif getCardData.recordcount eq 1>
		<cfset TenderedOC = min( getCardData.sumnet, TenderedOC )>
		<input type="hidden" name="occardid" value="#getCardData.cardid#">
	<cfelse>
		<cfset TenderedOC = 0>
		<cfset OCCardNumber = "">
	</cfif>

</cfif>

<!--- start sectionals for each process sequence --->
<!---
section 0: all funds and dc used that always show
section 1: OC card prompt
section 2: OC amount prompt if valid card number is supplied
section 3: net due and credit card prompt (if needed)
 --->

<cfif PaymentSequence eq 1>
	<!--- gift card options --->
	<cfquery datasource="#application.dopsds#" name="getOCCards">
		SELECT   othercreditdata,
		         othercredittype,
		         cardname,
		         dops.getavailableocfunds(
		         	othercredithistorysums.cardid,
		         	othercredithistorysums.primarypatronid,
		         	<cfqueryparam value="99999999" cfsqltype="cf_sql_numeric">,
		         	<cfqueryparam value="99999999" cfsqltype="cf_sql_numeric">,
		         	<cfqueryparam value="true" cfsqltype="cf_sql_bit" list="no"> ) as sumnet
		FROM     dops.othercredithistorysums
		where    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="CF_SQL_INTEGER">
		and      valid
		and      activated
		and      ( faappstatus = <cfqueryparam value="G" cfsqltype="cf_sql_varchar" list="no"> or faappstatus is null )
		and      not holdforreview
		and      othercreditdata is not null

		<cfif not GetHousehold.indistrict[1]>
			and      not isfa
		</cfif>

	</cfquery>

	<!--- remove 0 bal cards --->
	<cfquery dbtype="query" name="getOCCards">
		select  *
		from    getOCCards
		where   sumnet > 0
	</cfquery>

	<cfif getOCCards.recordcount gt 0 and 1>
		<!--- show option to select registered cards --->
		<TR>
			<TD colspan="99" align="right">
				If you wish to use a gift card, either select from the list or enter the card number below.
			</td>
		</tr>
		<TR align="right">
			<TD colspan="99" nowrap>

				<select name="registeredcard" onChange="getElementById('OCCardNumber').value=this.options[this.options.selectedIndex].value;">
					<option value="">------------ Select Card ------------</option>

					<CFLOOP query="getOCCards">
						<cf_cryp type="de" string="#getOCCards.othercreditdata#" key="#variables.skey#">
						<cfset x = ccformat( cryp.value )>
						<option value="#variables.x#"><cfif ltrim( rtrim( getOCCards.cardname ) ) neq "">Card: #ltrim( rtrim( getOCCards.cardname ) )#<cfelse>#variables.x#</cfif> ($ #decimalformat( sumnet )#)</option>
					</CFLOOP>

				</select>

			</TD>
		</TR>
	<cfelse>
		<TR>
			<TD colspan="99" align="right">
				If you wish to use a gift card, enter the card number below.
			</td>
		</tr>
	</cfif>

	<TR>
		<TD colspan="99" align="right">
			<input type="button" value="Go Back" onClick="history.go(-1)">
			<input id="OCCardNumber" name="OCCardNumber" type="text" maxlength="19" value="" style="width: 140px; background-color: #variables.inputcolor#;" #disableenterkey# title="Enter gift card number. Spaces are allowed.">&nbsp;
			<input name="LoadOCCard" type="submit" value="Continue">
		</td>
	</tr>
</cfif>

<cfif PaymentSequence eq 2><CFABORT>
	<!--- show gc fields --->
	<tr>

		<cfif form.OCCardNumber neq "">
			<cfset ocNum = REReplace( form.OCCardNumber, "[^0-9]", "", "all" )>

			<cfif len( variables.ocNum ) neq 16>
				<TD>
					Error in specified gift card number. Go back and try again.
					<input type="button" value="Go Back" onClick="history.go(-1)">
					<cfabort>
				</td>
			<cfelse>
				<cf_cryp type="en" string="#variables.ocNum#" key="#variables.key#">
				<cfset enOtherCreditData = cryp.value>

				<!--- lookup card by id - improves speed --->
				<cfquery datasource="#application.dopsds#" name="getCardID">
					SELECT   cardid,
					         activated,
					         valid,
					         primarypatronid,
					         holdforreview
					FROM     dops.othercredithistorysums
					where    othercreditdata = <cfqueryparam value="#variables.enOtherCreditData#" cfsqltype="CF_SQL_VARCHAR">
				</cfquery>

				<cfif getCardID.recordcount eq 0>
					<TD colspan="99" align="right">
						Specified gift card could not be found. Go back and try again.
						<input type="button" value="Go Back" onClick="history.go(-1)">
					</td>
					<cfabort>
				</cfif>

				<cfif 0>
					<cfdump var="#getCardID#">
				</cfif>

				<cfset cardproblemtext = "">

				<cfif not getCardID.valid>
					<cfset cardproblemtext = "Card was found but is marked as invalid.">
				<cfelseif getCardID.holdforreview>
					<cfset cardproblemtext = "Card was found but is on hold for review.">
				<cfelseif not getCardID.activated>
					<cfset cardproblemtext = "Card was found but has not been activiated.">
				<cfelseif val( getCardID.primarypatronid ) neq 0 and getCardID.primarypatronid neq form.primarypatronid>
					<cfset cardproblemtext = "Card was found but is registered to another party.">
				</cfif>

				<cfif variables.cardproblemtext neq "">
					<TD colspan="99" align="right">
						#variables.cardproblemtext# Go back and try again or contact THPRD for assisstance.
						<input type="button" value="Go Back" onClick="history.go(-1)">
					</td>
					<cfabort>
				</cfif>

				<!--- if variables.otherfacreditlimit is defined, it is supplied to function --->
				<cfquery datasource="#application.dopsds#" name="getCardData">
					SELECT   othercreditdesc,
					         cardid,
					         cardname,
					         othercredittype,
					         isfa,
					         faapptype,
					         valid,
					         activated,
					         holdforreview,
					         dops.getavailableocfunds(
					         	othercredithistorysums.cardid,
					         	othercredithistorysums.primarypatronid,
					         	<cfqueryparam value="#DollarRound( variables.TotalFees )#" cfsqltype="cf_sql_numeric">,
					         	<cfqueryparam value="#DollarRound( variables.NetDue )#" cfsqltype="cf_sql_numeric">,
					         	<cfqueryparam value="#variables.useextensivemode#" cfsqltype="cf_sql_bit" list="no"> ) as sumnet
					FROM     dops.othercredithistorysums
					where    cardid = <cfqueryparam value="#getCardID.cardid#" cfsqltype="cf_sql_integer">
				</cfquery>

				<input type="hidden" name="TenderedOCLimit" value="#getCardData.sumnet#">

				<cfif getCardData.recordcount eq 1>
					<!--- include specified file to process apps OC usage, set by calling prg --->
					<cfinclude template="#variables.occalcpage#">
				<cfelse>
					<TD colspan="99" align="right">
						Problem with obtaining gift card information. Go back and try again or contact THPRD for assisstance.
						<input type="button" value="Go Back" onClick="history.go(-1)">
					</td>
					<cfabort>
				</cfif>

			</cfif>

		</cfif>

	</tr>

	<cfif OCCardNumber neq "">
		<TR>
			<TD align="right" colspan="99">
				<!---The default amount is the lesser of applicable card balance and net due. However, you can change the value.<BR>--->
				<input type="button" value="Go Back" onClick="history.go(-1)">
				<input name="LoadOCCard" type="submit" value="Continue">
			</td>
		</tr>
	</cfif>

</cfif>

<cfset NetDue = variables.NetDue - variables.TenderedOC>

<cfif IsDefined("form.LoadOCCard") and OCCardNumber eq "">
	<cfset PaymentSequence = PaymentSequence + 1>
</cfif>

<cfif PaymentSequence eq 3>
	<TR align="right">
		<TD></td>
		<TD></td>
		<td align="right" nowrap>less Gift Card #ccformat( OCCardNumber )#</td>
		<td align="right"><input name="TenderedOC" value="#trim( NumberFormat( variables.TenderedOC, '99999.99' ))#" type="Text" readonly="yes" tabindex="-1" style="text-align: right; background: white; width: #variables.moneywidth#px;" title="Amount from gift card to be applied."></td>
	</TR>
	<TR align="right">
		<TD></td>
		<TD></td>
		<td align="right" nowrap><strong>Adjusted Net Due</strong></td>
		<td align="right"><input name="AdjustedNetDue" value="#trim( NumberFormat( variables.NetDue, '99999.99' ))#" type="Text" readonly="yes" tabindex="-1" style="text-align: right; background: white; width: #variables.moneywidth#px;" title="Adjusted net due where all credit have been applied to all charges."></td>
	</TR>
	<TR align="right">
		<TD><BR></td>
		<TD></td>
		<TD></td>
		<td></td>
	</TR>
	<tr>
		<td colspan="99">

			<table border="0" cellpadding="1" cellspacing="0" width="100%">

				<cfif variables.NetDue gt 0>
					<TR>
						<TD align="right" nowrap colspan="99" style="background-color: bbbbbb;">Credit Card Data (change card holder data as needed)</td>
					</TR>
					<TR>
						<TD align="right" nowrap>First / Last names on card</td>
						<TD width="1%">
							<input type="Text" name="ccFirstName" value="#GetHousehold.firstname[1]#" style="width: 100px; background-color: #variables.inputcolor#;" #disableenterkey# title="Enter first name on credit card.">
							<input type="Text" name="ccLastName" value="#GetHousehold.lastname[1]#" style="width: 100px; background-color: #variables.inputcolor#;" #disableenterkey# title="Enter last name on credit card.">
						</td>
					</TR>
					<TR>
						<TD align="right" nowrap>Credit Card Number</td>
						<TD width="1%">
							<input type="Text" name="ccNum" id="ccNum" value="" style="width: 135px; background-color: #variables.inputcolor#;" <cfif NetFees is 0 and ForceEnableFunds is 0>class="readonly" readonly tabindex="-1"<cfelse></cfif> maxlength="19" onChange="javascript:if (isValidCreditCardNumber(this.value,document.f.ccType.value,'Credit Card',false)==false) {} <!--- {this.value=''} --->calcnetbal();" #disableenterkey# title="Enter credit card number. Spaces are optional.">
						</td>
					</TR>
					<TR>
						<TD align="right" nowrap>Expiration Month / Year</td>
						<TD width="1%" nowrap>

							<select name="ccExpMon" style="background-color: #variables.inputcolor#;">

								<cfloop from="1" to="12" step="1" index="x">
									<option value="x">#numberformat( x, "00" )# - #MonthAsString(x)#</option>
								</cfloop>

							</select>

							<cfset startyear = dateformat( now(), "yyyy" )>

							<select name="ccExpYear" style="background-color: #variables.inputcolor#;">

								<cfloop from="#variables.startyear#" to="#variables.startyear + 10#" step="1" index="x">
									<option value="x">#x#</option>
								</cfloop>

							</select>

						</td>
					</TR>
					<TR>
						<TD align="right" nowrap>CCV</td>
						<TD width="1%" nowrap>
							<input type="Text" name="ccv" id="ccv" value="" style="width: 45px; background-color: #variables.inputcolor#;" onChange="javascript:this.value=alltrim(this.value);if ((this.value != ''&&isNaN(this.value))||(this.value!=''&&this.value.length!=3)) {alert('Incorrect CCV format');this.value='';} calcnetbal();" <cfif NetFees is 0 and ForceEnableFunds is 0>class="readonly" readonly tabindex="-1"<cfelse></cfif> maxlength="4" #disableenterkey# title="Enter credit card CCV.">

							<!--- quick link to populate cc data and offer test modes (dev only) --->
							<cfif 1>
								<A href="javascript:;" onClick="document.f.ccNum.value='4111 1111 1111 1111';document.f.ccv.value='666'" title="Populates credit card data for testing">Fill CC Data</a>

								<select name="selecttestmode">
									<option value="CODE">Code test</option>
									<option value="TESTD">TEST Decline</option>
									<option value="TESTA">TEST Approve</option>
									<option value="REAL">REAL Transaction</option>
								</select>

							</cfif>

						</td>
					</TR>
				<cfelse>
					<input type="hidden" name="ccNum" value="">
					<input type="hidden" name="ccExp" value="">
					<input type="hidden" name="ccv" value="">
				</cfif>

				<TR>
					<TD colspan="99" align="right">
						Preparation for purchase is now complete. To finish, click the Finish button below to finalize purchase.
					</td>
				</TR>
				<TR>
					<TD colspan="99" align="right">
						<input type="button" value="Go Back" onClick="history.go(-1)">
						<input name="finish" type="submit" value="Finish Checkout">
					</td>
				</TR>
			</table>

		</td>
	</tr>
</cfif>

</table>

<cfset PaymentSequence = PaymentSequence + 1>
<input type="hidden" name="PaymentSequence" value="#PaymentSequence#">

</cfoutput>

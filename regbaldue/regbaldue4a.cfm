<!---<cfparam name="form.othercreditused" default="0">
<cfparam name="form.othercreditcardid" default="0">
--->
				<cfif form.othercreditcardid gt 0>

					<cfquery datasource="#application.dopsds#ro" name="GetOCCard">
						select   cardid,
						         cardname,
						         isfa,
						         activated,
						         valid,
						         dops.getavailableocfunds(
						         	<cfqueryparam value="#form.otherCreditCardID#" cfsqltype="cf_sql_integer" list="no">,
						         	<cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">,
						         	<cfqueryparam value="#form.amountdue#" cfsqltype="cf_sql_numeric" scale="2" list="no">,
						         	<cfqueryparam value="#form.netdue#" cfsqltype="cf_sql_numeric" scale="2" list="no"> ) as sumnet,
						         othercreditdata,
						         othercreditdesc
						from     dops.othercredithistorysums
						where    cardid = <cfqueryparam value="#form.otherCreditCardID#" cfsqltype="cf_sql_integer" list="no">
					</cfquery>

					<cf_cryp type="de" string="#GetOCCard.othercreditdata#" key="#key#">
					<cfset abbreviateoccardnumber = cryp.value>
					<cfset abbreviateoccardnumber = left( variables.abbreviateoccardnumber, 4 ) & "..." & right( variables.abbreviateoccardnumber, 4 )>
					<cfset runningoc = min( GetOCCard.sumnet, form.otherCreditUsed )>
					<cfset runningoc = min( variables.runningOC, GetOCCard.sumnet )>
				<cfelse>
					<!--- simulate card used --->
					<cfset GetOCCard.cardid = 0>
					<cfset GetOCCard.cardname = "">
					<cfset GetOCCard.isfa = false>
					<cfset GetOCCard.activated = true>
					<cfset GetOCCard.valid = true>
					<cfset GetOCCard.sumnet = 0>
					<cfset GetOCCard.othercreditdata = "">
					<cfset GetOCCard.othercreditdesc = "">
					<cfset runningoc = 0>
				</cfif>

				<CFSET startbalance = GetAccountBalance( cookie.uID )>
				<cfset creditUsed = min( form.startingbalance, form.amountDue )>
				<cfset runningcredit = variables.creditUsed>
				<cfset runningtx = 0>

				<cfquery datasource="#application.reg_dsn#" name="GetSessionPatrons">
					-- init payment forms
					update   dops.sessionregconvert
					set
						dcused = <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">,
						dcmfused = <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">,
						ocused = <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">,
						ocmfused = <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">,
						txused = <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">,
						txmfused = <cfqueryparam value="0" cfsqltype="cf_sql_money" list="no">
					where   sessionregconvert.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
					;

					-- get patrons
					select   reg.patronid,

					<cfif form.othercreditcardid gt 0 and GetOCCard.isfa>
						(	select   sessionavailablefa
							from     dops.patronrelations
							where    primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
							and      secondarypatronid = reg.patronid ) as oclimit
					<cfelse>
						         9999999999 as oclimit
					</cfif>

					from     dops.sessionregconvert
					         INNER JOIN dops.reg reg ON sessionregconvert.primarypatronid=reg.primarypatronid AND sessionregconvert.regid=reg.regid
					group by reg.patronid
					order by reg.patronid
				</cfquery>

				<cfif 0>
					<cfdump var="#GetSessionPatrons#">
				</cfif>

				<cfquery datasource="#application.reg_dsn#" name="GetCurrentRegistrationsConversions">
					SELECT   sessionregconvert.*,
					         patrons.patronid, (

						-- balance
						select   balance
						from     dops.reghistory
						where    reghistory.primarypatronid = sessionregconvert.primarypatronid
						and      reghistory.regid = sessionregconvert.regid
						and      reghistory.depositonly
						and      not reghistory.depositbalpaid ) as balance
						-- end balance

					FROM     dops.sessionregconvert
					         INNER JOIN dops.reg ON sessionregconvert.primarypatronid=reg.primarypatronid AND sessionregconvert.regid=reg.regid
					         INNER JOIN dops.patrons ON reg.patronid=patrons.patronid
					WHERE    sessionregconvert.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
					ORDER BY sessionregconvert.pk
				</cfquery>

				<cfif 0>
					<cfdump var="#GetCurrentRegistrationsConversions#" label="before cost updates">
				</cfif>

				<cfset runningDC = form.districtCreditUsed>
				<cfset runningOC = min( form.otherCreditUsed, GetOCCard.sumnet )>
				<cfset runningTX = form.netdue>

				<cfif GetCurrentRegistrationsConversions.recordcount gt 0>

					<!--- loop over conversions and assign dc --->
					<cfif form.districtCreditUsed gt 0>

						<!---<cfloop query="GetSessionPatrons">--->
							<!--- GetCurrentRegistrationsConversions loop --->
							<cfloop query="GetCurrentRegistrationsConversions">

<cfif GetCurrentRegistrationsConversions.converttodeposit>
								<cfset t = min( variables.runningDC, GetCurrentRegistrationsConversions.depositamount )>
								<cfset runningDC = variables.runningDC - variables.t>

								<cfif variables.t gt 0>
									<cfset QuerySetCell( GetCurrentRegistrationsConversions, "depositamount", GetCurrentRegistrationsConversions.depositamount - variables.t, GetCurrentRegistrationsConversions.currentrow )>

									<cfquery datasource="#application.reg_dsn#" name="UpdateConversionDC">
										update dops.sessionregconvert
										set
											dcused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
										where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
									</cfquery>

								</cfif>

								<cfset t = min( variables.runningDC, GetCurrentRegistrationsConversions.depositamount )>
								<cfset runningDC = variables.runningDC - variables.t>

<cfelse>
								<cfset t = min( variables.runningDC, GetCurrentRegistrationsConversions.classcost )>
								<cfset runningDC = variables.runningDC - variables.t>

								<cfif variables.t gt 0>
									<cfset QuerySetCell( GetCurrentRegistrationsConversions, "classcost", GetCurrentRegistrationsConversions.classcost - variables.t, GetCurrentRegistrationsConversions.currentrow )>

									<cfquery datasource="#application.reg_dsn#" name="UpdateConversionDC">
										update dops.sessionregconvert
										set
											dcused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
										where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
									</cfquery>

								</cfif>

								<cfset t = min( variables.runningDC, GetCurrentRegistrationsConversions.miscfee )>
								<cfset runningDC = variables.runningDC - variables.t>

								<cfif variables.t gt 0>
									<cfset QuerySetCell( GetCurrentRegistrationsConversions, "miscfee", GetCurrentRegistrationsConversions.miscfee - variables.t, GetCurrentRegistrationsConversions.currentrow )>

									<cfquery datasource="#application.reg_dsn#" name="UpdateConversionDCMF">
										update dops.sessionregconvert
										set
											dcmfused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
										where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
									</cfquery>

								</cfif>

</cfif>
							</cfloop>
							<!--- end GetCurrentRegistrationsConversions loop --->

						<!---</cfloop>--->

					</cfif>
					<!--- end loop over conversions and assign dc --->



					<!--- loop over conversions and assign oc --->
					<cfif form.otherCreditCardID gt 0>

						<cfloop query="GetCurrentRegistrationsConversions">

<cfif GetCurrentRegistrationsConversions.converttodeposit>
								<cfset t = min( variables.runningOC, GetCurrentRegistrationsConversions.depositamount )>
								<cfset runningOC = variables.runningOC - variables.t>

								<cfif variables.t gt 0>
									<cfset QuerySetCell( GetCurrentRegistrationsConversions, "depositamount", GetCurrentRegistrationsConversions.depositamount - variables.t, GetCurrentRegistrationsConversions.currentrow )>

									<cfquery datasource="#application.reg_dsn#" name="UpdateConversionOC">
										update dops.sessionregconvert
										set
											ocused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
										where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
									</cfquery>

								</cfif>
								<cfset t = min( variables.runningOC, GetCurrentRegistrationsConversions.depositamount )>
								<cfset runningOC = variables.runningOC - variables.t>

<cfelse>
							<cfset t = min( variables.runningOC, GetCurrentRegistrationsConversions.classcost )>

							<cfif form.otherCreditCardID gt 0 and GetOCCard.isfa and variables.t gt 0>

								<cfloop query="GetSessionPatrons">

									<cfif GetCurrentRegistrationsConversions.patronid eq GetSessionPatrons.patronid>
										<cfset t = min( variables.t, GetSessionPatrons.oclimit )>
										<cfset QuerySetCell( GetSessionPatrons, "oclimit", GetSessionPatrons.oclimit - variables.t, GetSessionPatrons.currentrow )>
									</cfif>

								</cfloop>

							</cfif>

							<cfset runningOC = variables.runningOC - variables.t>

							<cfif variables.t gt 0>
								<cfset QuerySetCell( GetCurrentRegistrationsConversions, "classcost", GetCurrentRegistrationsConversions.classcost - variables.t, GetCurrentRegistrationsConversions.currentrow )>

								<cfquery datasource="#application.reg_dsn#" name="UpdateConversionOC">
									update dops.sessionregconvert
									set
										ocused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
									where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
								</cfquery>

							</cfif>

							<cfset t = min( variables.runningOC, GetCurrentRegistrationsConversions.miscfee )>

							<cfif form.otherCreditCardID gt 0 and GetOCCard.isfa and variables.t gt 0>

								<cfloop query="GetSessionPatrons">

									<cfif GetCurrentRegistrationsConversions.patronid eq GetSessionPatrons.patronid>
										<cfset t = min( variables.t, GetSessionPatrons.oclimit )>
										<cfset QuerySetCell( GetSessionPatrons, "oclimit", GetSessionPatrons.oclimit - variables.t, GetSessionPatrons.currentrow )>
									</cfif>

								</cfloop>

							</cfif>

							<cfset runningOC = variables.runningOC - variables.t>

							<cfif variables.t gt 0>
								<cfset QuerySetCell( GetCurrentRegistrationsConversions, "miscfee", GetCurrentRegistrationsConversions.classcost - variables.t, GetCurrentRegistrationsConversions.currentrow )>

								<cfquery datasource="#application.reg_dsn#" name="UpdateConversionOCMF">
									update dops.sessionregconvert
									set
										ocmfused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
									where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
								</cfquery>

							</cfif>
</cfif>
						</cfloop>

					</cfif>
					<!--- end loop over conversions and assign oc --->



					<!--- loop over conversions and assign tx --->
					<cfif form.netdue gt 0>

						<cfloop query="GetCurrentRegistrationsConversions">
<cfif GetCurrentRegistrationsConversions.converttodeposit>
								<cfset t = min( variables.runningTX, GetCurrentRegistrationsConversions.depositamount )>
								<cfset runningTX = variables.runningTX - variables.t>

								<cfif variables.t gt 0>
									<cfset QuerySetCell( GetCurrentRegistrationsConversions, "depositamount", GetCurrentRegistrationsConversions.depositamount - variables.t, GetCurrentRegistrationsConversions.currentrow )>

									<cfquery datasource="#application.reg_dsn#" name="UpdateConversionTX">
										update dops.sessionregconvert
										set
											txused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
										where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
									</cfquery>

								</cfif>
								<cfset t = min( variables.runningTX, GetCurrentRegistrationsConversions.depositamount )>
								<cfset runningTX = variables.runningTX - variables.t>

<cfelse>
							<cfset t = min( variables.runningTX, GetCurrentRegistrationsConversions.classcost )>
							<cfset runningTC = variables.runningTX - variables.t>

							<cfif variables.t gt 0>
								<cfset QuerySetCell( GetCurrentRegistrationsConversions, "classcost", GetCurrentRegistrationsConversions.classcost - variables.t, GetCurrentRegistrationsConversions.currentrow )>

								<cfquery datasource="#application.reg_dsn#" name="UpdateConversionTX">
									update dops.sessionregconvert
									set
										txused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
									where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
								</cfquery>

							</cfif>

							<cfset t = min( variables.runningTX, GetCurrentRegistrationsConversions.miscfee )>
							<cfset runningTX = variables.runningTX - variables.t>

							<cfif variables.t gt 0>
								<cfset QuerySetCell( GetCurrentRegistrationsConversions, "miscfee", GetCurrentRegistrationsConversions.miscfee - variables.t, GetCurrentRegistrationsConversions.currentrow )>

								<cfquery datasource="#application.reg_dsn#" name="UpdateConversionTXMF">
									update dops.sessionregconvert
									set
										txmfused = <cfqueryparam value="#variables.t#" cfsqltype="cf_sql_money" list="no">
									where  pk = <cfqueryparam value="#GetCurrentRegistrationsConversions.pk#" cfsqltype="cf_sql_integer" list="no">
								</cfquery>

							</cfif>
</cfif>

						</cfloop>

					</cfif>
					<!--- end loop over conversions and assign tx --->

				</cfif>


				<cfquery datasource="#application.reg_dsn#" name="GetCurrentRegistrationsConversions">
					SELECT   sessionregconvert.*,
					         terms.termname,
					         patrons.patronid,
					         patrons.lastname,
					         patrons.firstname,
					         patrons.middlename,
					         reg.termid,
					         reg.facid,
					         reg.classid,
					         classes.description,
					         facilities.name as facname,
					         isdeposit and ispayingbalance as depositmode
					FROM     dops.sessionregconvert sessionregconvert
					         INNER JOIN dops.reg reg ON sessionregconvert.primarypatronid=reg.primarypatronid AND sessionregconvert.regid=reg.regid
					         INNER JOIN dops.terms terms ON reg.termid=terms.termid AND reg.facid=terms.facid
					         INNER JOIN dops.patrons patrons ON reg.patronid=patrons.patronid
					         INNER JOIN dops.classes classes ON reg.termid=classes.termid AND reg.facid=classes.facid AND reg.classid=classes.classid
					         INNER JOIN dops.facilities facilities ON reg.facid=facilities.facid
					WHERE    sessionregconvert.primarypatronid = <cfqueryparam value="#cookie.uid#" cfsqltype="cf_sql_integer" list="no">
					ORDER BY sessionregconvert.pk
				</cfquery>

				<cfif 0>
					<cfdump var="#GetCurrentRegistrationsConversions#">
				</cfif>

				<cfloop query="GetCurrentRegistrationsConversions">

					<cfif GetCurrentRegistrationsConversions.converttodeposit>

						<cfif dollarRound( dcused + dcmfused + ocused + ocmfused + txused + txmfused ) neq dollarRound( GetCurrentRegistrationsConversions.depositamount )>
							<CFSET message = "ERROR: Payment forms did not add up to expected value.">
							<CFINCLUDE template="includes/layout.cfm">
							<cfabort>
						</cfif>

					<cfelse>

						<cfif dollarRound( dcused + dcmfused + ocused + ocmfused + txused + txmfused ) neq dollarRound( classcost + miscfee )>
							<CFSET message = "ERROR: Payment forms did not add up to expected value.">
							<CFINCLUDE template="includes/layout.cfm">
							<cfabort>
						</cfif>

					</cfif>

				</cfloop>



				<cfset totalOCUsed = 0>
				<!---<cfset netDue = 0>--->

				<cfloop query="GetCurrentRegistrationsConversions">

					<CFIF Isdefined("form.reg#GetCurrentRegistrationsConversions.regid#_bal")>
						<CFSET thestyle = "boldtext">
					<CFELSE>
						<CFSET thestyle = "bodytext3">
					</CFIF>

					<cfif form.otherCreditUsed gt 0>
						<!---<cfset a = min( variables.runningoc, GetCurrentRegistrationsConversions.classcost + GetCurrentRegistrationsConversions.miscfee )>--->
						<!---<input type="hidden" name="OCALL#GetCurrentRegistrationsConversions.pk#" value="0">--->
						<!---<cfset runningoc = variables.runningoc - variables.a>--->
						<cfset totalOCUsed = variables.totalOCUsed + GetCurrentRegistrationsConversions.ocused + GetCurrentRegistrationsConversions.ocmfused>
						<!---<TD align="right">#decimalformat( GetCurrentRegistrationsConversions.ocused + GetCurrentRegistrationsConversions.ocmfused )#</TD>--->
					</cfif>


				</cfloop>

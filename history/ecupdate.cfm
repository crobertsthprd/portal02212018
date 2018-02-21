<!--- need to check an make sure each section has something entered --->


<CFSETTING showdebugoutput="false">

<!--- need better security --->
<CFSILENT>
</CFSILENT>
<cfif cookie.loggedin is not 'yes'>
     <cflocation url="../index.cfm?msg=3">
     <cfabort>
</cfif>

<!--- START FORM PROCESSING --->
<!--- 
notes: each patron has their own primary/patron entries, thus are insulated from any other primary retain actual user login as "webuser" to be processed where specified
 --->

<CFSET dopsds = "dopsds">
<CFSET primaryPatronID = cookie.uid>
<CFSET inputcolor = "">
<!--- set web userid --->
<cfquery name="getUserID" datasource="#dopsds#ro">
SELECT patronid from patrons where patronlookup = <cfqueryparam value="#cookie.ulogin#" cfsqltype="cf_sql_varchar" list="no">
</cfquery>
<CFIF getUserID.recordcount NEQ 1>
     Could not find patron id.
     <CFABORT>
     <CFELSE>
     <CFSET webuser = getUserID.patronid>
</CFIF>

<!--- FORMAT for encoding query string: <CFSET thestring = urlencodedformat(tobase64(encrypt("id=10&recordid=1000","mykey")))> --->
<!--- METHOD for decoding encoded query string: <CFSET string = decrypt(tostring(tobinary(thestring)),"mykey")> --->

<CFPARAM name="url.q" default="false">
<CFPARAM name="form.update" default="false">
<!--- for form checkbox --->
<CFPARAM name="form.pickup" default="false">

<!--- this section decodes the query string and extract passed values --->
<CFIF url.q NEQ "false">
     <CFTRY>
          <CFSET string = decrypt(tostring(tobinary(url.q)),"mykey")>
          <CFLOOP from="1" to="#listlen(string,'&')#" index="i">
               <CFSET parampair = listgetat(string,i,"&")>
               <CFSET "#listfirst(parampair,'=')#" = listlast(parampair,"=")>
          </CFLOOP>
          <CFCATCH>
               <CFOUTPUT>#string#</CFOUTPUT>error reading data
               <CFDUMP var="#cfcatch#">
               <CFABORT>
          </CFCATCH>
     </CFTRY>
</CFIF>
<CFPARAM name="type" default="none">
<CFPARAM name="recordid" default="0">
<CFPARAM name="selectedpatronid" default="0">




<CFIF form.update EQ true>
     <CFIF listfirst(getfilefrompath(cgi.HTTP_REFERER),"?") NEQ getfilefrompath(cgi.script_name)>
          Line 188
          <CFABORT>
     </CFIF>
     <CFSET selectedpatronid = form.patronid>
     <!--- check referring page --->
     <CFIF listfirst(getfilefrompath(cgi.HTTP_REFERER),"?") NEQ getfilefrompath(cgi.script_name)>
          incorrect referring page - line 31
          <CFABORT>
     </CFIF>
     <CFIF form.updateaction EQ "confirmcurrent">
     	<CFIF NOT IsDefined("form.medCurrent") OR form.medcurrent NEQ "true">
          	<CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=3">
          <CFELSE>
          	<cfset didchangeemergencydata = 1>
          	<CFSET confirmmessage = "Information updated as current.">
          </CFIF>
     </CFIF>
     
     <CFIF form.updateaction EQ "gradelevel">
          <cfquery name="updateGradeData" datasource="#dopsds#">
               update dops.prgrade
               set
                    dropdt = now(),
                    webdropuserid = <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">
               where  patronid = <cfqueryparam value="#form.patronid#" cfsqltype="cf_sql_integer" list="yes">
               and    primarypatronid = <cfqueryparam value="#form.primaryPatronID#" cfsqltype="cf_sql_integer" list="no">
               and    dropdt is null
               ;
               insert into dops.prgrade
                    ( primarypatronid,
                    patronid,
                    grade,
                    webadduserid )
               values
                    ( <cfqueryparam value="#form.primaryPatronID#" cfsqltype="cf_sql_integer" list="no">,
                    <cfqueryparam value="#form.patronid#" cfsqltype="cf_sql_integer" list="yes">,
                    <cfqueryparam value="#form.selectgrade#" cfsqltype="cf_sql_varchar" list="no" maxlength="2">,
                    <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no"> )
          </cfquery>
          <cfquery name="updateSwimLevel" datasource="#dopsds#">
               update dops.prswim
               set
                    dropdt = now(),
                    webdropuserid = <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">
               where  patronid = <cfqueryparam value="#form.patronid#" cfsqltype="cf_sql_integer" list="yes">
               and    primarypatronid = <cfqueryparam value="#form.primaryPatronID#" cfsqltype="cf_sql_integer" list="no">
               and    dropdt is null
               ;
               insert into dops.prswim
                    ( primarypatronid,
                    patronid,
                    swimlevel,
                    webadduserid )
               values
                    ( <cfqueryparam value="#form.primaryPatronID#" cfsqltype="cf_sql_integer" list="no">,
                    <cfqueryparam value="#form.patronid#" cfsqltype="cf_sql_integer" list="yes">,
                    <cfqueryparam value="#form.selectswimlevel#" cfsqltype="cf_sql_varchar" list="no" maxlength="1">,
                    <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no"> )
          </cfquery>
          <CFSET confirmmessage = "Grade and level information successfully updated.">
     </CFIF>
     <CFIF form.updateaction EQ "addEC">
     
     <!--- VALIDATION --->
          <cfif not IsDefined( "form.emer" )>
          <CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=4">    
          </cfif>
          
          <cfif not IsDefined( "form.pickup" )>
          <CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=5">    
          </cfif>
          
          <cfif trim(form.contactname1) EQ "">
          <CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=6">   
          </cfif>
     
          <cftransaction action="BEGIN" isolation="REPEATABLE_READ">
               <cfquery name="AddECData" datasource="#dopsds#">
               insert into dops.prec
                    ( primarypatronid,
                    patronid,
                    contactname,
                    relationship,
                    emer,
                    phone1,
                    phone2,
                    pickup,
                    webadduserid )
               values
                    ( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
                    <cfqueryparam value="#patronid#" cfsqltype="cf_sql_integer" list="no">,
                    <cfqueryparam value="#contactname1#" cfsqltype="cf_sql_varchar" list="no">,
     
                    <cfif ltrim( rtrim( relationship1 ) ) eq "">
                         null,
                    <cfelse>
                         <cfqueryparam value="#ltrim( rtrim( relationship1 ) )#" cfsqltype="cf_sql_varchar" list="no">,
                    </cfif>
     
     			<cfqueryparam value="#form.emer#" cfsqltype="cf_sql_bit" list="no">,
     
                    <cfif ltrim( rtrim( phone11 ) ) eq "">
                         null,
                    <cfelse>
                         <cfqueryparam value="#ltrim( rtrim( phone11 ) )#" cfsqltype="cf_sql_varchar" list="no">,
                    </cfif>
     
                    <cfif ltrim( rtrim( phone12 ) ) eq "">
                         null,
                    <cfelse>
                         <cfqueryparam value="#ltrim( rtrim( phone12 ) )#" cfsqltype="cf_sql_varchar" list="no">,
                    </cfif>
                    
                    <cfqueryparam value="#form.pickup#" cfsqltype="cf_sql_bit" list="no">,
     
                    <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no"> )
		</cfquery>
               <CFSET confirmmessage = "Emergency Contact successfully added.">
               <cfset didchangeemergencydata = 1>
          </cftransaction>
          <CFELSEIF form.updateaction EQ "updateEC">
          
          <!--- VALIDATION --->
          <cfif not IsDefined( "form.emer" )>
          <CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=4">    
          </cfif>
          
          <cfif not IsDefined( "form.pickup" )>
          <CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=5">    
          </cfif>
          
          <cfif trim(form.contactname1) EQ "">
          <CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=6">   
          </cfif>
          
          <cftransaction action="BEGIN" isolation="REPEATABLE_READ">
               <cfquery name="DeleteecData" datasource="#dopsds#">
				update dops.prec
				set
					dropdt = now(),
					webdropuserid = <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">
				where  pk in ( <cfqueryparam value="#form.recordid#" cfsqltype="cf_sql_integer" list="yes"> )
				and    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>
               <cfquery name="updateECData" datasource="#dopsds#">
               insert into dops.prec
                    ( primarypatronid,
                    patronid,
                    contactname,
                    relationship,
                    emer,
                    phone1,
                    phone2,
                    pickup,
                    webadduserid )
               values
                    ( <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
                    <cfqueryparam value="#patronid#" cfsqltype="cf_sql_integer" list="no">,
                    <cfqueryparam value="#contactname1#" cfsqltype="cf_sql_varchar" list="no">,
     
                    <cfif ltrim( rtrim( relationship1 ) ) eq "">
                         null,
                    <cfelse>
                         <cfqueryparam value="#ltrim( rtrim( relationship1 ) )#" cfsqltype="cf_sql_varchar" list="no">,
                    </cfif>
                    
                    <cfqueryparam value="#form.emer#" cfsqltype="cf_sql_bit" list="no">,
     
                    <cfif ltrim( rtrim( phone11 ) ) eq "">
                         null,
                    <cfelse>
                         <cfqueryparam value="#ltrim( rtrim( phone11 ) )#" cfsqltype="cf_sql_varchar" list="no">,
                    </cfif>
     
                    <cfif ltrim( rtrim( phone12 ) ) eq "">
                         null,
                    <cfelse>
                         <cfqueryparam value="#ltrim( rtrim( phone12 ) )#" cfsqltype="cf_sql_varchar" list="no">,
                    </cfif>
     			
                    <!---
                    <cfif ltrim( rtrim( phone13 ) ) eq "">
                         null,
                    <cfelse>
                         <cfqueryparam value="#ltrim( rtrim( phone13 ) )#" cfsqltype="cf_sql_varchar" list="no">,
                    </cfif>
                    --->
                    <cfqueryparam value="#form.pickup#" cfsqltype="cf_sql_bit" list="no">,
     
                    <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no"> )
		</cfquery>
               <CFSET confirmmessage = "Emergency Contact successfully updated.">
               <cfset didchangeemergencydata = 1>
          </cftransaction>
          <CFELSEIF form.updateaction EQ "updatePI">
          <!--- ADD VALIDATION --->
          <cfquery name="PutPhysicianData" datasource="#dopsds#">
						update dops.prpd
						set
							dropdt = now(),
							webdropuserid = <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">
						where  primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
						and    patronid = <cfqueryparam value="#form.patronid#" cfsqltype="cf_sql_integer" list="no">
						and    dropdt is null
						;
						insert into dops.prpd
							( primarypatronid,
							patronid,
							physicianname,
							physicianphone,
							prefhospital,
							healthinsurance,
							healthinsurancegroup,
							dentistname,
							dentistphone,
							webadduserid )
						values
							( <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#form.patronid#" cfsqltype="cf_sql_integer" list="no">,
							<cfif form.physicianname eq "">null<cfelse><cfqueryparam value="#form.physicianname#" cfsqltype="cf_sql_varchar" list="no"></cfif>,
							<cfif form.physicianphone eq "">null<cfelse><cfqueryparam value="#form.physicianphone#" cfsqltype="cf_sql_varchar" list="no"></cfif>,
							<cfif form.hospital eq "">null<cfelse><cfqueryparam value="#form.hospital#" cfsqltype="cf_sql_varchar" list="no"></cfif>,
							<cfif form.insurance eq "">null<cfelse><cfqueryparam value="#form.insurance#" cfsqltype="cf_sql_varchar" list="no"></cfif>,
							<cfif form.groupnumber eq "">null<cfelse><cfqueryparam value="#form.groupnumber#" cfsqltype="cf_sql_varchar" list="no"></cfif>,
							<cfif form.dentistname eq "">null<cfelse><cfqueryparam value="#form.dentistname#" cfsqltype="cf_sql_varchar" list="no"></cfif>,
							<cfif form.dentistphone eq "">null<cfelse><cfqueryparam value="#form.dentistphone#" cfsqltype="cf_sql_varchar" list="no"></cfif>,
							<cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no"> )
					</cfquery>
          <CFSET confirmmessage = "Physician & Insurance Information have been updated.">
          <cfset didchangeemergencydata = 1>
          <CFELSEIF form.updateaction EQ "updateMPI">
          <!--- ADD VALIDATION --->
                         <cfif not IsDefined( "form.waiverMPI" ) OR form.waiverMPI NEQ true> 
              <CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=2">
          </cfif>
			
			<cfif not IsDefined( "form.allergies" ) or 
			not IsDefined( "form.adhd" ) or
			not IsDefined( "form.autism" ) or
			not IsDefined( "form.seizures" ) or
			not IsDefined( "form.hepatitis" ) or
			not IsDefined( "form.diabetes" ) or
			not IsDefined( "form.heart" ) or
			not IsDefined( "form.asthma" ) or
			not IsDefined( "form.hernia" ) or
			not IsDefined( "form.concussion" ) or
			not IsDefined( "form.glasses" ) or
			not IsDefined( "form.hcontacts" ) or
			not IsDefined( "form.scontacts" ) or
			not IsDefined( "form.thprdmeds" ) or
			trim(form.medhistory) eq "">
               
               
               	
              <CFLOCATION url="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=landing&selectedpatronid=#form.patronid#','mykey')))#&errormessage=1">    
          </cfif>
          
          

          <!--- get last pk to compare later --->
          <cfquery name="GetLastPK" datasource="#dopsds#">
						select   pk
						from     dops.prmp
						WHERE    primarypatronid = <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
						AND      patronid = <cfqueryparam value="#form.patronid#" cfsqltype="cf_sql_integer" list="no">
						and      dropdt is null
						order by pk desc
						limit    1
					</cfquery>
          <cfquery name="GetNextPK" datasource="#dopsds#">
						select   nextval( 'dops.prmp_pk_seq' ) as t
					</cfquery>
          <cfquery name="PutMedicalData" datasource="#dopsds#">
						insert into dops.prmp
							( pk,
							primarypatronid,
							patronid,
							webadduserid,
							allergies,
							adhd,
							autism,
							seizures,
							hepatitis,
							diabetes,
							heart,
							asthma,
							hernia,
							concussion,
							glasses,
							hcontacts,
							scontacts,
							homemeds,
							thprdmeds,
							meddetails,
							medhistory,
							adaptations,
							immunizations,
							tetanusdate )
						values
							( <cfqueryparam value="#GetNextPK.t#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#patronid#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">,
							<cfqueryparam value="#form.allergies#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.adhd#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.autism#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.seizures#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.hepatitis#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.diabetes#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.heart#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.asthma#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.hernia#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.concussion#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.glasses#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.hcontacts#" cfsqltype="cf_sql_bit" list="no">,
							<cfqueryparam value="#form.scontacts#" cfsqltype="cf_sql_bit" list="no">,

							<cfif IsDefined("form.homemeds")>
								<cfqueryparam value="#form.homemeds#" cfsqltype="cf_sql_bit" list="no">,
							<cfelse>
								null,
							</cfif>

							<cfif ltrim( rtrim( form.thprdmeds ) ) neq "">
								<cfqueryparam value="#form.thprdmeds#" cfsqltype="cf_sql_bit" list="no">,
							<cfelse>
								null,
							</cfif>

							<cfif IsDefined("form.meddetails") and ltrim( rtrim( form.meddetails ) ) neq "">
								<cfqueryparam value="#ltrim( rtrim( meddetails ) )#" cfsqltype="cf_sql_varchar" list="no">,
							<cfelse>
								null,
							</cfif>

							<cfif IsDefined("form.medhistory") and ltrim( rtrim( form.medhistory ) ) neq "">
								<cfqueryparam value="#ltrim( rtrim( form.medhistory ) )#" cfsqltype="cf_sql_varchar" list="no">,
							<cfelse>
								null,
							</cfif>

							<cfif IsDefined("form.adaptations") and ltrim( rtrim( form.adaptations ) ) neq "">
								<cfqueryparam value="#ltrim( rtrim( form.adaptations ) )#" cfsqltype="cf_sql_varchar" list="no">,
							<cfelse>
								null,
							</cfif>

							<cfif IsDefined("form.immunizations")>
								<cfqueryparam value="#form.immunizations#" cfsqltype="cf_sql_bit" list="no">,
							<cfelse>
								null,
							</cfif>

							<cfif IsDate( form.tetanusdate )>
								<cfqueryparam value="#form.tetanusdate#" cfsqltype="cf_sql_date" list="no">
							<cfelse>
								null
							</cfif> )

					</cfquery>
          
          <!--- compare last 2 records to detect if last entry was duplicated --->
          <cfif GetLastPK.recordcount eq 1>
               <cfquery name="CheckForSameAsLastRecord" datasource="#dopsds#">
							SELECT   count(*) as c
							FROM     dops.prmp
							WHERE    primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">
							AND      patronid = <cfqueryparam value="#patronid#" cfsqltype="cf_sql_integer" list="no">
							AND      pk >= <cfqueryparam value="#GetLastPK.pk#" cfsqltype="cf_sql_integer" list="no">
							GROUP BY allergies, adhd, autism, seizures, hepatitis, diabetes, heart, 
							         asthma, hernia, concussion, glasses, hcontacts, scontacts, 
							         immunizations, thprdmeds, meddetails, adaptations, medhistory, 
							         homemeds, tetanusdate
						</cfquery>
               
               <!--- if last 2 are the same, delete new record --->
               <cfif CheckForSameAsLastRecord.c gt 1>
                    <cfquery name="RemoveLastInsertedRecord" datasource="#dopsds#">
								delete from dops.prmp
								where  pk = <cfqueryparam value="#GetNextPK.t#" cfsqltype="cf_sql_integer" list="no">
							</cfquery>
                    <cfelse>
                    <!--- since different, drop previous record --->
                    <cfquery name="UpdatePRMP" datasource="#dopsds#">
								update dops.prmp
								set
									webdropuserid = <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">,
									dropdt = now()
								where  pk = <cfqueryparam value="#GetLastPK.pk#" cfsqltype="cf_sql_integer" list="no">
							</cfquery>
                    <cfset didchangeemergencydata = 1>
               </cfif>
               <cfelse>
               <cfset didchangeemergencydata = 1>
          </cfif>
          <CFSET confirmmessage = "Medical & Physical Information successfully updated.">
     </CFIF>
     <cfif IsDefined("didchangeemergencydata") or isDefined("confirmedemergencydataiscurrent")>
          <cfquery name="updateupdatedt" datasource="#dopsds#">
						update dops.patronrelations
						set
							edupdate = now()
						where  primarypatronid =  <cfqueryparam value="#form.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
						and    secondarypatronid = <cfqueryparam value="#form.patronid#" cfsqltype="cf_sql_integer" list="no">
					</cfquery>
          
         	<cfquery name="getAffectedAlerts" datasource="#dopsds#">
		SELECT   reg.facid,
		         reg.primarypatronid,
		         reg.patronid
		FROM     dops.reg 
		         INNER JOIN dops.classes classes ON reg.termid=classes.termid AND reg.facid=classes.facid AND reg.classid=classes.classid
		WHERE    classes.enddt > now()
		AND      classes.ecrequired
		and      reg.primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">
		group by reg.facid, reg.primarypatronid, reg.patronid
		</cfquery>
          
          	<cfif getAffectedAlerts.recordcount gt 0>

		<cfquery name="updateupdatedt" datasource="#dopsds#">

			<cfloop query="getAffectedAlerts">
				delete from dops.ecchange
				where  facid = <cfqueryparam value="#getAffectedAlerts.facid#" cfsqltype="cf_sql_varchar" list="no">
				and    primarypatronid = <cfqueryparam value="#getAffectedAlerts.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
				and    patronid = <cfqueryparam value="#getAffectedAlerts.patronid#" cfsqltype="cf_sql_integer" list="no">
				;

				insert into dops.ecchange
					( facid, 
					primarypatronid, 
					patronid )
				values
					( <cfqueryparam value="#getAffectedAlerts.facid#" cfsqltype="cf_sql_varchar" list="no">,
					<cfqueryparam value="#getAffectedAlerts.primarypatronid#" cfsqltype="cf_sql_integer" list="no">,
					<cfqueryparam value="#getAffectedAlerts.patronid#" cfsqltype="cf_sql_integer" list="no"> )
				;
			</cfloop>

		</cfquery>

	</cfif>
          
          <CFLOCATION url="#script_name#?type=landing&selectedpatronid=#form.patronid#&confirmmessage=#urlencodedformat(confirmmessage)#">
          
          
     </cfif>
</cfIF>
<CFIF type EQ "deleteEC">
     <!--- delete contact --->
     <cfquery name="DeleteecData" datasource="#dopsds#">
				update dops.prec
				set
					dropdt = now(),
					webdropuserid = <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">
				where  pk in ( <cfqueryparam value="#recordid#" cfsqltype="cf_sql_integer" list="yes"> )
				and    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="cf_sql_integer" list="no">
                    and    patronid = <cfqueryparam value="#selectedpatronid#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>
     <cfset didchangeemergencydata = 1>
     <CFSET confirmmessage = "Emergency Contact successfully deleted.">
     
     <!--- delete physician --->
     <cfelseif type EQ "deletepi">
     <cfquery name="delPhysicianData" datasource="#dopsds#">
				update dops.prpd
				set
					dropdt = now(),
					webdropuserid = <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">
				where  pk = <cfqueryparam value="#recordid#" cfsqltype="cf_sql_integer" list="no">
				and    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="cf_sql_integer" list="no">
                    and    patronid = <cfqueryparam value="#selectedpatronid#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>
     <cfset didchangeemergencydata = 1>
     <CFSET confirmmessage = "Physician & Insurance Information successfully deleted.">
     <cfelseif type EQ "deletepi">
     <cfquery name="delMedPhysical" datasource="#dopsds#">
				update dops.prmp
				set
					dropdt = now(),
					webdropuserid = <cfqueryparam value="#webuser#" cfsqltype="cf_sql_integer" list="no">
				where  pk = <cfqueryparam value="#recordid#" cfsqltype="cf_sql_integer" list="no">
				and    primarypatronid = <cfqueryparam value="#cookie.uID#" cfsqltype="cf_sql_integer" list="no">
                    and    patronid = <cfqueryparam value="#selectedpatronid#" cfsqltype="cf_sql_integer" list="no">
			</cfquery>
     <cfset didchangeemergencydata = 1>
     <CFSET confirmmessage = "Medical & Physical Information successfully deleted.">
</cfif>

<!--- END FORM PROCESSING --->

<!--- set mode: editmode=0 (default) means read only, 1 = allow edit --->
<cfparam name="editmode" default="1">
<cfquery name="getHousehold2" datasource="#dopsds#ro">
	SELECT   patronrelations.secondarypatronid as patronid, 
     	    patronrelations.primarypatronid,
	         patrons.firstname,
              patrons.middlename,
	         patrons.lastname, 
              patrons.patronlookup,
              patrons.gender,
	         patronrelations.relationtype, 
	         relationshiptype.relationshipdesc,
	         patronrelations.edupdate
	FROM     dops.patronrelations
	         inner join dops.relationshiptype ON patronrelations.RelationType=relationshiptype.RelationType
	         inner join dops.patrons on patronrelations.secondarypatronid=patrons.patronid
	WHERE    patronrelations.primarypatronid = <cfqueryparam value="#primaryPatronID#" cfsqltype="cf_sql_integer" list="no">
	         
	order by patronrelations.relationtype, patrons.lastname, patrons.firstname
</cfquery>
<CFQUERY name="getHousehold" dbtype="query">
	select * from getHousehold2 where patronid = <cfqueryparam value="#selectedPatronID#" cfsqltype="cf_sql_integer" list="no">
</CFQUERY>

<CFIF getHousehold.recordcount EQ 0>
<CFMAIL to="webadmin@thprd.org" from="webadmin@thprd.org" subject="ec update diagnostics" type="html">
<CFDUMP var="#getHousehold#">
<CFDUMP var="#cgi#">
<CFDUMP var="#form#">
<CFDUMP var="#url#">
<CFDUMP var="#variables#">
</CFMAIL>
</CFIF>

<!--- these are the lookup queries referenced in the include forms --->
<cfquery name="GetGrade" datasource="#dopsds#ro">
	select   *
	from     dops.prgrade
	where    primarypatronid = <cfqueryparam value="#primaryPatronID#" cfsqltype="cf_sql_integer" list="no">
	and      PatronID = <cfqueryparam value="#getHousehold.PatronID#" cfsqltype="cf_sql_integer" list="no">
	and      dropdt is null
	order by adddt desc
	limit    1
</cfquery>
<cfquery name="GetSwim" datasource="#dopsds#ro">
	select   *
	from     dops.prswim
	where    primarypatronid = <cfqueryparam value="#primaryPatronID#" cfsqltype="cf_sql_integer" list="no">
	and      PatronID = <cfqueryparam value="#getHousehold.PatronID#" cfsqltype="cf_sql_integer" list="no">
	and      dropdt is null
	order by adddt desc
	limit    1
</cfquery>

<cfquery name="GetECData" datasource="#dopsds#ro">
          SELECT   *
          FROM     dops.prec
          WHERE    primarypatronid = <cfqueryparam value="#gethousehold.primarypatronid#" cfsqltype="cf_sql_integer" list="no">
          and      patronid = <cfqueryparam value="#getHousehold.patronid#" cfsqltype="cf_sql_integer" list="no">
          and      dropdt is null
          order by contactname,adddt desc
</cfquery>

<!--- look up physicians & insurance; include edit and delete --->
<cfquery name="GetPhysicianData" datasource="#dopsds#ro">
	select   *
	from     dops.prpd
	where    primarypatronid   = <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">
	and      patronid = <cfqueryparam value="#getHousehold.patronid#" cfsqltype="cf_sql_integer" list="no">
	and      dropdt is null
</cfquery>

<cfquery datasource="#dopsds#ro" name="GetMedical">
	select   *
	
     <!---     
	case
		when     homemeds is null then -1
		when     homemeds then 1
		when     not homemeds then 0
	end as truehomemeds,

	case
		when     immunizations is null then -1
		when     immunizations then 1
		when     not immunizations then 0
	end as trueimmunizations
	--->

	from     dops.prmp
	where    primarypatronid = <cfqueryparam value="#primarypatronid#" cfsqltype="cf_sql_integer" list="no">
	and      patronid = <cfqueryparam value="#getHousehold.patronid#" cfsqltype="cf_sql_integer" list="no">
	and      dropdt is null
	order by pk desc
	limit    1
</cfquery>

<CFOUTPUT>
     <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
     <html>
     <head>
     <title>Emergency Contact Information</title>
     <link rel="stylesheet" href="/includes/thprdstyles_min.css">
     </head>
     <body leftmargin="0" topmargin="0">
     <table border="0" cellpadding="0" cellspacing="0" width="750">
               <tr>
          
               <td valign=top>
          
          <table border=0 cellpadding=2 cellspacing=0 width=749>
               <tr>
                    <td colspan=2 class="pghdr"><!--- start header --->
                         
                         <CFINCLUDE template="/portalINC/dsp_header.cfm">
                         
                         <!--- end header ---></td>
                    <tr>
               
               <td valign=top><table border=0 cellpadding=2 cellspacing=0>
                         <tr>
                              <td><img src="/siteimages/spacer.gif" width="130" height="1" border="0" alt=""></td>
                         </tr>
                         <tr>
                              <td valign=top nowrap class="lgnusr"><br>
                                   
                                   <!--- start nav --->
                                   
                                   <cfinclude template="/portalINC/admin_nav_history.cfm">
                                   
                                   <!--- end nav ---></td>
                         </tr>
                    </table></td>
                    <td valign=top class="bodytext" width="100%">
               
               
               <!--- start content ---> 
               
               <!--- Emergency Contact Info ---> 
               <br />
               <div class="pghdr">Emergency Contact / Medical & Physical Information</div>
               <CFIF Isdefined("confirmmessage")>
                    <div style="color:##093;padding:10px;"><b>#confirmmessage#</b></div>
                    <script>alert('#confirmmessage#');</script>
               </CFIF>
               <CFIF Isdefined("errormessage")>
               <CFIF errormessage EQ 1>
               	<CFSET errormessagetext = "One or more required Medical & Physical options were not checked and/or the Medical history was not completed.  Please complete all required fields.">
               <CFELSEIF errormessage EQ 2>
               	<CFSET errormessagetext = "Please acknowledge reading conditions and agree to consent by checking 'I Agree'.">
               <CFELSEIF errormessage EQ 3>
               	<CFSET errormessagetext = "Please check box indicating all information is current.">
               <CFELSEIF errormessage EQ 4>
               	<CFSET errormessagetext = "Please indicate whether submitted contact is an emergency contact.">
               <CFELSEIF errormessage EQ 5>
               	<CFSET errormessagetext = "Please indicate whether submitted contact is authorized to pickup family members from THPRD classes and events.">
               <CFELSEIF errormessage EQ 6>
               	<CFSET errormessagetext = "Please enter full name of emergency contact.">
               </CFIF>
               
                    <br>
                    <span style="background-color:##C00;color:##FFF;padding:2px;"><strong>Error:</strong></span> <b style="color:##C00;">#errormessagetext#</b>
                    <a href="javascript:history.go(-1);"><strong><< Go Back</strong></a><br><br>
               </CFIF>
               <CFLOOP query="getHousehold">
                    <CFINCLUDE template="ec/ecinclude.cfm">
                    <CFINCLUDE template="ec/mpinclude.cfm">
               </CFLOOP>
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
     <CFINCLUDE template="/portalINC/googleanalytics.cfm">
     </html>
</cfoutput>

<!---
<CFDUMP var="#getECData#">
--->
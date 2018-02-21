<cfparam name="url.v" default="L">
	<cfquery name="qCheckContent" datasource="#application.dsn#">
		select ch.ch_expire_date, ch.ch_file_live, ch.ch_file_draft, ch.ch_approved_by, ch.ch_instructions, cd.cd_id, cd.ca_id
		from th_content_history ch, th_content_data cd
		where cd.cd_file_path like <cfif not isdefined('url.p')>'#webpath#%'<cfelse>'#url.path#%'</cfif>
		and cd.cd_status = True
		and cd.cd_site = 1
		and cd.cd_edit = True
		and cd.cd_id = ch.cd_id
		and ch.ch_status = '#url.v#'
	</cfquery>
		<cfquery name="qInsertStamp" datasource="#application.dsn#">
		insert into th_traffic
			(t_page, t_ip, t_tdstamp)
		values
			('#cgi.SCRIPT_NAME#', '#cgi.REMOTE_ADDR#', '#dateformat(now(),'yyyy-mm-dd')# #timeformat(now(),'HH:mm:ss')#')
		</cfquery>

<cfoutput>
<cfparam name="content" default="Please check back soon for more information.">
<!--- the following query is on the includes/top_nav.cfm file --->
<cfif qCheckcontent.recordcount gt 0>

	<cfswitch expression="#url.v#">
		<cfcase value="L">
			<cfif qCheckcontent.ch_expire_date is not ''><!--- has expiration date --->
				<cfif datecompare(qCheckcontent.ch_expire_date,now()) is 1>
					<cfif fileexists('#request.filepath#/dynamiccontent/web/live/#qCheckcontent.ch_file_live#.cfm')>
						<cffile action="read" file="#request.filepath#/dynamiccontent/web/live/#qCheckcontent.ch_file_live#.cfm" variable="content">
					</cfif>
				</cfif>
			<cfelse><!--- no expiration date --->
				<cfif fileexists('#request.filepath#/dynamiccontent/web/live/#qCheckcontent.ch_file_live#.cfm')>
					<cffile action="read" file="#request.filepath#/dynamiccontent/web/live/#qCheckcontent.ch_file_live#.cfm" variable="content">
				</cfif>
			</cfif>
		</cfcase>
		<cfcase value="D,W">
			<!--- get original approvers --->
			<cfquery name="qGetApprovers" datasource="#application.dsn#">
				select cd.ca_id
				from th_content_data cd
				where cd.cd_id = #qCheckContent.cd_id# 
			</cfquery>
			<cfset approvers = "">
			<!--- get list of those who have marked page approved --->
			<cfloop list="#qGetApprovers.ca_id#" index="aID">
				<cfif listfind(qCheckcontent.ch_approved_by,aid) is 0>
					<cfset approvers = listappend(approvers,aID)>
				</cfif>
			</cfloop>
			<cfif listlen(approvers) gt 0><!--- get names of those who need to approve content, if necessary --->
				<cfquery name="qGetNames" datasource="#application.dsn#">
					select u.u_fname, u.u_lname
					from th_users u
					where u.u_uid in (#replacenocase(approvers,'|','','all')#)
				</cfquery>
				<!--- display names and instructions, if necessary--->
				Changes to this page need approved by:<br>
				<strong>
				<cfloop query="qGetNames">
				#u_fname# #u_lname#<br>
				</cfloop>
				</strong>
				<br>
				<cfif qCheckContent.ch_instructions is not ''>
				<strong>Notes from Editor:</strong><br>
				-------------------------------------<br>
				#qCheckContent.ch_instructions#<br>
				-------------------------------------<br><br>
				</cfif>
				
			</cfif>
			<cfif fileexists('#request.filepath#/dynamiccontent/web/draft/#qCheckcontent.ch_file_draft#.cfm')>
				<cffile action="read" file="#request.filepath#/dynamiccontent/web/draft/#qCheckcontent.ch_file_draft#.cfm" variable="content">
			</cfif>	
		</cfcase>
	</cfswitch>
</cfif>
#content#
 </cfoutput>
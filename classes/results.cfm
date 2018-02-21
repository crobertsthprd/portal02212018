<cfif not isdefined('aID')>
	<cflocation url="categories.cfm">
	<cfabort>
</cfif>
<cfoutput>
<html>
<head>
<title>Tualatin Hills Park and Recreation District</title>
<meta http-equiv="Content-Type" content="text/html;">
<link rel="stylesheet" href="/includes/thprdstyles_min.css">
</head>
<body bgcolor="ffffff" topmargin="0" leftmargin="0" marginheight="0" marginwidth="0">
<table border="0" cellpadding="0" cellspacing="0" width="750">
  
  <!--- <cfinclude template="#request.includes#/top_nav.cfm"> --->
  <tr>
   <td colspan="36" valign=top>
      	<table border=0 cellpadding=2 cellspacing=0 width=749>
		<tr>
		<td colspan=5><img src="#request.imagedir#/spacer.gif" width="1" height="35" border="0" alt=""></td>
		</tr>
		<tr>
		<td>&nbsp;</td>
		<td colspan=4>
			<table width="100%">
				<tr>
					<td><span class="pghdr" >Activities/Class Search by Category</span></td>
					<td align="right"><span class="lgnusr" >#cookie.firstname# #cookie.lastname# (#cookie.login#) - <strong>#cookie.districtstatus#</strong></span></td>
				</tr>
			</table>
		</td>
		</tr>		
		<tr>
		<td><img src="../images/spacer.gif" width="20" height="300" border="0" alt=""></td>
		<td valign=top>
			<table border=0 cellpadding=2 cellspacing=0>
			<tr>
			<td><img src="#request.imagedir#/spacer.gif" width="120" height="1" border="0" alt=""></td>
			</tr>
			<tr>
			<td valign=top nowrap><br>
			<a href="showcategories.cfm?aID=0" class="sidenav">Infant/Toddler</a><br>			
			<a href="showcategories.cfm?aID=1" class="sidenav">Preschool</a><br>
			<a href="showcategories.cfm?aID=2" class="sidenav">Youth</a><br>
			<a href="showcategories.cfm?aID=3" class="sidenav">Teen/Adult</a><br>
			<a href="showcategories.cfm?aID=4" class="sidenav">55+ Senior Adults</a><br>
			<a href="showcategories.cfm?aID=6" class="sidenav">Family (All Ages)</a><br>
			<a href="showcategories.cfm?aID=5" class="sidenav">Special Population</a><br>
			</td>
			</tr>		
			</table>		
		</td>
		<td valign=top><img src="../images/spacer.gif" width="5" height="300" border="0" alt=""></td>
		<td valign=top colspan=2 class="bodytext" width="100%">
		<cfif not isdefined('levelchoice') and not isdefined('clevel') and (form.catname is 'aquatics' and (form.subcat is '00' OR form.subcat is '14'))><!--- if true, show level choices --->
			<cfif isdefined('form.subcat')>
				<cfquery name="qGetSubCat" datasource="#application.reg_dsn#">
					select description
					from categoryb
					where code = '#form.subcat#'
				</cfquery>
			</cfif>
			<cfquery name="qGetCat" datasource="#application.reg_dsn#">
				select description
				from categorya
				where code = '#form.cat#'
			</cfquery>
			<cfquery name="qGetLevels" datasource="#application.reg_dsn#">
			select distinct c.categoryb, c.levels, cat.description as category, subcat.description, subcat.code
			from classes c, categorya cat, categoryb subcat, terms t
			where c.agecategory like '%#aID#%'
			and now() >= date(t.startdt) - 40
			and c.status = 'A'
			and c.categorya = '#form.cat#'
			and c.categorya = cat.code
			and c.categoryb = '#form.subcat#'
			and c.categoryb = subcat.code
			and c.facid=t.facid and c.termid=t.termid
			order by subcat.description desc
			</cfquery>
			<cfset levellist = listsort(replacenocase(valuelist(qGetLevels.levels),'-','','all'),'text','asc')>
			<cfset temp = "">
			<cfloop list="#levellist#" index="levelname">
				<cfif temp eq levelname>
					<cfset del = listfindnocase(levellist,levelname)>
					<cfset levellist = listdeleteat(levellist,del)>
				</cfif>
				<cfset temp = levelname>
			</cfloop>
			<br><br>
			<form name="choosecat" action="results.cfm" method="post">
			<table border=0 cellpadding=1 cellspacing=0 width=600>
			<tr>
			<td class="greentext" colspan=7 nowrap>
			<strong>
			#form.agecat#, 
			<cfif qGetCat.description is '--- None ---'>General<cfelse>#qGetCat.description#</cfif><cfif isdefined('form.subcat')>, <cfif qGetSubCat.description is '--- None ---'>General<cfelse>#qGetSubCat.description#</cfif></cfif><br><br>
			</strong>
			</td>
			<td rowspan=3 valign=top align="middle"><br><img src="#application.webimages#/photos/Image/160/people/kids/people69.jpg" border="0"></td>
			</tr>
			<tr>
			<td class="lgnusr" valign="top" nowrap>
			<strong>
			<cfset counter = 1>
			<cfloop list="#levellist#" index="levelname">
				<input type="checkbox" name="clevel" value="%-#levelname#-%">Level #levelname#&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;<br>
				<cfif counter is 5>
					</strong>
					</td>
					<td class="lgnusr" valign="top" nowrap>
					<strong>
					<cfset counter = 0>
				</cfif>
				<cfset counter = counter + 1>
			</cfloop>
			</strong>
			<cfif form.subcat is '00'>
			<input type="checkbox" name="slevel" value="specialty"><strong>Specialty</strong>
			</cfif>
			</td>
			</tr>
			<tr>
			<td colspan=7><br><br><br>
			<input type="submit" name="levelchoice" value="Choose Level(s)" class="form_submit"><br>
			*Leave boxes unchecked to view all classes
			</td>
			</tr>
			</table>
			<input type="hidden" name="SUBCAT" value="#form.SUBCAT#">
			<input type="hidden" name="AID" value="#form.AID#">
			<input type="hidden" name="AGECAT" value="#form.AGECAT#">
			<input type="hidden" name="CAT" value="#form.CAT#">
			<input type="hidden" name="CATNAME" value="#form.CATNAME#">
			</form>
		<cfelse>
			<!--- display results --->
			<cfinclude template="catdisplay.cfm">
		</cfif>
		</td>
   		</tr>
		</table>
   </td>
   <td><img src="#request.imagedir#/spacer.gif" width="1" height="128" border="0" alt=""></td>   
  </tr>
  <tr>
   <td colspan="36" valign="top"><p></p></td>
   <td><img src="#request.imagedir#/spacer.gif" width="1" height="11" border="0" alt=""></td>
  </tr>
  <cfinclude template="../footer.cfm">

</table>
</body>
</html>
</cfoutput>
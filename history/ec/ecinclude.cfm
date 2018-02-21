

<!--- params --->
<CFPARAM name="PIForm" default="false">


<table width="650" border=0 cellpadding=3 cellspacing="0">
     
     <CFSET formactive = false>
     <CFOUTPUT>
     <TR bgcolor="000000">
		<TD colspan="5" style="color:##FFF;font-size:14px;"><strong>#lastname#, #firstname# #middlename# (#patronlookup#) -
                    <cfif gender is "M">
                         Male
                         <cfelseif gender is "F">
                         Female
                    </cfif>
                    <cfif relationshipdesc NEQ "Self">#relationshipdesc#<CFELSE>Primary</cfif></strong></TD>
          </TR>
          
          <tr valign="top" style="background-color:##E0E0E0;">
          	<td colspan="5"><strong>Last Update</strong></td>
          </tr>          
         
         <tr valign="top" style="background-color:##E0E0E0;" >
          <td colspan="5" >
        <table bgcolor="##FFFFFF" width="100%">
         <tr>
         <td align="center">
         
         
         <CFIF getECdata.recordcount EQ 0>
         <div style="color:##C00;margin-bottom:2px;"><strong><strong>Emergency Contact Information</strong> has not been added.</strong>.</div><br>
         <CFELSEIF getPhysiciandata.recordcount EQ 0>
         <div style="color:##C00;margin-bottom:2px;"><strong><strong>Physician & Insurance Information</strong> has not been added.</strong>.</div><br>
         <CFELSEIF getMedical.recordcount EQ 0>
         <div style="color:##C00;margin-bottom:2px;"><strong><strong>Medical & Physical Information</strong> has not been added.</strong>.</div><br>
         <CFELSE>
         <div style="color:##390;margin-bottom:2px;"><strong>Emergency contact information last updated on #DateFormat( gethousehold.edupdate )#</strong>.</div><br>
               <form name="contactcurrent" action="#cgi.script_name#" method="post">
               <input type="hidden" name="update" value="true">
               <input type="hidden" name="updateAction" value="confirmcurrent">
               <input type="hidden" name="primarypatronid" value="#getHousehold.primarypatronid#">
               <input type="hidden" name="patronid" value="#getHousehold.patronid#">
                    <input type="checkbox" name="medCurrent" value="true">
                    All information is current.
                    <input type="submit" value="Confirm all information is current"><br>
                    
               </form>
         </CFIF>
         </td>
         </tr>
         </table>
         </td>
         </tr>
          
         <tr valign="top" ><td colspan="2" style="height:10px;"></td></tr>
          
          <tr valign="top" style="background-color:##E0E0E0;">
          	<td colspan="5"><strong>Levels</strong> | <a href="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=updatelevel&selectedpatronid=#getHousehold.patronid#','mykey')))#">Update</a></td>
          </tr>          
         
         <tr valign="top" style="background-color:##E0E0E0;" >
          <td colspan="5" >
     <CFIF type EQ "updatelevel">
     <table bgcolor="##FFFF99" width="100%">
         <tr>
         <td align="center">

               
               




                    <form method="POST" action="#cgi.script_name#" name="updateLevel">
               <input type="hidden" name="update" value="true">
               <input type="hidden" name="updateAction" value="gradelevel">
               <input type="hidden" name="primarypatronid" value="#getHousehold.primarypatronid#">
               <input type="hidden" name="patronid" value="#getHousehold.patronid#">
                
               <table>
               <tr>
                    
                         
                    <TD align="center"  valign="middle">Grade Level * &nbsp;
                         <select name="selectgrade">
                              <option value="-">---
                              <option value="K" <cfif GetGrade.grade eq "K">selected</cfif>>K</option>
                              <option value="P" <cfif GetGrade.grade eq "P">selected</cfif>>P</option>
                              <option value="-" disabled>---</option>
                              <cfloop from="1" to="16" index="x">
                                   <option value="#x#" <cfif GetGrade.grade eq x>selected</cfif>>#x#</option>
                              </cfloop>
                         </select></TD>
                    <td width="10"></td>
                    <TD  align="center" nowrap valign="middle">Swim Level  &nbsp;
                         <select name="selectswimlevel">
                              <option value="N" <cfif GetSwim.swimlevel eq "N">selected</cfif> > Non-Swimmer</option>
                              <option value="B" <cfif GetSwim.swimlevel eq "B">selected</cfif> > Beginner</option>
                              <option value="A" <cfif GetSwim.swimlevel eq "A">selected</cfif> > Advance Swimmer</option>
                              <option value="-" <cfif GetSwim.swimlevel eq "-" or GetSwim.recordcount eq 0>selected</cfif> > N/A</option>
                         </select></TD>
                    <td width="10"></td>
                    <td valign="middle"><input type="submit" value="Update Grade/Level"></td>
               </TR>
               
               <tr>
               	<td colspan="5">* In May/June, please update grade level for summer classses to the grade child will be entering in the fall. </td>
               </tr>
          </table>
          </form>
          <!---
          <cfif edupdate neq "">
               Emergency contact information last updated on #DateTimeFormat( edupdate )#.<br>
               <form name="contactcurrent" action="#cgi.script_name#" method="post">
                    <input type="checkbox" name="ecCurrent" value="true">
                    All information is current
                    <input type="submit" value="Submit">
               </form>
          </cfif>
		--->
               </td>
         </tr>
         </table>
         
         <CFELSE>
         
         <table bgcolor="##FFFFFF" width="100%">
         <tr>
         <td align="center">

                
               <table>
               <tr>
                    
                         
                    <TD align="center"  valign="middle"><strong>Grade Level</strong>*: &nbsp;
                         #GetGrade.grade#
                            
                         </select></TD>
                    <td width="10"></td>
                    <TD  align="center" nowrap valign="middle"><strong>Swim Level:</strong>  &nbsp;
                         <cfif GetSwim.swimlevel eq "N">Non-Swimmer</cfif>
                              <cfif GetSwim.swimlevel eq "B">Beginner</cfif>
                              <cfif GetSwim.swimlevel eq "A">Advance Swimmer</cfif>
                              <cfif GetSwim.swimlevel eq "-" or GetSwim.recordcount eq 0>N/A</cfif>
                         </TD>
                    <td width="10"></td>
                    <td valign="middle"></td>
               </TR>
               
               <tr>
               	<td colspan="5">* In May/June, please update grade level for summer classses to the grade child will be entering in the fall. </td>
               </tr>
          </table>
          

               </td>
         </tr>
         </table>
         
         </CFIF>
         
         </td>
         </tr>      
               
               </td>
          </tr>
          
         
          
          <tr valign="top" ><td colspan="2" style="height:10px;"></td></tr>
          
          <tr valign="top" style="background-color:##E0E0E0;">
          	<td colspan="5"><strong>Emergency Contact / Pick Up</strong> <CFIF GetECData.recordcount LT 5 and formActive EQ false>
               | <a href="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=addec&selectedpatronid=#getHousehold.patronid#','mykey')))#">Add</a>
          </CFIF></td>
          </tr>
          <tr>
          	<td colspan="5" bgcolor="##E0E0E0">
<!--- if link has been clicked show form to ADD emergency contact to this patron --->
          <CFIF type EQ "addec" >
               <form method="POST" action="#cgi.script_name#" name="addEC">
                    <input type="hidden" name="update" value="true">
                    <input type="hidden" name="updateAction" value="addEC">
                    <input name="patronid" value="#patronid#" type="hidden">
                    <input name="primarypatronid" value="#primarypatronid#" type="hidden">
                    <table  bgcolor="##FFFF99" width="100%">
                         <TR>
                              <TD align="right" style="color:red;font-weight:bold;">Name</TD>
                              <TD><input type="Text" name="contactname1" style="width: 200px;" onChange="this.value=alltrim(this.value)"></TD>
                              
                              

                              <TD nowrap align="right">Phone 1</TD>
                              <TD><input type="Text" name="phone11" style="width: 150px;" onChange="this.value=alltrim(this.value)"></TD>
                                                            <TD style="color:red;font-weight:bold;">Emergency<br />Contact?</TD>
                              <td><input name="emer" type="radio" value="true">
                                   Yes<Br />
                                   <input name="emer" type="radio" value="false">
                                   No
                              </td>
                         </TR>
                         <TR>
                              <TD align="right">Relationship</TD>
                              <TD><input type="Text" name="relationship1" style="width: 150px;" onChange="this.value=alltrim(this.value)"></TD>
                              
                              <TD nowrap align="right">Phone 2</TD>
                              <TD><input type="Text" name="phone12" style="width: 150px;" onChange="this.value=alltrim(this.value)"></TD>
                              
                              <TD style="color:red;font-weight:bold;" >Designate For<br />Pick Up?</TD>
                              <td><input name="pickup" type="radio" value="true">
                                   Yes<Br />
                                   <input name="pickup" type="radio" value="false">
                                   No
                              </td>
                              
                         </TR>
                         <!---
                         <tr>
                              <td colspan="6"  align="center">
                              <br />
                              <table style="border-style:dashed;border-width:1px;border-color:##000;background-color:##FFF;padding:3px;">
                                        <tr>
                                             <td valign="middle"><strong>Include this emergency contact / designated pick-up with<br />the following other household members:</strong> </td>
                                             <td width="10"></td>
                                             <td valign="top" nowrap="nowrap"><CFLOOP query="getHousehold2">
                                                       <input type="checkbox" name="additionalpatronidEC" value="#getHousehold2.patronid#">
                                                       #getHousehold2.firstname# &nbsp;<br />
                                                  </CFLOOP>
                                        </tr>
                                   </table></td>
                         </tr>
					--->
                         <tr><td colspan="6" align="center">
                         <br /><strong style="color:red;">Red text</strong> indicates a response is <strong>required</strong>.<br />
                         <input type="submit" value="Add Emergency Contact / Designated Pick-Up"></td></tr>
                    </table>
               </form>
               <CFSET formactive = true>
          </CFIF>
<!--- if link has been clicked show form to EDIT emergency contact to this patron --->
          <CFIF type EQ "editec" and selectedpatronid EQ getHousehold.patronid>
          
          <CFQUERY name="thisECData" dbtype="query">
          	select * from getECData where pk = <CFQUERYPARAM cfsqltype="cf_sql_numeric" value="#recordid#">
          </CFQUERY>
          
               <form method="POST" action="#cgi.script_name#" name="updateEC">
                    <input type="hidden" name="update" value="true">
                    <input type="hidden" name="updateAction" value="updateEC">
                    <input name="patronid" value="#getHousehold.patronid#" type="hidden">
                    <input name="primarypatronid" value="#getHousehold.primarypatronid#" type="hidden">
                    <input name="recordid" value="#recordid#" type="hidden">
                    <table  bgcolor="##FFFF99" width="100%">
                         <TR>
                              <TD align="right" style="color:red;font-weight:bold;">Name</TD>
                              <TD><input type="Text" name="contactname1" style="width: 200px;" onChange="this.value=alltrim(this.value)" value="#thisECData.contactname#"></TD>
                              
                              

                              <TD nowrap align="right">Phone 1</TD>
                              <TD><input type="Text" name="phone11" style="width: 150px;" onChange="this.value=alltrim(this.value)" value="#thisECData.phone1#"></TD>
                                                            <TD style="color:red;font-weight:bold;">Emergency<br />Contact?</TD>
                              <td><input name="emer" type="radio" value="true" <CFIF thisECdata.emer EQ true>checked</CFIF>>
                                   Yes<Br />
                                   <input name="emer" type="radio" value="false" <CFIF thisECdata.emer EQ false>checked</CFIF>>
                                   No
                              </td>
                         </TR>
                         <TR>
                              <TD align="right">Relationship</TD>
                              <TD><input type="Text" name="relationship1" style="width: 150px;" onChange="this.value=alltrim(this.value)" value="#thisECData.relationship#"></TD>
                              
                              <TD nowrap align="right">Phone 2</TD>
                              <TD><input type="Text" name="phone12" style="width: 150px;" onChange="this.value=alltrim(this.value)" value="#thisECData.phone2#"></TD>
                              
                              <TD style="color:red;font-weight:bold;" >Designate For<br />Pick Up?</TD>
                              <td><input name="pickup" type="radio" value="true" <CFIF thisECdata.pickup EQ true>checked</CFIF> >
                                   Yes<Br />
                                   <input name="pickup" type="radio" value="false" <CFIF thisECdata.pickup EQ false>checked</CFIF>>
                                   No
                              </td>
                              
                         </TR>

                         <tr><td colspan="6" align="center">
                         <strong style="color:red;">Red text</strong> indicates a response is <strong>required</strong>.<br />
                         <input type="submit" value="Update Emergency Contact / Designated Pick-Up"></td></tr>
                    </table>
               </form>
               <CFSET formactive = true>
          </CFIF>  
          <CFIF getECData.recordcount GT 0>
          <table width="100%" bgcolor="##FFFFFF">
          <tr>
          <td>
          
               <table bgcolor="##FFFFFF" width="95%" cellspacing="0" cellpadding="3">
                              <tr>
                                   <td style="border-bottom-color:##000;border-bottom-width:1px;border-bottom-style:solid;"><strong>Name</strong></td>
                                   <td style="border-bottom-color:##000;border-bottom-width:1px;border-bottom-style:solid;"><b>Relationship</b></td>
                                   <td style="border-bottom-color:##000;border-bottom-width:1px;border-bottom-style:solid;"><b>Phones(s)</b></td>
                                   <td style="border-bottom-color:##000;border-bottom-width:1px;border-bottom-style:solid;"><b>Emergency Contact</b></td>
                                   <td style="border-bottom-color:##000;border-bottom-width:1px;border-bottom-style:solid;"><b>Pick Up</b></td>
                                   <td style="border-bottom-color:##000;border-bottom-width:1px;border-bottom-style:solid;">&nbsp;</td>
                              </tr>
                              
                    <CFLOOP query="GetECData">
                         

                              <TR >
                                   <TD valign="top">#contactname#</TD>
                                   <TD valign="top">#relationship#</TD>
                                   <TD valign="top"><cfif phone1 neq "">
                                             #phone1# <BR>
                                        </cfif>
                                        <cfif phone2 neq "">
                                             #phone2# <BR>
                                        </cfif></TD>
                                   <td align="center"><CFIF emer>
                                             Yes
                                             <CFELSE>
                                             No
                                        </CFIF></td>
                                   <td align="center"><CFIF pickup>
                                             Yes
                                             <CFELSE>
                                             No
                                        </CFIF></td>
                                   <td><a href="#script_name#?type=editec&selectedpatronid=#getHousehold.patronid#&recordid=#getECData.pk#">Edit</a> | <a href="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=deleteec&selectedpatronid=#getHousehold.patronid#&recordid=#getECData.pk#','mykey')))#">Delete</a></td>
                              </TR>
                         
                    </CFLOOP>
                    
                    
                    
                    
                    <tr>
                                   <td colspan="6" style="border-top-color:##000;border-top-width:1px;border-top-style:solid;">* THPRD is only able to store <strong>five</strong> emergency contacts.</td>
                                  
                              </tr>
                    
                    </td></tr></table>
               </table>
          </CFIF>             
               </td>
          </tr>
          

           
           <tr valign="top" ><td colspan="2" style="height:10px;"></td></tr>        
          
          <tr valign="top" style="background-color:##E0E0E0;">
          	<td colspan="5"><strong>Physician & Insurance</strong> | <CFIF GetPhysicianData.recordcount EQ 0>
               <a href="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=addpi&selectedpatronid=#getHousehold.patronid#&recordid=#GetPhysicianData.pk#','mykey')))#">Add</a>
          <CFELSE><a href="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=editpi&selectedpatronid=#getHousehold.patronid#&recordid=#GetPhysicianData.pk#','mykey')))#   ">Update</a></CFIF></td>
          
          
     
          
          </tr>
          <tr>
          	<td colspan="5" style="background-color:##E0E0E0;">

<!--- if link has been clicked show form to ADD physician info to this patron --->
          <CFIF type EQ "addpi">
               <form method="POST" action="#cgi.script_name#" name="updatePI">
                    <input type="hidden" name="update" value="true">
                    <input type="hidden" name="updateAction" value="updatePI">
                    <input name="patronid" value="#patronid#" type="hidden">
                    <input name="primarypatronid" value="#primarypatronid#" type="hidden">
                    <table bgcolor="##FFFF99" width="100%" >
                         <TR>
                              <TD align="right">Physician Name</TD>
                              <TD colspan="3"><input type="Text" name="physicianname" style="width: 200px;" #inputcolor# onChange="this.value=alltrim(this.value)"></TD>
                              <TD align="right">Phone</TD>
                              <TD><input type="Text" name="physicianphone" style="width: 150px;" #inputcolor# onChange="this.value=alltrim(this.value)"></TD>
                         </TR>
                         
                         <TR>
                              <TD align="right">Health Insurance</TD>
                              <TD colspan="3"><input type="Text" name="insurance" style="width: 200px;" #inputcolor# onChange="this.value=alltrim(this.value)"></TD>
                              <TD align="right">Group ##</TD>
                              <TD><input type="Text" name="groupnumber" style="width: 100px;" #inputcolor# onChange="this.value=alltrim(this.value)"></TD>
                         </TR>
<TR>
                              <TD align="right" nowrap>Hospital Preferance</TD>
                              <TD colspan="5"><input type="Text" name="hospital" style="width: 200px;" #inputcolor# onChange="this.value=alltrim(this.value)"></TD>
                         </TR>
                         <TR>
                              <TD align="right">Dentist Name</TD>
                              <TD colspan="3"><input type="Text" name="dentistname" style="width: 200px;" #inputcolor# onChange="this.value=alltrim(this.value)"></TD>
                              <TD align="right">Phone</TD>
                              <TD><input type="Text" name="dentistphone" style="width: 150px;" #inputcolor# onChange="this.value=alltrim(this.value)"></TD>
                         </TR>
                         <!---
                         <tr>
                              <td colspan="6" align="center"><br />
                              <table style="border-style:dashed;border-width:1px;border-color:##000;background-color:##FFF;padding:3px;">
                                        <tr>
                                             <td valign="middle"><strong>Include this physician & insurance Information with<br />the following other household members:</strong></td>
                                             <td width="10"></td>
                                             <td><CFLOOP query="getHousehold2">
                                             		<CFIF getHouseHold2.patronid NEQ selectedpatronid>
                                                       <input type="checkbox" name="additionalpatronidPI" value="#getHousehold2.patronid#">
                                                       #getHousehold2.firstname# #getHousehold2.lastname# <br>
                                                       </CFIF>
                                                  </CFLOOP>
                                             
                                        </tr>
                                   </table></td>
                         </tr>
					--->
                         <tr><td colspan="6" align="center">
                         <br /><strong style="color:red;">Red text</strong> indicates a response is <strong>required</strong>.<br />
                         <input type="submit" value="Add Physician & Insurance Information"></td></tr>
                    </table>
               </form>
               <CFSET formactive = true>
          </CFIF>
          <!--- if link has been clicked show form to EDIT physician info to this patron --->
          <CFIF type EQ "editpi">
               <form method="POST" action="#cgi.script_name#" name="updatePI">
                    <input type="hidden" name="update" value="true">
                    <input type="hidden" name="updateAction" value="updatePI">
                    <input name="patronid" value="#getHousehold.patronid#" type="hidden">
                    <input name="primarypatronid" value="#getHousehold.primarypatronid#" type="hidden">
                    <input name="recordid" value="#recordid#" type="hidden">
                    <CFSET PIForm = true>
<table bgcolor="##FFFF99" width="100%" >
                         <TR>
                              <TD align="right">Physician Name</TD>
                              <TD colspan="3"><input type="Text" name="physicianname" style="width: 200px;" #inputcolor# onChange="this.value=alltrim(this.value)" value="#getPhysicianData.physicianname#"></TD>
                              <TD align="right">Phone</TD>
                              <TD><input type="Text" name="physicianphone" style="width: 150px;" #inputcolor# onChange="this.value=alltrim(this.value)" value="#getPhysicianData.physicianphone#"></TD>
                         </TR>
                         
                         <TR>
                              <TD align="right">Health Insurance</TD>
                              <TD colspan="3"><input type="Text" name="insurance" style="width: 200px;" #inputcolor# onChange="this.value=alltrim(this.value)" value="#getPhysicianData.healthinsurance#"></TD>
                              <TD align="right">Group ##</TD>
                              <TD><input type="Text" name="groupnumber" style="width: 100px;" #inputcolor# onChange="this.value=alltrim(this.value)" value="#getPhysicianData.healthinsurancegroup#"></TD>
                         </TR>
<TR>
                              <TD align="right" nowrap>Hospital Preferance</TD>
                              <TD colspan="5"><input type="Text" name="hospital" style="width: 200px;" #inputcolor# onChange="this.value=alltrim(this.value)" value="#getPhysicianData.prefhospital#"></TD>
                         </TR>
                         <TR>
                              <TD align="right">Dentist Name</TD>
                              <TD colspan="3"><input type="Text" name="dentistname" style="width: 200px;" #inputcolor# onChange="this.value=alltrim(this.value)" value="#getPhysicianData.dentistname#"></TD>
                              <TD align="right">Phone</TD>
                              <TD><input type="Text" name="dentistphone" style="width: 150px;" #inputcolor# onChange="this.value=alltrim(this.value)" value="#getPhysicianData.dentistphone#"></TD>
                         </TR>
                         <tr><td colspan="6" align="center">
                         <br /><strong style="color:red;">Red text</strong> indicates a response is <strong>required</strong>.<br />
                         <input type="submit" value="Update Physician & Insurance Information"></td></tr>
                    </table>
               </form>
          </CFIF>
          <CFIF getPhysicianData.recordcount GT 0 and PIform EQ false>
               <table bgcolor="##FFFFFF" width="100%" >
               
               <tr>
               <td>
               <table width="80%">
                    <CFLOOP QUERY="getPhysicianData">
                              <TR >
                                   <TD align="right"  width="25%"><strong>Physician Name</strong></TD>
                                   <TD width="25%">#GetPhysicianData.physicianname#</TD>
                                   <TD align="right"  width="25%"><strong>Phone</strong></TD>
                                   <TD width="25%">#GetPhysicianData.physicianphone#</TD>
                              </TR>
                              <TR >
                                   <TD align="right" nowrap  ><strong>Hospital Preference</strong></TD>
                                   <TD >#GetPhysicianData.prefhospital#</TD>
                              </TR>
                              <TR >
                                   <TD align="right"  ><strong>Health Insurance</strong></TD>
                                   <TD >#GetPhysicianData.healthinsurance#</TD>
                                   <TD align="right"  ><strong>Group ##</strong></TD>
                                   <TD>#GetPhysicianData.healthinsurancegroup#</TD>
                              </TR>
                              <TR >
                                   <TD colspan="4"><br></TD>
                              </TR>
                              <TR >
                                   <TD align="right"  ><strong>Dentist Name</strong></TD>
                                   <TD >#GetPhysicianData.dentistname#</TD>
                                   <TD align="right"  ><strong>Phone</strong></TD>
                                   <TD>#GetPhysicianData.dentistphone#</TD>
                              </TR>

                    </CFLOOP>
                    </td></tr></table>
               </table>
          </CFIF>
          
               
               </td>
          </tr>

<tr valign="top" ><td colspan="2" style="height:10px;"></td></tr>   

          </CFOUTPUT>

</table>            
               
               

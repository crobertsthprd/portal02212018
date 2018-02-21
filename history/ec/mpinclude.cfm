

<link rel="stylesheet" href="/css/jquery/jquery.css" type="text/css" media="all" />
<script src="/js/jquery/calendarpackage/jquery.min.js" type="text/javascript"></script>
<script src="/js/jquery/calendarpackage/ui.custom.min.js" type="text/javascript"></script>    

<script>
	$(function() {
		$( "#datepicker" ).datepicker({
			showOn: "button",
			buttonImage: "/images/cal.gif",
			buttonImageOnly: true,
			buttonText: 'Click To Select Start Date'
		});
	});
	</script>





<CFOUTPUT>
     <table width="650" border=0 cellpadding=3 cellspacing="0">
     
<form method="POST" action="#cgi.script_name#" name="updateMPI">
                    <input type="hidden" name="update" value="true">
                    <input type="hidden" name="updateAction" value="updateMPI">
                    <input name="patronid" value="#patronid#" type="hidden">
                    <input name="primarypatronid" value="#primarypatronid#" type="hidden">     
     
     <tr valign="top" style="background-color:##E0E0E0;">
          <td colspan="5"><strong>Medical & Physical Information</strong> | <CFIF GetMedical.recordcount EQ 0>
               <a href="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=updateMPI&selectedpatronid=#getHousehold.patronid#&recordid=#GetMedical.pk#','mykey')))#">Add</a><br>
          <CFELSE><a href="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=updateMPI&selectedpatronid=#getHousehold.patronid#&recordid=#GetMedical.pk#','mykey')))#">Update</a></CFIF></td>
     </tr>
     <tr valign="top" style="background-color:##E0E0E0;">
          <td colspan="5">
          
	<CFIF type EQ "updateMPI" >
          
     <table bgcolor="##FFFF99" width="100%" border="0">

          <tr>
               <td valign="top">

<table border="0">


<td colspan="4" ><strong>Have you ever had...</strong>
</td>
</tr>
<TR>
     <TD align="right" style="color:red;font-weight:bold;">Allergies</TD>
     <TD nowrap><input <cfif GetMedical.allergies eq "1">checked</cfif> type="checkbox" id="cballergies1" onChange="getElementById('cballergies2').checked=false" name="allergies" value="1">
          Yes
          <input <cfif GetMedical.allergies eq "0">checked</cfif> type="checkbox" id="cballergies2" onChange="getElementById('cballergies1').checked=false" name="allergies" value="0">
          No </TD>
</TR>

<TR>
     <TD align="right" style="color:red;font-weight:bold;">ADD/ADHD</TD>
     <TD nowrap><input <cfif GetMedical.adhd eq "1">checked</cfif> type="checkbox" id="cbadhd1" onChange="getElementById('cbadhd2').checked=false" name="adhd" value="1">
          Yes
          <input <cfif GetMedical.adhd eq "0">checked</cfif> type="checkbox" id="cbadhd2" onChange="getElementById('cbadhd1').checked=false" name="adhd" value="0">
          No </TD>
</tr>
<TR>
     <TD align="right" nowrap style="color:red;font-weight:bold;">Autism/Aspergers</TD>
     <TD nowrap><input <cfif GetMedical.autism eq "1">checked</cfif> type="checkbox" id="cbautism1" onChange="getElementById('cbautism2').checked=false" name="autism" value="1">
          Yes
          <input <cfif GetMedical.autism eq "0">checked</cfif> type="checkbox" id="cbautism2" onChange="getElementById('cbautism1').checked=false" name="autism" value="0">
          No </TD>
</TR>
<TR>
     <TD align="right" style="color:red;font-weight:bold;">Seizures</TD>
     <TD nowrap><input <cfif GetMedical.seizures eq "1">checked</cfif> type="checkbox" id="cbseizures1" onChange="getElementById('cbseizures2').checked=false" name="seizures" value="1">
          Yes
          <input <cfif GetMedical.seizures eq "0">checked</cfif> type="checkbox" id="cbseizures2" onChange="getElementById('cbseizures1').checked=false" name="seizures" value="0">
          No </TD>
 </TR>
 <TR>
     <TD align="right" nowrap style="color:red;font-weight:bold;">Hepatitis A or B</TD>
     <TD nowrap><input <cfif GetMedical.hepatitis eq "1">checked</cfif> type="checkbox" id="cbhepatitis1" onChange="getElementById('cbhepatitis2').checked=false" name="hepatitis" value="1">
          Yes
          <input <cfif GetMedical.hepatitis eq "0">checked</cfif> type="checkbox" id="cbhepatitis2" onChange="getElementById('cbhepatitis1').checked=false" name="hepatitis" value="0">
          No </TD>
</TR>
<tr>
 <TD align="right" style="color:red;font-weight:bold;">Diabetes</TD>
                              <TD nowrap><input <cfif GetMedical.diabetes eq "1">checked</cfif> type="checkbox" id="cbdiabetes1" onChange="getElementById('cbdiabetes2').checked=false" name="diabetes" value="1">
                                   Yes
                                   <input <cfif GetMedical.diabetes eq "0">checked</cfif> type="checkbox" id="cbdiabetes2" onChange="getElementById('cbdiabetes1').checked=false" name="diabetes" value="0">
                                   No </TD>
</tr>
<tr>
     <TD align="right" nowrap style="color:red;font-weight:bold;">Heart Problems/Murmur</TD>
     <TD nowrap><input <cfif GetMedical.heart eq "1">checked</cfif> type="checkbox" id="cbheart1" onChange="getElementById('cbheart2').checked=false" name="heart" value="1">
          Yes
          <input <cfif GetMedical.heart eq "0">checked</cfif> type="checkbox" id="cbheart2" onChange="getElementById('cbheart1').checked=false" name="heart" value="0">
          No </TD>

</TR>

<tr>
     <TD align="right" nowrap style="color:red;font-weight:bold;">Asthma/Bronchitis</TD>
     <TD nowrap><input <cfif GetMedical.asthma eq "1">checked</cfif> type="checkbox" id="cbasthma1" onChange="getElementById('cbasthma2').checked=false" name="asthma" value="1">
          Yes
          <input <cfif GetMedical.asthma eq "0">checked</cfif> type="checkbox" id="cbasthma2" onChange="getElementById('cbasthma1').checked=false" name="asthma" value="0">
          No </TD>
</tr>


 <tr>
     <TD align="right" style="color:red;font-weight:bold;">Hernia</TD>
     <TD nowrap><input <cfif GetMedical.hernia eq "1">checked</cfif> type="checkbox" id="cbhernia1" onChange="getElementById('cbhernia2').checked=false" name="hernia" value="1">
          Yes
          <input <cfif GetMedical.hernia eq "0">checked</cfif> type="checkbox" id="cbhernia2" onChange="getElementById('cbhernia1').checked=false" name="hernia" value="0">
          No </TD>

</TR>

<tr>
     <TD align="right" style="color:red;font-weight:bold;">Concussion</TD>
     <TD nowrap><input <cfif GetMedical.concussion eq "1">checked</cfif> type="checkbox" id="cbconcussion1" onChange="getElementById('cbconcussion2').checked=false" name="concussion" value="1">
          Yes
          <input <cfif GetMedical.concussion eq "0">checked</cfif> type="checkbox" id="cbconcussion2" onChange="getElementById('cbconcussion1').checked=false" name="concussion" value="0">
          No </TD>
</tr>
<tr>
<td colspan="4"><strong>Do you wear...</strong>
</td>
</tr>
<tr>
 <TD align="right" style="color:red;font-weight:bold;">Glasses</TD>
                              <TD nowrap><input <cfif GetMedical.glasses eq "1">checked</cfif> type="checkbox" id="cbglasses1" onChange="getElementById('cbglasses2').checked=false" name="glasses" value="1">
                                   Yes
                                   <input <cfif GetMedical.glasses eq "0">checked</cfif> type="checkbox" id="cbglasses2" onChange="getElementById('cbglasses1').checked=false" name="glasses" value="0">
                                   No </TD>
</tr>
<tr>
<td align="right"><strong><u>Contact Lenses</u></strong></td>
<td></td>
</tr>
<tr>
                              <TD align="right" style="color:red;font-weight:bold;">Soft</TD>
                              <TD nowrap><input <cfif GetMedical.scontacts eq "1">checked</cfif> type="checkbox" id="cbscontacts1" onChange="getElementById('cbscontacts2').checked=false" name="scontacts" value="1">
                                   Yes
                                   <input <cfif GetMedical.scontacts eq "0">checked</cfif> type="checkbox" id="cbscontacts2" onChange="getElementById('cbscontacts1').checked=false" name="scontacts" value="0">
                                   No </TD>
</tr>
<TD align="right" style="color:red;font-weight:bold;">Hard</TD>
                              <TD nowrap><input <cfif GetMedical.hcontacts eq "1">checked</cfif> type="checkbox" id="cbhcontacts1" onChange="getElementById('cbhcontacts2').checked=false" name="hcontacts" value="1">
                                   Yes
                                   <input <cfif GetMedical.hcontacts eq "0">checked</cfif> type="checkbox" id="cbhcontacts2" onChange="getElementById('cbhcontacts1').checked=false" name="hcontacts" value="0">
                                   No </TD>
                         </TR>




</table>               
</td>
<td width="40"></td>
<td valign="top" width="480"><strong>Details:</strong><br>
                                   <textarea name="meddetails" wrap="virtual" style="width: 95%;" rows="20" onChange="this.value=alltrim(this.value)" #inputcolor#>#replace( GetMedical.meddetails, chr(13), "<BR>", "all")#</textarea>
</td>
</tr>
               
               <!---
               <table border="0">
                         <TR>
                              <TD colspan="4"  width="65%"><strong>Have you ever had...</strong></TD>
                              <TD colspan="4" ><strong>Do you wear...</strong></TD>
                         </TR>
                         <TR>
                              <TD align="right">Allergies</TD>
                              <TD nowrap><input <cfif GetMedical.allergies eq "1">checked</cfif> type="checkbox" id="cballergies1" onChange="getElementById('cballergies2').checked=false" name="allergies" value="1">
                                   Yes
                                   <input <cfif GetMedical.allergies eq "0">checked</cfif> type="checkbox" id="cballergies2" onChange="getElementById('cballergies1').checked=false" name="allergies" value="0">
                                   No </TD>
                              <TD align="right">Diabetes</TD>
                              <TD nowrap><input <cfif GetMedical.diabetes eq "1">checked</cfif> type="checkbox" id="cbdiabetes1" onChange="getElementById('cbdiabetes2').checked=false" name="diabetes" value="1">
                                   Yes
                                   <input <cfif GetMedical.diabetes eq "0">checked</cfif> type="checkbox" id="cbdiabetes2" onChange="getElementById('cbdiabetes1').checked=false" name="diabetes" value="0">
                                   No </TD>
                              <TD align="right">Glasses</TD>
                              <TD nowrap><input <cfif GetMedical.glasses eq "1">checked</cfif> type="checkbox" id="cbglasses1" onChange="getElementById('cbglasses2').checked=false" name="glasses" value="1">
                                   Yes
                                   <input <cfif GetMedical.glasses eq "0">checked</cfif> type="checkbox" id="cbglasses2" onChange="getElementById('cbglasses1').checked=false" name="glasses" value="0">
                                   No </TD>
                         </TR>
                         <TR>
                              <TD align="right">ADD/ADHD</TD>
                              <TD nowrap><input <cfif GetMedical.adhd eq "1">checked</cfif> type="checkbox" id="cbadhd1" onChange="getElementById('cbadhd2').checked=false" name="adhd" value="1">
                                   Yes
                                   <input <cfif GetMedical.adhd eq "0">checked</cfif> type="checkbox" id="cbadhd2" onChange="getElementById('cbadhd1').checked=false" name="adhd" value="0">
                                   No </TD>
                              <TD align="right" nowrap>Heart Problems/Murmur</TD>
                              <TD nowrap><input <cfif GetMedical.heart eq "1">checked</cfif> type="checkbox" id="cbheart1" onChange="getElementById('cbheart2').checked=false" name="heart" value="1">
                                   Yes
                                   <input <cfif GetMedical.heart eq "0">checked</cfif> type="checkbox" id="cbheart2" onChange="getElementById('cbheart1').checked=false" name="heart" value="0">
                                   No </TD>
                              <TD align="right" nowrap>Contacts</TD>
                              <TD nowrap></TD>
                         </TR>
                         <TR>
                              <TD align="right" nowrap>Autism/Aspbergers</TD>
                              <TD nowrap><input <cfif GetMedical.autism eq "1">checked</cfif> type="checkbox" id="cbautism1" onChange="getElementById('cbautism2').checked=false" name="autism" value="1">
                                   Yes
                                   <input <cfif GetMedical.autism eq "0">checked</cfif> type="checkbox" id="cbautism2" onChange="getElementById('cbautism1').checked=false" name="autism" value="0">
                                   No </TD>
                              <TD align="right" nowrap>Asthma/Bronchitis</TD>
                              <TD nowrap><input <cfif GetMedical.asthma eq "1">checked</cfif> type="checkbox" id="cbasthma1" onChange="getElementById('cbasthma2').checked=false" name="asthma" value="1">
                                   Yes
                                   <input <cfif GetMedical.asthma eq "0">checked</cfif> type="checkbox" id="cbasthma2" onChange="getElementById('cbasthma1').checked=false" name="asthma" value="0">
                                   No </TD>
                              <TD align="right">Hard</TD>
                              <TD nowrap><input <cfif GetMedical.hcontacts eq "1">checked</cfif> type="checkbox" id="cbhcontacts1" onChange="getElementById('cbhcontacts2').checked=false" name="hcontacts" value="1">
                                   Yes
                                   <input <cfif GetMedical.hcontacts eq "0">checked</cfif> type="checkbox" id="cbhcontacts2" onChange="getElementById('cbhcontacts1').checked=false" name="hcontacts" value="0">
                                   No </TD>
                         </TR>
                         <TR>
                              <TD align="right">Seizures</TD>
                              <TD nowrap><input <cfif GetMedical.seizures eq "1">checked</cfif> type="checkbox" id="cbseizures1" onChange="getElementById('cbseizures2').checked=false" name="seizures" value="1">
                                   Yes
                                   <input <cfif GetMedical.seizures eq "0">checked</cfif> type="checkbox" id="cbseizures2" onChange="getElementById('cbseizures1').checked=false" name="seizures" value="0">
                                   No </TD>
                              <TD align="right">Hernia</TD>
                              <TD nowrap><input <cfif GetMedical.hernia eq "1">checked</cfif> type="checkbox" id="cbhernia1" onChange="getElementById('cbhernia2').checked=false" name="hernia" value="1">
                                   Yes
                                   <input <cfif GetMedical.hernia eq "0">checked</cfif> type="checkbox" id="cbhernia2" onChange="getElementById('cbhernia1').checked=false" name="hernia" value="0">
                                   No </TD>
                              <TD align="right">Soft</TD>
                              <TD nowrap><input <cfif GetMedical.scontacts eq "1">checked</cfif> type="checkbox" id="cbscontacts1" onChange="getElementById('cbscontacts2').checked=false" name="scontacts" value="1">
                                   Yes
                                   <input <cfif GetMedical.scontacts eq "0">checked</cfif> type="checkbox" id="cbscontacts2" onChange="getElementById('cbscontacts1').checked=false" name="scontacts" value="0">
                                   No </TD>
                         </TR>
                         <TR>
                              <TD align="right" nowrap>Hepatitis A or B</TD>
                              <TD nowrap><input <cfif GetMedical.hepatitis eq "1">checked</cfif> type="checkbox" id="cbhepatitis1" onChange="getElementById('cbhepatitis2').checked=false" name="hepatitis" value="1">
                                   Yes
                                   <input <cfif GetMedical.hepatitis eq "0">checked</cfif> type="checkbox" id="cbhepatitis2" onChange="getElementById('cbhepatitis1').checked=false" name="hepatitis" value="0">
                                   No </TD>
                              <TD align="right">Concussion</TD>
                              <TD nowrap><input <cfif GetMedical.concussion eq "1">checked</cfif> type="checkbox" id="cbconcussion1" onChange="getElementById('cbconcussion2').checked=false" name="concussion" value="1">
                                   Yes
                                   <input <cfif GetMedical.concussion eq "0">checked</cfif> type="checkbox" id="cbconcussion2" onChange="getElementById('cbconcussion1').checked=false" name="concussion" value="0">
                                   No </TD>
                    </table>
                    --->
                    
                    <!---
                         <TR valign="top">
                              <TD colspan="10"><strong>Details:</strong><br>
                                   <textarea name="meddetails" wrap="virtual" style="width: 60%;" onChange="this.value=alltrim(this.value)" #inputcolor#>#replace( GetMedical.meddetails, chr(13), "<BR>", "all")#</textarea></TD>
                         </TR>
				--->
                         <TR>
                              <TD colspan="3" nowrap >
                              <BR />
                              <table border="0">
                              <tr>
                              <TD >Is child current on all school-required immunizations?</TD>
                              <td><input <cfif GetMedical.immunizations eq "1">checked</cfif> type="checkbox" id="cbimmunizations1" onChange="getElementById('cbimmunizations2').checked=false" name="immunizations" value="1">
                                   Yes
                                   <input <cfif GetMedical.immunizations eq "0">checked</cfif> type="checkbox" id="cbimmunizations2" onChange="getElementById('cbimmunizations1').checked=false" name="immunizations" value="0">
                                   No
                               </td>
                         </tr>
                         <tr>
                         <td>Date of last tetanus inoculation:</td>
                         <td><input name="tetanusdate" type="text" id="datepicker" style="width:85px;margin-right:5px;" onClick="this.blur()" value="<cfif IsDate(GetMedical.tetanusdate)>#DateFormat(GetMedical.tetanusdate, "mm/dd/yyyy" )#</cfif>"></TD>
                         </TR>
                         
                         
					
                         
                         <TR>
                              <TD colspan="2" style="color:red;font-weight:bold;"><br>
                                   Please list any medical history or physical restrictions that could affect participation in program/activities: Describe any past medical conditions, which might require special attention (if none please indicate).</TD>
                         </TR>
                         <TR>
                              <TD colspan="2"><textarea name="medhistory" wrap="virtual" style="width: 60%;" onChange="this.value=alltrim(this.value)" #inputcolor#>#replace( GetMedical.medhistory, chr(13), "<BR>", "all")#</textarea></TD>
                         </TR>
                         <TR>
                              <TD colspan="2"><br>Please identify any special adaptations or accommodations necessary to assist with participation in programs/activities.</TD>
                         </TR>
                         <TR>
                              <TD colspan="2"><textarea name="adaptations" wrap="virtual" style="width: 60%;" onChange="this.value=alltrim(this.value)" #inputcolor#>#replace( GetMedical.adaptations, chr(13), "<BR>", "all")#</textarea></TD>
                         </TR>
                         <TR>
                              <TD   nowrap><br />Does participant take medicines at home?</TD>
                              <TD  width="460"><br /><input <cfif GetMedical.homemeds eq "1">checked</cfif> type="checkbox" id="cbhomemeds1" onChange="getElementById('cbhomemeds2').checked=false" name="homemeds" value="1">
                                   Yes
                                   <input <cfif GetMedical.homemeds eq "0">checked</cfif> type="checkbox" id="cbhomemeds2" onChange="getElementById('cbhomemeds1').checked=false" name="homemeds" value="0">
                                   No </TD>
                         </TR>
                         <TR>
                              <TD  nowrap style="color:red;font-weight:bold;">Will participant need medicine administered by THPRD?<br>
                                   If Yes, submit <A href="http://www.thprd.org/pdfs2/document70.pdf" target="_blank"><strong>Medical Authorization Form</strong></A>.</TD>
                              <TD  nowrap valign="top"><input <cfif GetMedical.thprdmeds eq "1">checked</cfif> type="checkbox" id="cbthprdmeds1" onChange="getElementById('cbthprdmeds2').checked=false" name="thprdmeds" value="1">
                                   Yes
                                   <input <cfif GetMedical.thprdmeds eq "0">checked</cfif> type="checkbox" id="cbthprdmeds2" onChange="getElementById('cbthprdmeds1').checked=false" name="thprdmeds" value="0">
                                   No&nbsp;&nbsp; </TD>
                         </TR>
                         <TR>
                              <TD colspan="2" align="center"><br />
                                   <table cellpadding="5">
                                        <tr>
                                             <td style="border-style:dashed;border-width:1px;border-color:##000;background-color:##FFF;"><strong style="color:red;">Please read conditions herein:</strong><br />I hereby give consent for my child to participate in all camp/recreational programs sponsored by Tualatin Hills Park & Recreation District (THPRD). I understand that activities run by the program may be vigorous at times, and although they are planned with the safety of the participants in mind, there is the risk of injury to my child arising from participation in this program.<br />
<br>

I acknowledge that the THPRD is relying on my judgment, as well as my doctor's judgment, after examining my child to determine that my child has the physical and mental capacity reasonably necessary to engage in the program in which he or she has been enrolled. As my child's legal guardian, I agree to assume the risk associated with this program for him/her. By doing so, I hereby waive all claims against the Tualatin Hills Park & Recreation District or any of its officers, agents or employees, which may arise due to accident, sickness, injury or death, which my child might suffer from his/her participation in the Program. In the event of a medical emergency, I understand every effort will be made to contact me. If I cannot be reached, I give my permission for my child to be treated by a professional medical person and admitted to a hospital if necessary. I agree to be the party responsible for all medical expenses incurred. Agreeing to this form will authorize THPRD to transport your child during the program. I will be responsible to maintain this information provided herein.<br />
                                                  <br />
                                                  <div align="center">
                                                       <input type="checkbox" name="waiverMPI" value="true"/>
                                                       <strong>I agree</strong></div></td>
                                        </tr>
                                   </table>
                                   <br />
                                   <strong style="color:red;">Red text</strong> indicates a response is <strong>required</strong>.<br />
                                   
                                   <input type="submit" value="Add/Update Medical & Physical Information"></TD>
                         </TR>
                    </table>
                    
                    
                    
                    </form>
                    
                    </TD>
          </TR>
     </TABLE>
     </CFIF>
     
     <CFIF getMedical.recordcount EQ 1 and type NEQ "updateMPI" >
<table bgcolor="##FFFFFF" width="100%" border="0">

          <tr>
               <td valign="top">

<table border="0">

<td colspan="4" ><strong>Have you ever had...</strong>
</td>
</tr>
<TR>
     <TD align="right" style="font-weight:bold;">Allergies</TD>
     <TD nowrap><input <cfif GetMedical.allergies eq "1">checked</cfif> type="checkbox" id="cballergies1" onChange="getElementById('cballergies2').checked=false" name="allergies" value="1" disabled>
          Yes
          <input <cfif GetMedical.allergies eq "0">checked</cfif> type="checkbox" id="cballergies2" onChange="getElementById('cballergies1').checked=false" name="allergies" value="0" disabled>
          No </TD>
</TR>

<TR>
     <TD align="right" style="font-weight:bold;">ADD/ADHD</TD>
     <TD nowrap><input <cfif GetMedical.adhd eq "1">checked</cfif> type="checkbox" id="cbadhd1" onChange="getElementById('cbadhd2').checked=false" name="adhd" value="1" disabled>
          Yes
          <input <cfif GetMedical.adhd eq "0">checked</cfif> type="checkbox" id="cbadhd2" onChange="getElementById('cbadhd1').checked=false" name="adhd" value="0" disabled>
          No </TD>
</tr>
<TR>
     <TD align="right" nowrap style="font-weight:bold;">Autism/Aspergers</TD>
     <TD nowrap><input <cfif GetMedical.autism eq "1">checked</cfif> type="checkbox" id="cbautism1" onChange="getElementById('cbautism2').checked=false" name="autism" value="1" disabled>
          Yes
          <input <cfif GetMedical.autism eq "0">checked</cfif> type="checkbox" id="cbautism2" onChange="getElementById('cbautism1').checked=false" name="autism" value="0" disabled>
          No </TD>
</TR>
<TR>
     <TD align="right" style="font-weight:bold;">Seizures</TD>
     <TD nowrap><input <cfif GetMedical.seizures eq "1">checked</cfif> type="checkbox" id="cbseizures1" onChange="getElementById('cbseizures2').checked=false" name="seizures" value="1" disabled>
          Yes
          <input <cfif GetMedical.seizures eq "0">checked</cfif> type="checkbox" id="cbseizures2" onChange="getElementById('cbseizures1').checked=false" name="seizures" value="0" disabled>
          No </TD>
 </TR>
 <TR>
     <TD align="right" nowrap style="font-weight:bold;">Hepatitis A or B</TD>
     <TD nowrap><input <cfif GetMedical.hepatitis eq "1">checked</cfif> type="checkbox" id="cbhepatitis1" onChange="getElementById('cbhepatitis2').checked=false" name="hepatitis" value="1" disabled>
          Yes
          <input <cfif GetMedical.hepatitis eq "0">checked</cfif> type="checkbox" id="cbhepatitis2" onChange="getElementById('cbhepatitis1').checked=false" name="hepatitis" value="0" disabled>
          No </TD>
</TR>
<tr>
 <TD align="right" style="font-weight:bold;">Diabetes</TD>
                              <TD nowrap><input <cfif GetMedical.diabetes eq "1">checked</cfif> type="checkbox" id="cbdiabetes1" onChange="getElementById('cbdiabetes2').checked=false" name="diabetes" value="1" disabled>
                                   Yes
                                   <input <cfif GetMedical.diabetes eq "0">checked</cfif> type="checkbox" id="cbdiabetes2" onChange="getElementById('cbdiabetes1').checked=false" name="diabetes" value="0" disabled>
                                   No </TD>
</tr>
<tr>
     <TD align="right" nowrap style="font-weight:bold;">Heart Problems/Murmur</TD>
     <TD nowrap><input <cfif GetMedical.heart eq "1">checked</cfif> type="checkbox" id="cbheart1" onChange="getElementById('cbheart2').checked=false" name="heart" value="1" disabled>
          Yes
          <input <cfif GetMedical.heart eq "0">checked</cfif> type="checkbox" id="cbheart2" onChange="getElementById('cbheart1').checked=false" name="heart" value="0" disabled>
          No </TD>

</TR>

<tr>
     <TD align="right" nowrap style="font-weight:bold;">Asthma/Bronchitis</TD>
     <TD nowrap><input <cfif GetMedical.asthma eq "1">checked</cfif> type="checkbox" id="cbasthma1" onChange="getElementById('cbasthma2').checked=false" name="asthma" value="1" disabled>
          Yes
          <input <cfif GetMedical.asthma eq "0">checked</cfif> type="checkbox" id="cbasthma2" onChange="getElementById('cbasthma1').checked=false" name="asthma" value="0" disabled>
          No </TD>
</tr>


 <tr>
     <TD align="right" style="font-weight:bold;">Hernia</TD>
     <TD nowrap><input <cfif GetMedical.hernia eq "1">checked</cfif> type="checkbox" id="cbhernia1" onChange="getElementById('cbhernia2').checked=false" name="hernia" value="1" disabled>
          Yes
          <input <cfif GetMedical.hernia eq "0">checked</cfif> type="checkbox" id="cbhernia2" onChange="getElementById('cbhernia1').checked=false" name="hernia" value="0" disabled>
          No </TD>

</TR>

<tr>
     <TD align="right" style="font-weight:bold;">Concussion</TD>
     <TD nowrap><input <cfif GetMedical.concussion eq "1">checked</cfif> type="checkbox" id="cbconcussion1" onChange="getElementById('cbconcussion2').checked=false" name="concussion" value="1" disabled>
          Yes
          <input <cfif GetMedical.concussion eq "0">checked</cfif> type="checkbox" id="cbconcussion2" onChange="getElementById('cbconcussion1').checked=false" name="concussion" value="0" disabled>
          No </TD>
</tr>
<tr>
<td colspan="4"><strong>Do you wear...</strong>
</td>
</tr>
<tr>
 <TD align="right" style="font-weight:bold;">Glasses</TD>
                              <TD nowrap><input <cfif GetMedical.glasses eq "1">checked</cfif> type="checkbox" id="cbglasses1" onChange="getElementById('cbglasses2').checked=false" name="glasses" value="1" disabled>
                                   Yes
                                   <input <cfif GetMedical.glasses eq "0">checked</cfif> type="checkbox" id="cbglasses2" onChange="getElementById('cbglasses1').checked=false" name="glasses" value="0" disabled>
                                   No </TD>
</tr>
<tr>
<td align="right"><strong><u>Contact Lenses</u></strong></td>
<td></td>
</tr>
<tr>
                              <TD align="right" style="font-weight:bold;">Soft</TD>
                              <TD nowrap><input <cfif GetMedical.scontacts eq "1">checked</cfif> type="checkbox" id="cbscontacts1" onChange="getElementById('cbscontacts2').checked=false" name="scontacts" value="1" disabled>
                                   Yes
                                   <input <cfif GetMedical.scontacts eq "0">checked</cfif> type="checkbox" id="cbscontacts2" onChange="getElementById('cbscontacts1').checked=false" name="scontacts" value="0" disabled>
                                   No </TD>
</tr>
<TD align="right" style="font-weight:bold;">Hard</TD>
                              <TD nowrap><input <cfif GetMedical.hcontacts eq "1">checked</cfif> type="checkbox" id="cbhcontacts1" onChange="getElementById('cbhcontacts2').checked=false" name="hcontacts" value="1" disabled>
                                   Yes
                                   <input <cfif GetMedical.hcontacts eq "0">checked</cfif> type="checkbox" id="cbhcontacts2" onChange="getElementById('cbhcontacts1').checked=false" name="hcontacts" value="0" disabled>
                                   No </TD>
                         </TR>




</table>               
</td>
<td width="40"></td>
<td valign="middel" width="480"><strong>Details:</strong><br><textarea name="meddetails" wrap="virtual" style="width: 95%;" rows="20" onChange="this.value=alltrim(this.value)" #inputcolor# readonly="readonly">#replace( GetMedical.meddetails, chr(13), "<BR>", "all")#</textarea>
</td>
</tr>
                         <TR>
                              <TD colspan="3" nowrap >
                              <BR />
                              <table border="0">
                              <tr>
                              <TD ><strong>Is child current on all school-required immunizations?</strong></TD>
                              <td><input <cfif GetMedical.immunizations eq "1">checked</cfif> type="checkbox" id="cbimmunizations1" onChange="getElementById('cbimmunizations2').checked=false" name="immunizations" value="1" disabled>
                                   Yes
                                   <input <cfif GetMedical.immunizations eq "0">checked</cfif> type="checkbox" id="cbimmunizations2" onChange="getElementById('cbimmunizations1').checked=false" name="immunizations" value="0" disabled>
                                   No
                               </td>
                         </tr>
                         <tr>
                         <td><strong>Date of last tetanus inoculation:</strong></td>
                         <td>#DateFormat(GetMedical.tetanusdate, "mm/dd/yyyy" )#</TD>
                         </TR>
                         
                         
					
                         
                         <TR>
                              <TD colspan="2" style="font-weight:bold;"><br>
                                   Please list any medical history or physical restrictions that could affect participation in program/activities: Describe any past medical conditions, which might require special attention (if none please indicate).</TD>
                         </TR>
                         <TR>
                              <TD colspan="2"><textarea name="medhistory" wrap="virtual" style="width: 60%;" onChange="this.value=alltrim(this.value)" #inputcolor# readonly="readonly">#replace( GetMedical.medhistory, chr(13), "<BR>", "all")#</textarea></TD>
                         </TR>
                         
                         
                         
                         <TR>
                              <TD colspan="2"><br><strong>Please identify any special adaptations or accommodations necessary to assist with participation in programs/activities.</strong></TD>
                         </TR>
                         <TR>
                              <TD colspan="2"><textarea name="adaptations" wrap="virtual" style="width: 60%;" onChange="this.value=alltrim(this.value)" #inputcolor# readonly="readonly">#replace( GetMedical.adaptations, chr(13), "<BR>", "all")#</textarea></TD>
                         </TR>
                         <TR>
                              <TD   nowrap><br /><strong>Does participant take medicines at home?</strong></TD>
                              <TD  width="460"><br /><input <cfif GetMedical.homemeds eq "1">checked</cfif> type="checkbox" id="cbhomemeds1" onChange="getElementById('cbhomemeds2').checked=false" name="homemeds" value="1" disabled>
                                   Yes
                                   <input <cfif GetMedical.homemeds eq "0">checked</cfif> type="checkbox" id="cbhomemeds2" onChange="getElementById('cbhomemeds1').checked=false" name="homemeds" value="0" disabled>
                                   No </TD>
                         </TR>
                         <TR>
                              <TD  nowrap style="font-weight:bold;">Will participant need medicine administered by THPRD?<br>
                                   If Yes, submit <A href="http://www.thprd.org/pdfs2/document70.pdf" target="_blank"><strong>Medical Authorization Form</strong></A>.</TD>
                              <TD  nowrap valign="top"><input <cfif GetMedical.thprdmeds eq "1">checked</cfif> type="checkbox" id="cbthprdmeds1" onChange="getElementById('cbthprdmeds2').checked=false" name="thprdmeds" value="1" disabled>
                                   Yes
                                   <input <cfif GetMedical.thprdmeds eq "0">checked</cfif> type="checkbox" id="cbthprdmeds2" onChange="getElementById('cbthprdmeds1').checked=false" name="thprdmeds" value="0" disabled>
                                   No&nbsp;&nbsp; </TD>
                         </TR>
                         <TR>
                              <TD colspan="2" align="center"><br />
                                   
                                   
                                   
                                   <a href="#script_name#?q=#urlencodedformat(tobase64(encrypt('type=updateMPI&selectedpatronid=#getHousehold.patronid#&recordid=#GetMedical.pk#','mykey')))#">Click Here To Update Medical & Physical Information</a></TD>
                         </TR>
                    </table>
                    
                    
                    
                    </form>
                    
                    </TD>
          </TR>
     </TABLE>     
     </CFIF>
     
</TD>
</TR>
</TABLE>
</CFOUTPUT>
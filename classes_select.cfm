 <cftry>

<CFPARAM name="ANY_AVAIL" default= "1">
<CFPARAM name="DO_SCHED" default="0">
<CFPARAM name="CRSLST" default="0">
<CFPARAM name="THIS_GRP" default="">
<CFPARAM name="THIS_PRG" default="0">
<CFPARAM name="THIS_PERM" default="0">
<CFPARAM name="READONLY" default="0">

<CFIF isDefined("url.prg") >
	<CFSET THIS_PRG=url.prg>
</CFIF>
<CFIF isDefined("url.readonly")>
	<CFSET readonly=url.readonly>
</CFIF>
<CFIF isDEfined("url.crs") and ( NOT isDefined("url.cls") )>
	<CFSET CRSLIST=url.crs>
	<CFQUERY name="checkclasses" datasource="#DB.CONNECT#">
		select fkey_course_deliv_type from course_core_data with (nolock)
		where key_course in (#crslst#) and fkey_course_deliv_type ='CL'
	</CFQUERY>
	<CFIF checkclasses.recordCOUNT gt 0>
		<CFSET DO_SCHED=1>

	</CFIF>
</CFIF>

<CFFUNCTION name="showEvents" returntype="any" >

	<CFQUERY name="crsInfo" datasource="#db.connect#"   >
		select key_course, rtrim(course_id) as course_id,
		rtrim(course_name) as course_name, fkey_course_deliv_type
		from course_core_data with (nolock) where key_course in (#crslst#)
	</CFQUERY>

	<cfloop query="crsInfo">

 		<CFSET THE_CRS=#crsinfo.key_course#>
		<CFIF Len(#crsInfo.course_name#) GT 0>
			<CFSET CRS_NAME = #crsInfo.course_name#>
		</CFIF>

	 	<CFOUTPUT><INPUT type=hidden name="id#THE_CRS#" id="id#THE_CRS#" value="#crsInfo.course_id#"></CFOUTPUT>
 	</cfloop>

	<CFQUERY name="Gscheds" datasource="#db.connect#"  timeout=#db.timeout#>
		select distinct classes.key_class, classes.max_Cost_per_student, final_price,
			rtrim(classes.location) as location, class_capacity,
			start_date, end_date, rtrim(schedule) as schedule, isnull(yr,'') as bundle_id,
		addr, loc_type
		from classes with (nolock)
		left outer join retail_pricev with (nolock) on classes.key_class = retail_pricev.fkey_class
			and program = '#THIS_PRG#'
			and retail_pricev.currency_locale = '#use_currency_locale#'
			and key_course_group is null
		left outer join class_sched with (nolock) on class_sched.fkey_class=key_class and class_sched.class_date=classes.start_date
		left outer join classrooms with (nolock) on key_classroom=class_sched.fkey_classroom
		where classes.fkey_course IN (#crslst#)
		and class_status = 'open'
		and start_date >= '#DateFormat(Now(),"MM/DD/YY")#'
		and (fkey_group = 'enterpriseAdmin'
			OR fkey_group in (
				<CFIF client.contact_key GT 0>
					select fkey_group
							from company_admin_groups with (nolock), contact with (nolock)
							where contact.fkey_company = company_admin_groups.fkey_company
							and key_contact = #client.contact_key#
				<CFELSE>
					select fkey_group
							from company_admin_groups with (nolock), company with (nolock)
							where company.key_company = company_admin_groups.fkey_company
							and company.name='#default_company#'
				</CFIF>
				)
			)
		order by bundle_id,start_date
	</CFQUERY>

	<CFQUERY name="getevents" dbtype="query">
		select distinct bundle_id from Gscheds where bundle_id <>'' order by bundle_id
	</CFQUERY>

	<CFIF getevents.recordcount GT 0>
	<h2>Choose from the following events</h2>
	<CFLOOP query="getevents">

	<script>
		<cfoutput>
		function checkedBtn(bundleId){

			var allCkBoxes = document.getElementsByTagName('input');
			for (var i=0; i < allCkBoxes.length; i++ ){
				if(allCkBoxes[i].type =='checkbox'){
					allCkBoxes[i].checked = false;
				}
			}


			var bundleTable = document.getElementById(bundleId+"_table");
			var courseBoxes = bundleTable.getElementsByTagName('input');

			for (var i=0; i < courseBoxes.length; i++ ){
				if(courseBoxes[i].type =='checkbox'){
					courseBoxes[i].checked = true;

				}
			}
		}
	</cfoutput>
	</script>

	<div class="class_events" >
		<cfset bundleIdNoWhiteSpace= REreplace(trim(getevents.bundle_id), "[\W_]", "-", "ALL") >

		<CFOUTPUT><label for="#bundleIdNoWhiteSpace#">#getevents.bundle_id#</label>
		 <INPUT type="radio"  name="bundledCourses" id="#bundleIdNoWhiteSpace#" value="#bundleIdNoWhiteSpace#" onChange='checkedBtn("#bundleIdNoWhiteSpace#")'></CFOUTPUT>


		<CFQUERY name="classesThisEvent" dbtype="query">
			select distinct * from Gscheds where bundle_id='#getevents.bundle_id#'
		</CFQUERY>

		<CFQUERY name="grpCourseInfo" datasource="#db.connect#"  timeout=#db.timeout#>
			SELECT KEY_CLASS,COURSE_ID,FKEY_COURSE,COURSE_NAME,schedule,instructor
   			FROM classesV  with (nolock) WHERE yr='#getevents.bundle_id#' AND class_status='OPEN';
		</CFQUERY>

		<div class="table-responsive">
			<CFOUTPUT><Z:Table id="#bundleIdNoWhiteSpace#_table" cols="Course ID,Course Name,Schedule,Instructor" class="zlist table<cfif IsDefined("tableClass") and len(tableClass)> #tableClass#</cfif>" format="table"></CFOUTPUT>
				<cfloop query="grpCourseInfo">
					<CFSET grpCrsId="">
					<cfset grpCrsID = grpCourseInfo.course_id >
					<cfset grpCrsName = grpCourseInfo.course_name >
					<cfset grpCrsSchedule = grpCourseInfo.schedule >
					<cfset grpCrsInstructor = grpCourseInfo.instructor >
					<cfset THE_CRS = grpCourseInfo.fkey_course >

					<Row>
					 	<cfoutput>
				   			<Data>
				   				<span >
								<INPUT type="checkbox" style="display:none;" name="cls#grpCourseInfo.fkey_course#" id="cls#grpCourseInfo.fkey_course#_#bundleIdNoWhiteSpace#"  value="#grpCourseInfo.key_class#" aria-label="#grpCourseInfo.course_id#" >
								</span>


								#trim(grpCrsID)#</Data>
					   		<Data>#trim(grpCrsName)#</Data>
					   		<Data>#trim(grpCrsSchedule)#</Data>
					   		<Data>
					   			<cfif grpCrsInstructor NEQ "NULL">#trim(grpCrsInstructor)#</cfif>
					   		</Data>
					   	</cfoutput>
					</Row>
				</cfloop>
			</Z:Table>
		</div>
	</div>

	</CFLOOP>
	</CFIF>
	<CFIF getevents.recordcount GT 0><CFSET show_individual_classes=0></CFIF>

	<CFRETURN true />


</CFFUNCTION>


<CFFUNCTION name="showIndividualClasses" returntype="any" >

	<cfloop Index="THE_CRS" List="#crslst#">
		<CFSET CRS_NAME = "">

		<CFQUERY name="crsInfo" datasource="#db.connect#"  timeout=#db.timeout#>
			select rtrim(course_id) as course_id, rtrim(course_name) as course_name, fkey_course_deliv_type
			from course_core_data where key_course= #THE_CRS#
		</CFQUERY>

		<CFIF Len(#crsInfo.course_name#) GT 0>
			<CFSET CRS_NAME = #crsInfo.course_name#>
		</CFIF>


	 	<CFOUTPUT><INPUT type=hidden name="id#THE_CRS#" id="id#THE_CRS#" value="#crsInfo.course_id#"></CFOUTPUT>


		<CFIF ( NOT IsDefined("URL.cls") OR (isDefined("URL.grp") AND url.grp GT 0) )
		  AND NOT CompareNoCase(#Trim(crsInfo.fkey_course_deliv_type)#,"CL"  ) >


			<CFQUERY name="scheds" datasource="#db.connect#"  timeout=#db.timeout#>
				select distinct classes.key_class, classes.max_Cost_per_student, final_price,
					rtrim(classes.location) as location, class_capacity,
					start_date, end_date, rtrim(schedule) as schedule, isnull(yr,'') as bundle_id,
				addr, loc_type
				from classes
				left outer join retail_pricev on classes.key_class = retail_pricev.fkey_class
					and program = '#THIS_PRG#'
					and retail_pricev.currency_locale = '#use_currency_locale#'
					and key_course_group is null
				left outer join class_sched on class_sched.fkey_class=key_class and class_sched.class_date=classes.start_date
				left outer join classrooms on key_classroom=class_sched.fkey_classroom
				where classes.fkey_course = #THE_CRS#
				and class_status = 'open'
				and start_date >= '#DateFormat(Now(),"MM/DD/YY")#'
				and (isnull(fkey_group,'enterpriseAdmin') = 'enterpriseAdmin'
					OR isnull(fkey_group,'enterpriseAdmin') in (
						<CFIF client.contact_key GT 0>
							select fkey_group
									from company_admin_groups, contact
									where contact.fkey_company = company_admin_groups.fkey_company
									and key_contact = #client.contact_key#
						<CFELSE>
							select fkey_group
									from company_admin_groups, company
									where company.key_company = company_admin_groups.fkey_company
									and company.name='#default_company#'
						</CFIF>
						)
					)
				order by bundle_id,start_date
			</CFQUERY>

			<span class="catalogcoursename"><cfoutput>@getmsg(APP_COURSE): #CRS_NAME#</cfoutput></span>

			<TABLE class="map">
			<TR>
				<CFSET num_cols=2>

				<TD class="subhead" width=30>&nbsp;</TD>
				<CFIF findnocase("location", register_cols) GT 0><CFSET num_cols=num_cols+1><TD class="subhead">@getmsg(APP_LOCATION)</TD></CFIF>
				<CFIF findnocase("city_state", register_cols) GT 0><CFSET num_cols=num_cols+1><TD  class="subhead">@getmsg(APP_CityState)</TD></CFIF>
				<CFIF findnocase("start_date", register_cols) GT 0><CFSET num_cols=num_cols+1><TD  class="subhead">@getmsg(APP_STARTDATE)</TD></CFIF>
				<CFIF findnocase("end_date", register_cols) GT 0><CFSET num_cols=num_cols+1><TD  class="subhead">@getmsg(APP_ENDDATE)</TD></CFIF>
				<CFIF findnocase("first_times", register_cols) GT 0><CFSET num_cols=num_cols+1><TD  class="subhead">@getmsg(APP_TIME)</TD></CFIF>
				<CFIF findnocase("schedule", register_cols) GT 0><CFSET num_cols=num_cols+1><TD  class="subhead">@getmsg(APP_SCHEDULE)</TD></CFIF>
				<CFIF findnocase("instructors", register_cols) GT 0><CFSET num_cols=num_cols+1><TD  class="subhead">@getmsg(APP_Instructors)</TD></CFIF>
				<TD width=60 class="subhead"></TD>
				<CFIF findnocase("price", register_cols) GT 0 and THIS_GRP IS 0><TD width=60 class="subhead">@Getmsg(APP_PRICE)</TD></CFIF>
				<CFIF findnocase("current-max", register_cols) GT 0><CFSET num_cols=num_cols+1><TD width=60 class="subhead">@Getmsg(APP_NumMaxEnr)</TD></CFIF>

			</TR>
			        <CFSET CLS = "subalt1">
				<CFSET CTR = 1>

				<CFIF client.contact_key EQ 0>
					<CFSET ANY_AVAIL = scheds.recordcount>
				<CFELSE>

					<CFSET ANY_AVAIL = 0>
				</CFIF>

				<CFLOOP query="scheds">

					<CFIF isDefined("scheds.max_cost_per_student") and #Len(scheds.max_cost_per_student)# GT 0>
						<CFSET THIS_PRICE = scheds.final_price>
					</CFIF>

					<CFSET HAS_CONFLICTS = 0>

					<CFIF use_shopping_cart NEQ 0 AND IsDefined("Client.order_id") AND Len(#Client.order_id#) GT 0 AND #Client.order_id# NEQ 0>
						<CFQUERY name="cart_conflicts" datasource="#db.connect#"  timeout=#db.timeout#>
							select conflict from dbo.find_cart_conflict('#Client.order_id#',#scheds.key_class#)
						</CFQUERY>
						<CFIF cart_conflicts.conflict NEQ 0>
							<CFSET HAS_CONFLICTS = 1>
						</CFIF>
					</CFIF>

					<CFIF HAS_CONFLICTS EQ 0>
						<CFSET ANY_AVAIL = 1>
						<CFSET MAX_LEVEL = scheds.class_capacity>
						<CFQUERY name="reg" datasource="#db.connect#"  timeout=#db.timeout#>
							select 	count(key_reg) as num_reg
							from 		stu_registration,
										course_status_type
							where 	fkey_class = #scheds.key_class#
										and fkey_course_status = key_course_status_type
										and course_open = 1
						</CFQUERY>
						<CFSET CURR_LEVEL = reg.num_reg>

						<TR>
							<cfoutput>
							<TD class="#CLS#" width=30>
								<INPUT type="radio" name="cls#THE_CRS#" id="cls#THE_CRS#" <CFIF CTR EQ 1>checked</CFIF> value="#scheds.key_class#" onChange="form.price.value=#THIS_PRICE#;">
							</TD>
							</CFOUTPUT>
							<CFIF findnocase("location", register_cols) GT 0>
								<TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" width=70>
									<CFIF scheds.loc_type EQ "Physical"><CFOUTPUT>#scheds.location#</CFOUTPUT>
									<CFELSE><CFOUTPUT>#scheds.addr#</CFOUTPUT>
									</CFIF>&nbsp;

								</TD>
							</CFIF>
							<CFIF findnocase("city_state", register_cols) GT 0  >
									<CFQUERY name="first_location" datasource="#db.connect#" timeout="#db.timeout#">
										select	top 1 key_sched, rtrim(city) as city,
											rtrim(state) as state
	                    			    from class_sched, classrooms
	                     			    where fkey_class = #scheds.key_class#
	                     			    and fkey_classroom = key_classroom
										order by class_date
									</CFQUERY>

									<TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" >
										<CFOUTPUT>#first_location.city#<CFIF isdefined("first_location.city") and #len(first_location.city)# GT 0>, #first_location.state#
										<CFELSE>

											<CFIF scheds.loc_type EQ "Physical"><CFOUTPUT>#scheds.location#</CFOUTPUT>
											<CFELSEIF findnocase("location",register_cols) EQ 0><CFOUTPUT>#scheds.addr#</CFOUTPUT>
											</CFIF>&nbsp;

										</CFIF>
										</CFOUTPUT>&nbsp;
									</TD>
								</CFIF>
								<CFIF findnocase("start_date", register_cols) GT 0><TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" ><CFOUTPUT>#DateFormat(scheds.start_date,"MM/DD/YY")#</CFOUTPUT>&nbsp;</TD></CFIF>
								<CFIF findnocase("end_date", register_cols) GT 0><TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" ><CFOUTPUT>#DateFormat(scheds.end_date,"MM/DD/YY")#</CFOUTPUT>&nbsp;</TD></CFIF>

								<CFIF #findnocase("first_times", register_cols)# GT 0>
									<TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" >
										<CFQUERY name="first_times" datasource="#db.connect#" timeout="#db.timeout#">
											select	top 1 key_sched, start_time, end_time
		                    			    from class_sched
		                     			    where fkey_class = #scheds.key_class#
											order by class_date
										</CFQUERY>
										<CFOUTPUT>#timeformat(first_times.start_time, 'h:mm tt')# - #timeformat(first_times.end_time, 'h:mm tt')#</CFOUTPUT>
									</TD>
								</CFIF>

								<CFIF #findnocase("schedule", register_cols)# GT 0><TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" ><CFOUTPUT>#scheds.schedule#</CFOUTPUT>&nbsp;</TD></CFIF>


								<TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" width=60 align=center><CFIF #CURR_LEVEL# GTE #MAX_LEVEL#><FONT class="mainalt">@getmsg(APP_FULL)</FONT><CFELSE>@GetMsg(APP_AVAILABLE)</CFIF>

								<CFIF findnocase("price", register_cols) GT 0 and THIS_GRP IS 0> <!--- if bundle do not show price --->

									<CFSET mylocale=SetLocale(use_currency_locale) >
									<TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" width=60 align=center>
											<CFOUTPUT>#lsCurrencyFormat(scheds.final_price,use_currency_format)#</CFOUTPUT>
									</TD>
								</CFIF>

								<!--- CRF 1-25-2007, added a new column to be displayed showing the number of students that
	                            can sign up and the number that HAVE signed up.   if the class is 90% or more full,
	                            it also turns bolds the info and turns it red --->
								<cfif findnocase("current-max", register_cols) GT 0>
									<TD class="<CFOUTPUT>#CLS#</CFOUTPUT>" width=60 align=center>
									   <cfif CURR_LEVEL GTE MAX_LEVEL>
										   <strong><font color="red">
											   Class Full
										   </font></strong>
			                           <cfelse>
			                              <cfoutput>#CURR_LEVEL# / #MAX_LEVEL#</cfoutput>
			                           </cfif>
									</TD>
								</cfif>

					</TR>

					<TR>
						<TD>&nbsp;</td>
						<TD colspan=<CFOUTPUT>#num_cols#</CFOUTPUT>-2>

						<CFSET url.sched=#first_times.key_sched#>
						<CFSET url.cls= #scheds.key_class#>

						<CFSET url.prg=#THIS_PRG_KEY#>


						<div class="expandable" style="width:100%;">
							<div class="title">@GETMSG(APP_Details)</div>
							<div class="content">

								<CFINCLUDE template="../widgets/training_cal_details.cfm">

							</div>
						</div>
						</td>

						<TD>&nbsp;</td>
					</TR>
						<CFIF NOT Compare(#CLS#,"subalt1")>
							<CFSET CLS = "subalt2">
						<CFELSE>
							<CFSET CLS = "subalt1">
						</CFIF>
						<CFSET CTR = CTR + 1>
					</CFIF>

				</CFLOOP>

			</TABLE>

				<CFIF ANY_AVAIL EQ 0>

					<span class="message">@getmsg(REG_NoClassesFit)</span>
				</CFIF>

		</CFIF>
	</cfloop>
	<CFRETURN true />
</CFFUNCTION>

<div class="container1">

<CFIF DO_SCHED EQ 1>
	<span class="pagetitle">@getmsg(APP_AvailClasses)</span>
	<BR><div id="contentareatitle"> @getmsg(REG_SelectAClass)</div>
	<BR><div id="contentareainstructions"> @Getmsg(REG_Select_Class_Conflict)</div>
</cfif>

<!--- show grouped events first (same bundle_id) --->
<CFSET show_individual_classes=1>


<FORM name="form1" action="../pagebuilder/showpage.cfm?pagedef=<CFOUTPUT>#cart_pagedef#</CFOUTPUT>&goto=apply_add_to_cartR&<CFOUTPUT>#URLTOKEN#</CFOUTPUT>" method="post">
	<INPUT type=hidden name="courses" value=<CFOUTPUT>"#CRSLST#"</CFOUTPUT>>
	<INPUT type=hidden name="grp" id="grp" value="<CFOUTPUT>#THIS_GRP#</CFOUTPUT>">

	<CFSET THE_RT = 1>
	<CFQUERY name="reg" datasource="#db.connect#"  timeout=#db.timeout#>
		select key_reg_type from registration_type where registration like '%regular%'
	</CFQUERY>
	<CFIF Len(#reg.key_reg_type#) GT 0 AND #reg.key_reg_type# GT 0>
		<CFSET THE_RT = #reg.key_reg_type#>
	</CFIF>
	<INPUT type=hidden name="selReg" id="selReg" value="<CFOUTPUT>#THE_RT#</CFOUTPUT>">

	<CFQUERY name="thisET" datasource="#db.connect#"  timeout=#db.timeout#>
		select fkey_exam_type from program_type where rtrim(program) = '#THIS_PRG#'
	</CFQUERY>
	<CFSET THE_EXAM = 0>
	<CFIF Len(#thisET.fkey_exam_type#) GT 0>
		<CFSET THE_EXAM = #thisET.fkey_exam_type#>
	</CFIF>

	<CFIF isdefined("catpar") AND LEN(catpar) GT 0>

		<input name="catpar" id="catpar" type="hidden" value="<CFOUTPUT>#catpar#</CFOUTPUT>" >
	</CFIF>

	<INPUT type=hidden name="selEx" id="selEx" value="<CFOUTPUT>#THE_EXAM#</CFOUTPUT>">
	<INPUT type=hidden name="reg_perm" id="reg_perm" value=<CFOUTPUT>#THIS_PERM#</CFOUTPUT>>
	<INPUT type=hidden name="price" id="price" value="<CFOUTPUT>#THIS_PRICE#</CFOUTPUT>">
	<INPUT type=hidden name="txtEnr" id="txtEnr" value="<CFOUTPUT>#THIS_PRG_KEY#</CFOUTPUT>">
	<CFIF IsDefined("URL.cls")><INPUT type=hidden name="clsGroup" id="clsGroup" value="<CFOUTPUT>#URL.cls#</CFOUTPUT>"></CFIF>

	<CFIF #THIS_GRP# GT 0>
	  <CFSET showEvents( ) >
	</CFIF>
<!--- <CFOUTPUT>#CRSLST# #THIS_GRP# #THIS_PRG#</CFOUTPUT> --->

	<cfif SHOW_INDIVIDUAL_CLASSES eq 1  >
		<CFSET showIndividualClasses()>

	</cfif>

	<CFIF DO_SCHED EQ 1>
		<table class="map">
		<TR>
			<CFIF ANY_AVAIL EQ 0 and FileExists(ExpandPath('#client.custom_path#/config/no_classes.cfm'))>
				<td><cfinclude template="#client.custom_path#/config/no_classes.cfm">
				</td>
			</cfif>
			<TD  align=right><BR>
			<cfoutput>


	<!--- case 58651 KC 1/30/15 cgi.http_referer is blank when accessed via ie with the catalog_presets.cfm addSelection()--->
		<INPUT type=submit class="btn" <CFIF ANY_AVAIL EQ 0 OR readonly EQ 1>disabled</CFIF> name="btnSave" value="@GETMSG(BTN_APPLY)" >&nbsp;
		<CFIF isDefined("url.pagedef") and url.pagedef EQ "signup">
			<INPUT type=button class="btn" name="btnClose"
				value=<CFIF readonly EQ 0>"@GETMSG(BTN_CANCEL)"<CFELSE>"@GETMSG(BTN_CLOSE)"</CFIF> onClick="window.close();" >
		<CFELSE>
			<CFIF isDefined("goto") and len(goto) GT 0>

				<CFSET goto="#CGI.http_referer#">

				<CFSET pstart = findnocase("pagedef=", CGI.http_referer ) + 8>

				<CFIF pstart GT 0>
					<CFSET pend = findnocase("&", CGI.http_referer, pstart ) >
					<CFIF pend EQ 0>
						<CFSET pend = len(cgi.http_referer) >
					</CFIF>

					<CFSET is_from = mid(cgi.http_referer,pstart,pend-pstart ) >

					<CFIF comparenocase(url.pagedef,is_from) NEQ 0>

						<CFSET client.page=is_from >

						<CFSET goto=replaceNoCase(goto,"pagedef="&url.pagedef, "pagedef="&is_from)  >

					<CFELSEIF len(client.page) GT 0>

						<CFSET goto=replaceNoCase(goto,"pagedef="&url.pagedef, "pagedef="&client.page)  >

					</CFIF>
 				</CFIF>

			<CFELSEIF find("?", catalog_page) GT 0>
				<CFSET goto = catalog_page & "&" & #URLTOKEN#& "&prog=" & #THIS_PRG_KEY#>
			<CFELSE>

				<CFSET goto = catalog_page & "?" & #URLTOKEN#& "&prog=" & #THIS_PRG_KEY#>
			</cfif>

			<INPUT type=button class="btn" name="btnClose" value="@GETMSG(BTN_CANCEL)" onClick="window.location.href='#goto#'" >
		</CFIF>

			</cfoutput>
		</TD></TR>
		</TABLE>
	</cfif>
</FORM>


</div>

<CFCATCH>
<CFOUTPUT>#cfcatch.message#<br>#cfcatch.detail#</cfoutput>
<CFDUMP var=#cfcatch#>
</cfcatch>
</cftry>

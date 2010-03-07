<cfcomponent displayname="mxunit.framework.TestResult" output="false" hint="Represents the results generated by TestCases. Data is stored as a ColdFusion structure and component has methods for transforming that data to HTML and XML. In General, you will not need to call most methods in this component. The primary ones you will use are: getResults(), getHtmlResults(), getJunitXmlResults(), getXmlResults()">
	<cfparam name="this.testRuns" type="numeric" default="0" />
	<cfparam name="this.testFailures" type="numeric" default="0" />
	<cfparam name="this.testErrors" type="numeric" default="0" />
	<cfparam name="this.testSuccesses" type="numeric" default="0" />
	<cfparam name="this.totalExecutionTime" type="numeric" default="0" />
	<cfparam name="this.package" type="string" default="mxunit.testresults" />
	<cfparam name="tempTestCase" type="any" default="" />
	<cfparam name="tempTestComponent" type="any" default="" />
	<cfparam name="this.results" type="array" default="#arrayNew(1)#" />
	<cfparam name="this.resultItem" type="struct" default="#structNew()#" />
	<cfparam name="this.resultItem.debug" type="array" default="#arrayNew(1)#" />
	
	<cfset this.resultItem.debug = arrayNew(1) />
	
	<!---
		Constructor
	--->
	<cffunction name="TestResult" access="public" returntype="TestResult" output="false">
		<cfset this.totalExecutionTime = getTickcount() />
		
		<cfreturn this />
	</cffunction>
	
	<cffunction name="closeResults" access="public" returntype="void" output="false">
		<cfset this.totalExecutionTime = getTickcount() - this.totalExecutionTime />
	</cffunction>
	
	<cffunction name="getJSONResults" access="public" returntype="any" output="false">
		<cfset closeResults() />
		
		<cfreturn serializeJSON(this.results)  />
	</cffunction>
	
	<cffunction name="getResults" access="public" returntype="array" output="false">
		<cfset closeResults() />
		
		<cfreturn this.results />
	</cffunction>
	
	<!--- Initialize the test result item struct each time and populate it with meta data --->
	<cffunction name="startTest" access="public" returntype="void" output="false">
		<cfargument name="testCase" type="any" required="yes" />
		<cfargument name="componentName" type="any" required="yes" />
		
		<cfscript>
			var tempTestCase = "";
			var tempTestComponent = "";
			
			this.resultItem = structNew();
			this.resultItem.trace = "" ;
			this.testRuns = this.testRuns + 1;
			
			tempTestCase = arguments.testCase ;
			tempTestComponent = arguments.componentName ;
			
			this.resultItem.number = this.testRuns;
			this.resultItem.component = tempTestComponent;
			this.resultItem.testname = tempTestCase;
			this.resultItem.dateTime = dateFormat(now(),"mm/dd/yyyy") & " " &  timeFormat(now(),"medium");
			this.resultItem.expected = "";
			this.resultItem.actual = "";
			
			this.debug = arrayNew(1);
		</cfscript>
	</cffunction>
	
	<!--- Add the test result item to the test results array --->
	<cffunction name="endTest" access="public" returntype="any" output="false">
		<cfargument name="testCase" type="any" required="yes" />
		
		<cfset arrayAppend(this.results, this.resultItem) />
	</cffunction>
	
	<!--- If anything goes wrong, capture the entire exception. --->
	<cffunction name="addError" access="public" returntype="void" output="false">
		<cfargument name="exception" type="any" required="yes" />
		
		<cfscript>
			this.resultItem.error = arguments.exception;
			this.resultItem.testStatus = 'Error';
			
			this.testErrors = this.testErrors + 1;
			this.resultItem.content = "";
		</cfscript>
	</cffunction>
	
	<cffunction name="addFailure" access="public" returntype="void" output="false">
		<cfargument name="exception" type="any" required="yes" />
		
		<cfscript>
			this.resultItem.error = arguments.exception;
			this.resultItem.testStatus = 'Failed';
			this.testFailures = this.testFailures + 1;
			this.resultItem.content = "";
		</cfscript>
	</cffunction>
	
	<!--- If the item beiong tested OR the test case itself generates any content, capture that. --->
	<cffunction name="addContent" access="public" returntype="void" output="false">
		<cfargument name="content" type="any" required="yes" />
		
		<cfset this.resultItem.content = arguments.content />
	</cffunction>
	
	<!---
		Should only be called once by TestSuite in order to add the debug array generated by TestCase.
	--->
	<cffunction name="setDebug" access="public" returntype="void" output="false">
		<cfargument name="debugData" type="Any" required="true"/>
		
		<!--- TODO Should be injectable setComponentUtil() what about a Guice like thing? ---> 
		<cfset var cUtil = createObject("component","ComponentUtils") />
		
		<cfif cUtil.isCfc(arguments.debugData)>
			<cfset this.resultItem.debug = getMetaData(arguments.debugData) />
		<cfelse>
			<cfset this.resultItem.debug = duplicate(arguments.debugData) />
		</cfif>
	</cffunction>
	
	<cffunction name="getDebug" access="public" returntype="any" output="false">
		<cfreturn this.resultItem.debug />
	</cffunction>
	
	<!--- If the test passes, store that. --->
	<cffunction name="addSuccess" access="public" returntype="void" output="false">
		<cfargument name="message" type="string" required="yes" />
		
		<cfscript>
			this.resultItem.testStatus = arguments.message;
			this.resultItem.error = "";
			this.testSuccesses = this.testSuccesses + 1;
		</cfscript> 
	</cffunction>
	
	<!--- Store how long the test took. --->
	<cffunction name="addProcessingTime" access="public" returntype="void" output="false">
		<cfargument name="milliseconds" required="true" type="numeric" default="-1" />
		
		<cfset this.resultItem.time = arguments.milliseconds />
	</cffunction>
	
	<!---
		Add the string that was expected
	--->
	<cffunction name="addExpected" access="public" returntype="void" output="false">
		<cfargument name="expected" type="string" required="true" />
		
		<cfset this.resultItem.expected = arguments.expected />
	</cffunction>
	
	<!---
		Add the actual string
	--->
	<cffunction name="addActual" access="public" returntype="void" output="false">
		<cfargument name="actual" type="string" required="true" />
		
		<cfset this.resultItem.actual = arguments.actual />
	</cffunction>
	
	<!---
		Add any user defined trace messages to the results.
		TODO: Allow for multiple trace messages per test. Currently only one is allowed.
	--->
	<cffunction name="addTrace" access="public" returntype="void" output="false">
		<cfargument name="message" type="any" required="no" default="" />
		
		<cfset this.resultItem.trace =  this.resultItem.trace & message.toString() />
	</cffunction>
	
	<!---
		Merges any catastrophic errors (parse errors, etc) into the TestResults object
	--->
	<cffunction name="mergeErrorsIntoTestResult" access="public" returntype="void" output="false">
		<cfargument name="ErrorStruct" type="struct" required="true" />
		
		<cfset var key = "" />
		<cfset var a_debug = ArrayNew(1) />
		
		<cfloop collection="#ErrorStruct#" item="key">
			<cfset startTest(ListLast(key,"."),key) />
			<cfset a_debug[1] = ErrorStruct[key] />
			<cfset addError(ErrorStruct[key]) />
			<cfset addProcessingTime(0) />
			<cfset setDebug(a_debug) />
			<cfset endTest("") />
		</cfloop>
	</cffunction>
	
	<cffunction name="getFailures" returntype="Numeric" access="public" output="false">
		<cfreturn this.testFailures />
	</cffunction>
	
	<cffunction name="getSuccesses" returntype="Numeric" access="public" output="false">
		<cfreturn this.testSuccesses />
	</cffunction>
	
	<cffunction name="getErrors" returntype="numeric" access="public" output="false">
		<cfreturn this.testErrors />
	</cffunction>
	
	<!---
		Returns the error's tagcontext formatted as xml.
		
		TODO If we store the entire exception in the data structure, we might not need this below.
	--->
	<cffunction name="constructTagContextElements" access="public" returntype="string" output="false">
		<cfargument name="exception" type="any" />
		
		<cfset var tc = exception.tagcontext />
		<cfset var i = 1 />
		<cfset var xmlReturn = "" />
		<cfset var sep = createObject("java","java.lang.System").getProperty("file.separator") />
		<cfset var mxunitpath = "mxunit#sep#framework" />
		
		<cfoutput>
			<cfreturn getXMLResults() />
		</cfoutput>
		
		<cfreturn xmlReturn />
	</cffunction>
	
	<!---
		Convenience for getting the various output modes
		
		TODO Refactor this out of here... should instantiate the correct object from the runner, not in the base test case.
	--->
	<cffunction name="getResultsOutput" returntype="any" hint="" access="public" output="false">
		<cfargument name="mode" required="true" />
		
		<cfset arguments.mode = listLast(arguments.mode) />
		
		<cfswitch expression="#arguments.mode#">
			
			<cfcase value="html">
				<cfreturn getHTMLResults() />
			</cfcase>
			
			<cfcase value="rawhtml">
				<cfreturn getRawHTMLResults() />
			</cfcase>
			
			
			<cfcase value="xml">
				<cfreturn getXMLResults() />
			</cfcase>
			
			<cfcase value="junitxml">
				<cfreturn getJUnitXMLResults() />
			</cfcase>
			
			<cfcase value="json">
				<cfreturn getJSONResults() />
			</cfcase>
			
			<cfcase value="query">
				<cfreturn getQueryResults() />
			</cfcase>
			
			<cfcase value="array">
				<cfreturn getResults() />
			</cfcase>
			
			<cfcase value="text">
				<cfreturn getTextResults() />
			</cfcase>
			
			<cfdefaultcase>
				<cfreturn getHTMLResults() />
			</cfdefaultcase>
		</cfswitch>
	</cffunction>
	
	<!---
		Call this method to return preformatted Text.
	--->
	<cffunction name="getTextResults" returnType="string" output="false">
		<cfset var results = createObject("component", "TextTestResult").init(this) />
		
		<cfreturn results.getTextResults() />
	</cffunction>
	
	<!---
		Call this method to return preformatted HTML.
	--->
	<cffunction name="getHTMLResults" returnType="string" output="false">
		<cfset var htmlresult = createObject("component", "HtmlTestResult").HTMLTestResult(this) />
		
		<cfreturn htmlresult.getHtmlresults() />
	</cffunction>
	
	<!---
		Call this method to return _raw_ (unstylized) HTML.
	--->
	<cffunction name="getRawHTMLResults" returnType="string" output="false">
		<cfset var htmlresult = createObject("component", "HtmlTestResult").HTMLTestResult(this) />
		<cfreturn htmlresult.getRawHtmlResults() />
	</cffunction>
	
	<!---
		Call this method to return raw XML. You can then apply your own xsl.
	--->
	<cffunction name="getXMLResults" returnType="string" output="false">
		<cfset var xml = createObject("component", "XMLTestResult").XMLTestResult(this) />
		
		<cfreturn xml.getXMLresults() />
	</cffunction>
	
	<!---
		Call this method to return raw XML. You can then apply your own xsl.
	--->
	<cffunction name="getQueryResults" returnType="query" output="false">
		<cfset var q = createObject("component", "QueryTestResult").QueryTestResult(this) />
		
		<cfreturn q.getQueryResults() />
	</cffunction>
	
	<!---
		 Call this method to return JUnit style XML for Ant junitreport task.
	--->
	<cffunction name="getJUnitXMLResults" returnType="string" output="false">
		<cfset var xml = createObject("component", "JUnitXMLTestResult").JUnitXMLTestResult(this) />
		
		<cfreturn xml.getXMLresults() />
	</cffunction>
	
	<!---
		Returns results as a struct keyed on Component
	--->
	<cffunction name="getResultsAsStruct" returntype="struct" output="false">
		<cfset var s_results = StructNew() />
		<cfset var thisComponent = "" />
		<cfset var test = 1 />
		
		<cfloop from="1" to="#ArrayLen(this.results)#" index="test">
			<cfset thisComponent = this.results[test].Component />
			
			<cfif not StructKeyExists(s_results,thisComponent)>
				<cfset s_results[thisComponent] = ArrayNew(1) />
			</cfif>
			
			<cfset ArrayAppend(s_results[thisComponent],this.results[test]) />
		</cfloop>
		
		<cfreturn s_results />
	</cffunction>
	
	<cffunction name="setPackage" access="public" returntype="void" output="false">
		<cfargument name="package" type="string" required="true" />
		
		<cfset this.package = arguments.package />
	</cffunction>
	
	<cffunction name="getPackage" access="public" returntype="string" output="false">
		<cfreturn this.package />
	</cffunction>
	
	<cffunction name="normalizeQueryString" returntype="string" output="false">
		<cfargument name="URLScope" required="true" type="struct" hint="the URL scope" />
		<cfargument name="outputMode" required="true" type="string" hint="the output mode to append to the query string" />
		
		<cfset var qs = "" />
		<cfset var key = "" />
		
		<cfloop collection="#URLScope#" item="key">
			<cfif key neq "output">
				<cfset qs = listAppend(qs,"#lcase(key)#=#URLScope[key]#","&") />
			</cfif>
		</cfloop>
		
		<cfset qs = ListAppend(qs,"output=#outputMode#","&") />
		
		<cfreturn qs />
	</cffunction>
	
	<!---
		Attempts to discover the webroot installation of mxunit.
		
		Refactor to ComponentUtils and wrap this up
	--->
	<cffunction name="getInstallRoot" returnType="string" access="public" output="false">
		<cfargument name="fullPath" type="string" required="false" default="" hint="Used for testing, really." />
		
		<cfscript>
			var cUtil = createObject("component","ComponentUtils");
			
			return cUtil.getInstallRoot(arguments.fullPath);
		</cfscript>
	</cffunction>
</cfcomponent>

component extends="mxunit.framework.TestCase" {

	specs = {};
	runnableMethods = [];
	currentDescriptionContext = "";
	currentSpecContext = "";
	variables.actual = "";
	variables.expected = "";
	
	function getSpecs(){
		return specs;
	}
	
	function getRunnableMethods(){
		return runnableMethods;
	}
	
	/* BDD equivalents of setup/teardown, etc */
	function beforeAll(){}
	function afterAll(){}
	function before(){}
	function after(){}


	function describe( name, expectations="" ){
		if( isClosure( arguments.expectations ) ){
			specs[name] = {};
			variables.currentDescriptionContext = arguments.name;

			expectations();
		} else {
			throw("Description for #name# did not include a closure/function argument... ignoring");
		}

		variables.currentDescriptionContext = "";
		variables.currentSpecContext = "";
		return this;
	}

	function it( should, code ){
		//writeLog("inside it: should = #should#");
		variables.currentSpecContext = should;
		arrayAppend( runnableMethods, "#variables.currentDescriptionContext# : #should#");
		specs[ variables.currentDescriptionContext ][should] = { code = code, annotations = {} };
		return this;
	}
	
	function executeSpec( methodName, args="#{}#" ){
		//writeLog( "executing spec #methodName#" );
		var context = getSpecContextFromFullSpecName( methodName );
		var fn = context.code;
		var outputOfTest = "";

		savecontent variable="outputOfTest"{
			fn();
		}
		return outputOfTest;
	}
	
	private function getCurrentDescriptionContext(){
		writeLog("looking at currentDescriptionContext #variables.currentDescriptionContext#");
		return specs[ variables.currentDescriptionContext ];
	}
	
	private function getCurrentSpecContext(){
		var descContext = getCurrentDescriptionContext(); 
		writeLog("looking at currentSpecContext #variables.currentSpecContext#");
		return descContext[ variables.currentSpecContext ];
	}
	
	private function getSpecContextFromFullSpecName( methodName ){
		var desc = trim(listFirst( methodName, ":" ));
		var spec = trim(listLast( methodName, ":" ));
		return variables.specs[ desc ][ spec ];
	}
	
	/* expectations */
	
	function expect( value ){
		variables.actual = value;
		return this;
	}
	
	
	function toBeTrue( message = "" ){
		assertTrue( getActual(), message );
	}
	
	function toBeFalse( message = "" ){
		assertFalse( getActual(), message );
	}
	
	function toBe( expected, message = "" ){
		if( isObject( getActual() ) && isObject( expected ) ){
			assertSame( getActual(), expected, message );		
		} else {
			assertEqualsCase( getActual(), expected, message );
		}
	}
	
	function toNotBe( expected, message = "" ){
		if( isObject( getActual() ) && isObject( expected ) ){
			assertNotSame( getActual(), expected, message );		
		} else {
			assertNotEqualsCase( getActual(), expected, message );
		}
	}
	
	function toEqual( expected, message = ""  ){
		assertEquals( getActual(), expected, message );
	}
	
	function toNotEqual( expected, message = ""  ){
		assertNotEquals( getActual(), expected, message );
	}
	
	/* TestCase overrides which essentially Adapt a Spec into a TestCase */
	
	package function withAnnotation( annotationName, annotationValue ){
		var context = getCurrentSpecContext();
		context.annotations[ annotationName ] = annotationValue;
		
		return this;
	}
	
	function getAnnotation( methodName="", annotationname, defaultValue="" ){
		if( methodName eq "" ){
			return super.getAnnotation( argumentCollection = arguments );
		}
		
		var context = getSpecContextFromFullSpecName( methodName );
		
		if( structKeyExists( context.annotations, annotationName ) ){
			writeLog("w00000000000000000t");
			return context.annotations[ annotationName ];
		}
		return defaultValue;
	}
	
	function beforeTests(){
		beforeAll();
	}
	
	function setUp(){
		before( argumentCollection=arguments );
	}
	
	function tearDown(){
		after( argumentCollection=arguments );
	}
	
	function afterTests(){
		afterAll();
	}
	
	function invokeTestMethod( methodName, args="#{}#" ){
		return executeSpec( methodname, args );
	}
	
	function onMissingMethod( missingMethodName, missingMethodArguments ){
		
		if( missingMethodName.startsWith("with") ){
			return onMissingWithMethod( argumentCollection = arguments );
		}
		
		throw( "Spec.onMissingMethod: Unknown method #missingMethodName#" );
	}
	
	private function onMissingWithMethod(missingMethodName, missingMethodArguments){
		var annotationName = mid(missingMethodName, 5, len(missingMethodName) - 4);
		return withAnnotation( annotationName, missingMethodArguments[1] );
	}

}
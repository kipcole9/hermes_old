function _tks(account)  {
	this.version		= "0.5";
	var self = this;
	this.account 		= "";
	this.trackerHost	= "noexpectations.com.au";
	this.trackerImage	= "/tracker.gif";
	this.parameters 	= new Object;  // Parsed URL parameters
	// Default campaign parameter names; same as the Google Analytics
	// to easy compatibility for campaign tracking, especially if GA is
	// already installed and working
	this.campaignName 	= "utm_name";
	this.campaignSource = "utm_source";
	this.campaignMedium = "utm_medium";
	this.campaignContent = "utm_content";
	// This is the method that actually sends the tracking
	// request
	this.trackPageview = function() {
		params = []; i = 0; image = new Image(1, 1);
		url = location.protocol + '//' + (this.account || 'www') + '.' + this.trackerHost + this.trackerImage + "?";
		for (p in this.urlParams) {
			// Have to separate the next two functions
			// to work in IE7.  Sigh.
			f = this.urlParams[p]; value = f();
			if (value != 'undefined') params[i++] = p + '=' + value;
		};
		url = url + params.join('&');
		url = url + "&uver=" + this.version;
        image.src = url;
		return url;	
	};
	this.getScreenSize = function() {
		return screen.width + 'x' + screen.height;
	};
	this.getColorDepth = function() {
		return screen.colorDepth;
	};
	this.getLanguage = function() {
		return (navigator.language) ? navigator.language : navigator.userLanguage; 
	};
	this.getUserAgent = function() {
		return navigator.userAgent;
	};
	this.getUrl = function() {
		return escape(document.URL);
	};
	this.getPageTitle = function() {
		return escape(document.title);
	};
	this.getReferrer = function() {
		return escape(document.referrer);
	};
	this.getCampName = function() {
		return escape(parameters[self.campaignName]);
	};
	this.getCampSource = function() {
		return escape(parameters[self.campaignSource]);
	};
	this.getCampMedium = function() {
		return escape(parameters[self.campaignMedium]);
	};
	this.getCampContent = function() {
		return escape(parameters[self.campaignContent]);
	};
	this.getVisitor = function() {
		function createTdsv() {
			// Set for about 720 days, or about 2 years
			self.setCookie('_tdsv', newVisitorId(), 720);
			return self.getCookie('_tdsv');
		};
		function newVisitorId() {
			return self.getUuid(15);
		};
		return (self.getCookie('_tdsv') || createTdsv());
	};
	this.getSession = function() {
		function setTdsb(value) {
			// Session cookie set for 30 minutes
			self.setCookie('_tdsb', value, 0.5/24);
		};
		function currentSession() {
			var tdsb, tdsc;

			// If both cookies then we have an existing session.  Set the _tdsb cookie
			// again to extend the session further
			if ((tdsb = self.getCookie('_tdsb')) && (tdsc = self.getCookie('_tdsc'))) {
				setTdsb(tdsb);
				return tdsb;
			};
			return false;
		};
		function createNewSession() {
			tdsb = self.getCookie('_tdsb');
			tdsc = self.getCookie('_tdsc');

			if (!tdsb) {
				tdsb = getNewSessionId();
				setTdsb(tdsb);
			};
			// Session cookie deleted at end of browser session
			// Hence if missing then a new session must be started
			if (!tdsc) {
				tdsb = self.getCookie('_tdsb');
				self.setCookie('_tdsc', tdsb);
			};
			return tdsb;
		};
		function getNewSessionId() {
			return (new Date).getTime();
		};
		session = currentSession();
		if (!session) { session = createNewSession() };
		return session;
	};
	/*
		Copyright (c) Copyright (c) 2007, Carl S. Yestrau All rights reserved.
		Code licensed under the BSD License: http://www.featureblend.com/license.txt
		Version: 1.0.4
		http://www.featureblend.com/javascript-flash-detection-library.html
	*/
	this.getFlashVersion = function(){
	    var self = this;
	    self.installed = false;
	    self.raw = "";
	    self.major = -1;
	    self.minor = -1;
	    self.revision = -1;
	    self.revisionStr = "";
	    var activeXDetectRules = [
	        {
	            "name":"ShockwaveFlash.ShockwaveFlash.7",
	            "version":function(obj){
	                return getActiveXVersion(obj);
	            }
	        },
	        {
	            "name":"ShockwaveFlash.ShockwaveFlash.6",
	            "version":function(obj){
	                var version = "6,0,21";
	                try{
	                    obj.AllowScriptAccess = "always";
	                    version = getActiveXVersion(obj);
	                }catch(err){}
	                return version;
	            }
	        },
	        {
	            "name":"ShockwaveFlash.ShockwaveFlash",
	            "version":function(obj){
	                return getActiveXVersion(obj);
	            }
	        }
	    ];
	    /**
	     * Extract the ActiveX version of the plugin.
	     * 
	     * @param {Object} The flash ActiveX object.
	     * @type String
	     */
	    var getActiveXVersion = function(activeXObj){
	        var version = -1;
	        try{
	            version = activeXObj.GetVariable("$version");
	        }catch(err){}
	        return version;
	    };
	    /**
	     * Try and retrieve an ActiveX object having a specified name.
	     * 
	     * @param {String} name The ActiveX object name lookup.
	     * @return One of ActiveX object or a simple object having an attribute of activeXError with a value of true.
	     * @type Object
	     */
	    var getActiveXObject = function(name){
	        var obj = -1;
	        try{
	            obj = new ActiveXObject(name);
	        }catch(err){
	            obj = {activeXError:true};
	        }
	        return obj;
	    };
	    /**
	     * Parse an ActiveX $version string into an object.
	     * 
	     * @param {String} str The ActiveX Object GetVariable($version) return value. 
	     * @return An object having raw, major, minor, revision and revisionStr attributes.
	     * @type Object
	     */
	    var parseActiveXVersion = function(str){
	        var versionArray = str.split(",");//replace with regex
	        return {
	            "raw":str,
	            "major":parseInt(versionArray[0].split(" ")[1], 10),
	            "minor":parseInt(versionArray[1], 10),
	            "revision":parseInt(versionArray[2], 10),
	            "revisionStr":versionArray[2]
	        };
	    };
	    /**
	     * Parse a standard enabledPlugin.description into an object.
	     * 
	     * @param {String} str The enabledPlugin.description value.
	     * @return An object having raw, major, minor, revision and revisionStr attributes.
	     * @type Object
	     */
	    var parseStandardVersion = function(str){
	        var descParts = str.split(/ +/);
	        var majorMinor = descParts[2].split(/\./);
	        var revisionStr = descParts[3];
	        return {
	            "raw":str,
	            "major":parseInt(majorMinor[0], 10),
	            "minor":parseInt(majorMinor[1], 10), 
	            "revisionStr":revisionStr,
	            "revision":parseRevisionStrToInt(revisionStr)
	        };
	    };
	    /**
	     * Parse the plugin revision string into an integer.
	     * 
	     * @param {String} The revision in string format.
	     * @type Number
	     */
	    var parseRevisionStrToInt = function(str){
	        return parseInt(str.replace(/[a-zA-Z]/g, ""), 10) || self.revision;
	    };
	    /**
	     * Constructor, sets raw, major, minor, revisionStr, revision and installed public properties.
	     */
        if(navigator.plugins && navigator.plugins.length>0){
            var type = 'application/x-shockwave-flash';
            var mimeTypes = navigator.mimeTypes;
            if(mimeTypes && mimeTypes[type] && mimeTypes[type].enabledPlugin && mimeTypes[type].enabledPlugin.description){
                var version = mimeTypes[type].enabledPlugin.description;
                var versionObj = parseStandardVersion(version);
                self.raw = versionObj.raw;
                self.major = versionObj.major;
                self.minor = versionObj.minor; 
                self.revisionStr = versionObj.revisionStr;
                self.revision = versionObj.revision;
                self.installed = true;
            }
        }else if(navigator.appVersion.indexOf("Mac")==-1 && window.execScript){
            var version = -1;
            for(var i=0; i<activeXDetectRules.length && version==-1; i++){
                var obj = getActiveXObject(activeXDetectRules[i].name);
                if(!obj.activeXError){
                    self.installed = true;
                    version = activeXDetectRules[i].version(obj);
                    if(version!=-1){
                        var versionObj = parseActiveXVersion(version);
                        self.raw = versionObj.raw;
                        self.major = versionObj.major;
                        self.minor = versionObj.minor; 
                        self.revision = versionObj.revision;
                        self.revisionStr = versionObj.revisionStr;
                    }
                }
            }
        };
		if (self.installed) {
			return self.major + '.' + self.minor;
		} else {
			return '-';
		};
	};
	this.setCookie = function(name, value, daysToExpire) {  
		var expire = '';  
	    if (daysToExpire != undefined) {  
	      var d = new Date();  
	      d.setTime(d.getTime() + (86400000 * parseFloat(daysToExpire)));  
	      expire = '; expires=' + d.toGMTString();  
	    }  
	    return (document.cookie = escape(name) + '=' + escape(value || '') + expire);  
	};  
	this.getCookie = function(name) {  
	    var cookie = document.cookie.match(new RegExp(escape(name) + "\s*=\s*(.*?)(;|$)"));
	    return (cookie ? unescape(cookie[1]) : null); 
	};  
	this.eraseCookie = function(name) {  
	    var cookie = _tks.getCookie(name) || true;  
	    this.setCookie(name, '', -1);  
	    return cookie;  
	};  
	this.acceptCookie = function() {  
	    if (typeof navigator.cookieEnabled == 'boolean') {  
	      return navigator.cookieEnabled;  
	    }  
	    this.setCookie('_test', '1');  
	    return (this.eraseCookie('_test') === '1');  
	}; 	
	this.setCampName = function(name) {
		campaignName = name;
	};
	this.setCampSource = function(name) {
		campaignSource = name;
	};
	this.setCampMedium = function(name) {
		campaignMedium = name;
	};
	this.setCampContent = function(name) {
		campaignContent = name;
	};
	this.getUuid = function(len, radix) {
		var CHARS = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz'.split(''); 
	  	var chars = CHARS, uuid = [], rnd = Math.random;
	    radix = radix || chars.length;
	    if (len) {
	      // Compact form
	      for (var i = 0; i < len; i++) uuid[i] = chars[0 | rnd()*radix];
	    } else {
	      // rfc4122, version 4 form
	      var r;
	      // rfc4122 requires these characters
	      uuid[8] = uuid[13] = uuid[18] = uuid[23] = '-';
	      uuid[14] = '4';
	      // Fill in random data.  At i==19 set the high bits of clock sequence as
	      // per rfc4122, sec. 4.1.5
	      for (var i = 0; i < 36; i++) {
	        if (!uuid[i]) {
	          r = 0 | rnd()*16;
	          uuid[i] = chars[(i == 19) ? (r & 0x3) | 0x8 : r & 0xf];
	        };
	      };
	    };
	    return uuid.join('');
	};
	this.getUniqueRequest = function() {
		return self.getUuid(10, 10);
	};
	this.parseParameters = function(){
		var objURL = new Object();
		window.location.search.replace(
			new RegExp( "([^?=&]+)(=([^&]*))?", "g" ),

			// For each matched query string pair, add that
			// pair to the URL struct using the pre-equals
			// value as the key.
			function( $0, $1, $2, $3 ) {
				objURL[ $1 ] = $3;
			}
		);
		return objURL;
	};
	this.account = account;
	parameters = this.parseParameters();
	this.urlParams = {
		"utvis": this.getVisitor, "utses": this.getSession,
		"utmdt": this.getPageTitle,	"utmsr": this.getScreenSize, "utmsc": this.getColorDepth, 
		"utmul": this.getLanguage, "utmfl": this.getFlashVersion, "utmn": this.getUniqueRequest,
		"utm_campaign": this.getCampName, "utm_source": this.getCampSource,
		"utm_medium": this.getCampMedium, "utm_content": this.getCampContent,
		"utmp": this.getUrl
	};
};


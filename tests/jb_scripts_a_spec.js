describe("japbib Website", function(){
    var test_utils = window.test_utils = window.test_utils || {};

    function returnOneHTML(fileName){
        return returnNHTML.apply(this, [1, [fileName]])[0]; 
    }
    function returnNHTML(n, fileNames){
        expect(this.requests.length).to.equal(n);
        var results = [];
        for (var i = 0; i < n; i++) {
            var resultHandle = fixture.load(fileNames[i], true)[0];
            results.push(resultHandle.outerHTML);
            resultHandle.parentNode.removeChild(resultHandle);
            this.requests[i].respond(200, {"Content-Type": "text/html"}, results[i]);
        }  
        return results;
    }
    test_utils.returnOneHTML = returnOneHTML;
    test_utils.returnNHTML = returnNHTML;

    function returnOneError(code){
        return returnNError.apply(this, [1, [code]])[0];
    }
    function returnNError(n, codes) {
        expect(this.requests.length).to.equal(n);
        var results = []; 
        for (var i = 0; i < n; i++) {
            expect(codes[i]).to.be.a("number");
            results.push("<html><head><title>Error "+codes[i]+"</title></head><body>"+codes[i]+"</body></html>")
            this.requests[i].respond(codes[i], {"Content-Type": "text/html"}, results[i]);
        }
        return results;
    }
    test_utils.returnOneError = returnOneError;
    test_utils.returnNError = returnNError;

    function initFakeRequests() {        
        this.xhr = sinon.useFakeXMLHttpRequest(); 
        var requests = this.requests = [];
        this.xhr.onCreate = function(req) {
            requests.push(req);
        };
    }
    test_utils.initFakeRequests = initFakeRequests;

    function restoreRequests() {
        this.xhr.restore();
    }
    test_utils.restoreRequests = restoreRequests;
        
    function timeout(ms) {
        return new Promise(function(resolve, reject){
            setTimeout(function(){resolve();}, ms);
        });
    }
    test_utils.timeout = timeout;

    before(function(){
        // quick hack to disable loading any img or link tags
        __html__['index.htm'] = __html__['index.htm'].replace(/<(img|link).*>/g, '');
        var indexhtm = $(fixture.set(__html__['index.htm']));
        // now replace all "pointers" to index.htm parts with the actual HTML (in div tags)
        for (var file in __html__) {
          if(__html__.hasOwnProperty( file ) &&
             file !== 'index.htm' &&
             __html__[file].match(/<!--.*\s*index.htm(.*)\s*-->/g)){
            var partID = __html__[file].replace(/<!--.*\s*index.htm(.*)\s*-->/g, '$1'),
                part = indexhtm.find(partID),
                partAttributes = part.prop("attributes");
                wrapper = $('<div/>');
            $.each(partAttributes, function(){
                wrapper.attr(this.name, this.value);
            });
            wrapper.html(part.html());
            __html__[file] = $('<div/>').append(wrapper).html();
            // console.log(file + ": " +  $('<div/>').append(wrapper).html().substring(0,240));
          } 
        }
        fixture.cleanup();
        fixture.setBase('tests/fixtures');
    });

    describe("General behavoir", function(){

        beforeEach(function(){
            test_utils.initFakeRequests.apply(this);
        });

        it("Should have working assertions", function(){
            expect(false).to.be.false;
        });

        it("Should be able to get a fake result", function(){
            var get = $.get("sru?operation=fake&version=0.0&query=id=0002656&x-style='record2html.xsl'"),
                result = test_utils.returnOneHTML.apply(this, ['simpleResult.html']);
            // return timeout(3000)
            // .then(function(){
            // });
            return get
            .then(function( data, textStatus, jqXHR ) {
                expect(data).to.equal(result);
            });
        });

        afterEach(function(){
            test_utils.restoreRequests.apply(this);
        });
    });

    const expect = chai.expect;
})

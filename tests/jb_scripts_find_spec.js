describe("japbib Website", function(){
    describe("Find", function(){

        before(function(){
            fixture.setBase('tests/fixtures');
        });

        beforeEach(function(){
            fixture.load('findFixture.html');
            this.xhr = sinon.useFakeXMLHttpRequest(); 
            var requests = this.requests = [];
            this.xhr.onCreate = function(req) {
                requests.push(req);
            };
            jb_init();
            return timeout(10) // need a small timeout to settle (initial animations?)
            //  .then(function(){                 
            //  });
        });

        it("Should be able to get a fake result", function(){
            var get = $.get("sru?operation=searchRetrieve&version=1.2&query=id=0002656&x-style='record2html.xsl'"),
                result = returnOneHTML.apply(this, ['simpleResult.html']);
            // return timeout(3000)
            // .then(function(){
            // });
            return get
            .then(function( data, textStatus, jqXHR ) {
                expect(data).to.equal(result);
            });
        });

        function returnOneHTML(fileName){
            expect(this.requests.length).to.equal(1);
            var resultHandle = fixture.load(fileName, true)[0],
                result = resultHandle.outerHTML;
            resultHandle.parentNode.removeChild(resultHandle);
            this.requests[0].respond(200, {"Content-Type": "text/html"}, result);
            return result;
        }

        it("Should get a result on 'Freie Suche'", function(){

            var input = $('#searchInput1');
            expect(input).to.be.visible;
            expect(input.val()).to.equal('');
            expect($('.content .showResults')).to.be.not.visible; 
            input.val('Test');
            expect(input.val()).to.equal('Test');
            input.trigger(jQuery.Event('keypress', {which: 13}));
            returnOneHTML.apply(this, ['fullResult.html']);
            return timeout(10)
            .then(function(){
            expect($('.content .showResults')).to.be.visible;
            // chai-jquery .to.exist is broken because there seem to be two different jQueries here.
            expect($('#showList .showOptions ~ ol').length).to.be.above(0, 'There should be some results');
            // return timeout(1000)
            // .then(function(){
            // });
            });
        });

        afterEach(function(){
            fixture.cleanup();
            this.xhr.restore();
        });
    });
    const expect = chai.expect;
    
    function timeout(ms) {
        return new Promise(function(resolve, reject){
            setTimeout(function(){resolve();}, ms);
        });
    }
})
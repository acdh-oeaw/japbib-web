describe("japbib Website", function(){
    var test_utils = window.test_utils = window.test_utils || {};

    describe("Find", function(){

        CodeMirrorDummy = {fromTextArea: function(){}}

        beforeEach(function(){
            fixture.load('findFixture.html');
            test_utils.initFakeRequests.apply(this);
            jb_init(jQuery, CodeMirrorDummy, undefined, undefined, URI);
        });

        it("Should show a result on 'Freie Suche'", function(){

            var input = $('#searchInput1');
            expect(input).to.be.visible;
            expect(input.val()).to.equal('');
            expect($('.content .showResults')).to.be.not.visible;
            input.val('Test');
            expect(input.val()).to.equal('Test');
            input.trigger(jQuery.Event('keypress', {which: 13}));
            test_utils.returnOneHTML.apply(this, ['fullResult.html']);
            expect($('.content .showResults')).to.be.visible;
            // chai-jquery .to.exist is broken because there seem to be two different jQueries here.
            expect($('#showList .showOptions ~ ol').length).to.be.equal(1, 'There should be one result list');
        });

        it("Should show the result template if there is no actual sru endpoint", function(){
            var input = $('#searchInput1');
            expect(input).to.be.visible;
            expect(input.val()).to.equal('');
            expect($('.content .showResults')).to.be.not.visible;
            input.val('Test');
            expect(input.val()).to.equal('Test');
            input.trigger(jQuery.Event('keypress', {which: 13}));
            test_utils.returnOneError.apply(this, [404]);
            expect($('.content .showResults')).to.be.visible;
            // chai-jquery .to.exist is broken because there seem to be two different jQueries here.
            expect($('.ajax-error.c400').length).to.equal(1, 'There should be an error message');
            expect($('#showList .showOptions ~ ol').length).to.equal(1, 'There should be one result list');
        });

        it("Should show a good error message if the search result is fetched multiple times", function(){
            var input = $('#searchInput1');
            expect(input).to.be.visible;
            expect(input.val()).to.equal('');
            expect($('.content .showResults')).to.be.not.visible;
            input.val('Test');
            expect(input.val()).to.equal('Test');
            jb80.doSearchOnReturn();
            expect(jb80.doSearchOnReturn).to.throw(Error, undefined, 'Second should throw an error!');
            expect(jb80.doSearchOnReturn).to.throw(Error, undefined, 'Third should throw an error!');
            test_utils.returnOneError.apply(this, [404]);
            expect($('.ajax-error.concurrency').length).to.equal(1, 'There should be an error message');
            expect($('.ajax-error pre').length).to.equal(3, 'There should be the original stack trace and 2 printed errors!');     
        });

        afterEach(function(){
            fixture.cleanup();
            test_utils.restoreRequests.apply(this);
        });
    });
    const expect = chai.expect;
})
describe("japbib Website", function(){
    var test_utils = window.test_utils = window.test_utils || {};

    describe("Find", function(){

        beforeEach(function(){
            fixture.load('findFixture.html');
            test_utils.initFakeRequests.apply(this);
            jb_init();
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
            expect($('#showList .showOptions ~ ol').length).to.be.equal(1, 'There should be one result list');
        });

        afterEach(function(){
            fixture.cleanup();
            test_utils.restoreRequests.apply(this);
        });
    });
    const expect = chai.expect;
})
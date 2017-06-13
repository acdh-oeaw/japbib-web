describe("japbib Website", function(){
    var test_utils = window.test_utils = window.test_utils || {};

    describe("Find", function(){

        beforeEach(function(){
            fixture.load('findFixture.html');
            test_utils.initFakeRequests.apply(this);
            jb_init();
            return test_utils.timeout(10) // need a small timeout to settle (initial animations?)
            //  .then(function(){                 
            //  });
        });

        it("Should get a result on 'Freie Suche'", function(){

            var input = $('#searchInput1');
            expect(input).to.be.visible;
            expect(input.val()).to.equal('');
            expect($('.content .showResults')).to.be.not.visible;
            input.val('Test');
            expect(input.val()).to.equal('Test');
            input.trigger(jQuery.Event('keypress', {which: 13}));
            test_utils.returnOneHTML.apply(this, ['fullResult.html']);
            return test_utils.timeout(10)
            .then(function(){
            expect($('.content .showResults')).to.be.visible;
            // chai-jquery .to.exist is broken because there seem to be two different jQueries here.
            expect($('#showList .showOptions ~ ol').length).to.be.above(0, 'There should be some results');
            // return test_utils.test_utils.timeout(1000)
            // .then(function(){
            // });
        });
        });

        afterEach(function(){
            fixture.cleanup();
            test_utils.restoreRequests.apply(this);
        });
    });
    const expect = chai.expect;
})
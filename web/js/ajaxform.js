// This will load forms with CSS class "ajaxform" via ajax and place the answer into a div with id "results"
$(document).ready(function(){
    $('.ajaxform button').click(function(e){
        e.preventDefault();
        $.ajax({
            "url" : $('.ajaxform').attr("action") + "?" + $('.ajaxform').serialize(),
            beforeSend : function () {
                $("body").css("cursor", "wait");
            },
            done : function () {
                $("body").css("cursor", "auto");
            },
            success : function (res) {
                var oSerializer = new XMLSerializer();
                var doc = oSerializer.serializeToString(res);
                $('#results').html(doc);
                $("body").css("cursor", "auto");
            },
            error : function (res) {
                window.alert(res.statusText);
                $("body").css("cursor", "auto");
            }
        })        
    })
});
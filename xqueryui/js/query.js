var editor = ace.edit("editor");
var results = ace.edit("results");
editor.getSession().setMode("ace/mode/xquery");
results.getSession().setMode("ace/mode/xml");

var query = function(url, data) {
    $.ajax({
            method : "POST",
            url : url,
            data : data,
            dataType : "json",
            contentType : false,
            beforeSend : function(){
                $(".fa-spinner").show();
            },
            success: function(data, textStatus, jqXHR){
                $(".fa-spinner").hide();
                var xml = data[4][1],
                    max = parseInt(data[3][1]),
                    totalRecords = parseInt(data[1][1]),
                    startAt = parseInt(data[2][1]);
                    console.log("max=" + max + " total=" + totalRecords + " startAt=" + startAt);
                results.setValue(xml ? xml : "", 1);
                results.scrollToLine(0);
                results.scrollToRow(0);
                $('#results-meta').html("Showing ".concat((totalRecords < max) ? totalRecords : max) + " of " + totalRecords + " hits, starting at " + startAt + ".");
                if (startAt > 1) {
                    var startAtNew = startAt - max > 1 ? startAt - max : 1;
                    $('#results-meta').append("&#160;<a href='?startAt=" + startAtNew + "' data-goto='" +  startAtNew + "'>Prev</a>");
                }
                if (startAt + max < totalRecords) {
                    var startAtNew = parseInt(startAt) + parseInt(max);
                    $('#results-meta').append("&#160;<a href='?startAt=" + startAtNew + "' data-goto='" + startAtNew + "'>Next</a>");
                }
            },
            error: function(data, textStatus, jqXHR){
                $('#results-meta').html();
                $(".fa-spinner").hide();
                results.setValue(data.responseText, 1);
            }
        });
}; 

$(document).ready(function(){
    $("#query-form button[type = submit]").click(function(e){
        e.preventDefault();
        $('#query-form').find("input[name = startAt]").val(1);
        $(e.target).submit();
    });
    $("#query-form").submit(function(e){
        e.preventDefault();
        var url = this.action + "?" + $("#query-form").serialize();
        var data = editor.getValue()
        query(url, data);
    });
    
    $('#results-meta').on('click', 'a[data-goto]', function(e){
        e.preventDefault();
        $('#query-form').find("input[name = startAt]").val($(e.target).attr("data-goto"));
        $('#query-form').submit();
    });
    
    $('.examples').on('click', 'a', function(e){
        e.preventDefault();
        var query = e.target.textContent.trim(); 
        if ($("select[name = db]").val() === "MODS") {
            query = "xquery version '3.0';\n\ndeclare default element namespace 'http://www.loc.gov/mods/v3';\n\n" + query;  
        }
        editor.setValue(query, 1);
    });
    
    $("#query-form select[name = db]").change(function(e){
        e.preventDefault();
        if ($(e.target).val() === 'MODS') {
            $('#MODS-examples').show();
            $('#LIDOS-examples').hide();
            editor.setValue(xqueryTop + "//mods", 1);
        } else {
            $('#MODS-examples').hide();
            $('#LIDOS-examples').show();
            editor.setValue("//Verfasser", 1);
        }
    });
    
    $(window).keydown(function (e) {
        if (e.ctrlKey && e.keyCode == 13) {
            e.preventDefault();
            var url = $('#query-form').attr("action") + "?" + $("#query-form").serialize();
            var data = editor.getValue()
            query(url, data);
        }
  });
    
    var url = $('#query-form').attr("action") + "?max=1&amp;startAt=1";
    var data = "//LIDOS-Dokument"
    query(url, data);
});
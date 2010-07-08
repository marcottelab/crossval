function load_gene_tooltip(id) {
    $.getJSON("/genes/" + id + ".json", function(data) {
        summary = "No summary";
        if (data.gene.summary != null) summary = data.gene.summary;
        $(".tooltip #st_" + id).html("<div class=\"container\"><dl><dt style=\"font-size: small;\">" + data.gene.symbol + "</dt><dd><a href=\"http://www.ncbi.nlm.nih.gov/gene/" + id
            + "\">NCBI</a>, <a href=\"/genes/" + id + "\">full record</a></dd></dl>\n<p style=\"float:left; clear:both; margin:0.4em;\">"
            + data.gene.full_name + "</p>\n<dl><dt style=\"display:none;\">Summary</dt><dd>" + summary
            + "</dd></dl>\n<dl><dt>Other symbols</dt><dd>" + data.gene.synonyms + "</dd></dl></div>");
    });
}

$(document).ready(function() {
    $("ul.gene_list li").each(
        function() {
            var gene = $(this);
            //gene.mouseover(function() {
//                alert($(".tooltip").html());
                //$(".tooltip").html("Gene is " + $(this).html());
//            });
            gene.tooltip({
                tip: '.tooltip', effect: 'fade',
                onShow: function() {
                    // Hide all others
                    $(".tooltip div:visible").hide();
                    
                    var id = this.getTrigger().html();
                    var gene_tip = $(".tooltip #st_" + id);

                    if (gene_tip.length == 0) {
                        $(".tooltip").html($(".tooltip").html() + "<div id=\"st_" + id + "\">Loading...</div>");
                        load_gene_tooltip(id);
                        //$(".tooltip #st_" + id).load("/genes/" + id + " .container");
                    } else if (gene_tip.html().length < 12) {
                        load_gene_tooltip(id);
                        //$(".tooltip #st_" + id).load("/genes/" + id + " .container");
                    }
                    $(".tooltip #st_" + id + " .container").show();
                    $(".tooltip #st_" + id).show();
                },
                onHide: function() {
                    //id = this.getTrigger().html();
                    $(".tooltip div:visible").hide();
                }
            });
        }
    );
});

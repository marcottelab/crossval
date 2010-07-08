function load_gene_tooltip(id) {
    $.getJSON("/genes/" + id + ".json", function(data) {
        summary = "No summary";
        if (data.gene.summary != null) summary = data.gene.summary;
        $(".tooltip #st-" + id).html("<h1><a href=\"/genes/" + id + "\">"
            + data.gene.symbol +"</a> <a href=\"http://www.ncbi.nlm.nih.gov/gene/"
            + id + "\">(NCBI)</a></h1>\n<dl class=\"container\">\n<dt>Name</dt><dd class=\"noline\">"
            + data.gene.full_name + "</dd>\n" + "<dt>Summary</dt><dd>" + summary
            + "</dd>\n<dt>Aliases</dt><dd>" + data.gene.synonyms + "</dd></dl>");
    });
}

function add_gene_tooltip_div(id) {
    tooltip = $(".tooltip");
    tooltip.html(tooltip.html() + "<div id=\"st-" + id + "\">Loading...</div>");
}

// Make sure the tooltip div exists (create/load if not)
function ensure_gene_tooltip_div(sel, id) {
    var gene_tip  = $(sel);
    if (gene_tip.length == 0) {
        add_gene_tooltip_div(id);
        load_gene_tooltip(id);
    } else if (gene_tip.html().length < 12) {
        load_gene_tooltip(id);
    }
}

$(document).ready(function() {
    $("ul.gene_list li").each(
        function() {
            $(this).tooltip({
                tip: '.tooltip', effect: 'fade',
                onShow: function() {
                    $(".tooltip div[id|=st]").hide();
                    var id = this.getTrigger().html();
                    var tooltip_s = ".tooltip #st-" + id;
                    ensure_gene_tooltip_div(tooltip_s, id);
                    $(tooltip_s).show();
                }
            });
        }
    );
});

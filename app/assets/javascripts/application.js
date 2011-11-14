// This is a manifest file that'll be compiled into including all the files listed below.
// Add new JavaScript/Coffee code in separate files in this directory and they'll automatically
// be included in the compiled file accessible from http://example.com/assets/application.js
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// the compiled file.
//
//= require jquery
//= require jquery_ujs
//= require_tree .

function add_source(element, source_name, new_source) {
  $('experiment_sources').insert({
    bottom: new_source.replace(/NEW_RECORD/g, new Date().getTime())
  });
}

function add_nested(element, nested_type, new_nested) {
  $(nested_type).insert({
    bottom: new_nested.replace(/NEW_RECORD/g, new Date().getTime())
  });
}

function remove_nested(nested_type, element) {
  var hidden_field = $(element).previous("input[type=hidden]");
  if (hidden_field) hidden_field.value = '1';
  $(element).up("."+nested_type).hide();
}

function remove_source(element) {
  var hidden_field = $(element).previous("input[type=hidden]");
  if (hidden_field) hidden_field.value = '1';
  $(element).up(".source").hide();
}

function remove_roc_group_item(element) {
  var hidden_field = $(element).previous("input[type=hidden]");
  if (hidden_field) hidden_field.value = '1';
  $(element).up(".roc_group_item").hide();
}

function showInfoBox(element) {
    $('ul.info').stop().hide();
    $(element).css("opacity", 1);
    $(element).fadeIn();
}


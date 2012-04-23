# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://jashkenas.github.com/coffee-script/
$ ->
  # Show or hide the extras form on create/edit boxes
  update_order_extras_collection = ->
    include_extras = $("#order_include_extras").prop("checked")
    if include_extras
      $("#order_extras").show()
    else
      $("#order_extras").hide()
  $("#order_include_extras").change(update_order_extras_collection)
  update_order_extras_collection()

  $("#order_submit").click ->
    include_extras = $("#order_include_extras").prop("checked")
    if !include_extras
      $("#order_extras input[type=number]").val(0) # Set all extras count to zero
    true

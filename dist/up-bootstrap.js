(function() {
  var defaults;

  defaults = up.layout.defaults();

  up.layout.defaults({
    fixedTop: defaults.fixedTop + ", .navbar-fixed-top",
    fixedBottom: defaults.fixedBottom + ", .navbar-fixed-bottom"
  });

}).call(this);
(function() {
  up.modal.defaults({
    template: "<div class=\"up-modal\">\n  <div class=\"up-modal-dialog modal-dialog\">\n    <div class=\"up-modal-content modal-content\"></div>\n  </div>\n</div>"
  });

}).call(this);
(function() {
  up.navigation.defaults({
    currentClass: 'active'
  });

}).call(this);
(function() {


}).call(this);

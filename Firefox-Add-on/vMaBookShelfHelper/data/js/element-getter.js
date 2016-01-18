self.port.on("getElements", function(tag) {
  var elements = document.getElementsByTagName(tag);
  for (var i = 0; i < elements.length; i++) {
    self.port.emit("gotElement", elements[i].innerHTML);
  }
});

self.port.on("getAnzahl", function(tag) {
    console.log( "element-getter.js self.port.on getAnzahl" + " tag: " + tag );
    var elements = document.getElementsByTagName(tag);
    self.port.emit("anzahlElemente", elements.length);
});

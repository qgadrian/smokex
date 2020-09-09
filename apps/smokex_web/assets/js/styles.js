document.getElementById("navbarBurger").addEventListener('click', function (e) {
  var dataTarget = e.target.getAttribute("data-target")
  var element = document.getElementById(dataTarget)
  element.classList.toggle("is-active")
}, false);

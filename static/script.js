/* PoemReason — Web Speech API vocalizer */

function falar(texto, lang) {
  if (!("speechSynthesis" in window)) {
    alert("Este navegador nao tem sintese de voz.");
    return;
  }
  speechSynthesis.cancel();
  var u = new SpeechSynthesisUtterance(texto);
  u.lang = lang || "pt-BR";
  u.rate = 0.92;
  u.pitch = 1;
  speechSynthesis.speak(u);
}

document.querySelectorAll(".dizer").forEach(function (b) {
  b.addEventListener("click", function () {
    falar(b.dataset.text, b.dataset.lang);
  });
});

document.getElementById("lerTudo").addEventListener("click", function () {
  if (!("speechSynthesis" in window)) return;
  speechSynthesis.cancel();
  document.querySelectorAll(".dizer").forEach(function (b) {
    var u = new SpeechSynthesisUtterance(b.dataset.text);
    u.lang = b.dataset.lang || "pt-BR";
    u.rate = 0.92;
    speechSynthesis.speak(u);
  });
});

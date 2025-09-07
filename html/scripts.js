
    let progress = 20;
    let active = false;
    let interval;

    const game = document.getElementById("game");
    const progressFill = document.getElementById("progress");

    function updateProgress() {
      progressFill.style.width = progress + "%";
    }

    function startGame() {
      progress = 20;
      updateProgress();
      active = true;
      game.style.display = "block";

      interval = setInterval(() => {
        if (!active) return;
        progress -= 2;
        if (progress <= 0) {
          progress = 0;
          failGame();
        }
        updateProgress();
      }, 300);
    }

    function winGame() {
      active = false;
      clearInterval(interval);
      fetch(`https://${GetParentResourceName()}/minigameResult`, {
        method: "POST",
        body: JSON.stringify({ success: true })
      });
      game.style.display = "none";
    }

    function failGame() {
      active = false;
      clearInterval(interval);
      fetch(`https://${GetParentResourceName()}/minigameResult`, {
        method: "POST",
        body: JSON.stringify({ success: false })
      });
      game.style.display = "none";
    }

    document.addEventListener("keydown", (e) => {
      if (!active) return;
      if (e.key.toUpperCase() === "E") {
        progress += 8;
        if (progress >= 100) {
          progress = 100;
          winGame();
        }
        updateProgress();
      }
    });

    window.addEventListener("message", (event) => {
      if (event.data.action === "open") startGame();
      if (event.data.action === "close") {
        game.style.display = "none";
        active = false;
        clearInterval(interval);
      }
    });

    updateProgress();
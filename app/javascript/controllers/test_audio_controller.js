import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["playButton"];

  connect() {
    this.updateAllIconsToPlay(); // 初期化時に全アイコンを再生ボタンに設定
  }

  updateAllIconsToPlay() {
    document.querySelectorAll(".audio-icon").forEach((icon) => {
      icon.classList.remove("fa-pause");
      icon.classList.add("fa-play");
    });
  }

  playPause(event) {
    const button = event.currentTarget;
    const audioId = button.dataset.audioId;
    const audio = document.getElementById(`audio-${audioId}`);
    const icon = document.getElementById(`audio-icon-${audioId}`);

    // ソースタイプの確認と変更
    const source = audio.querySelector("source");
    const canPlay = audio.canPlayType(source.type);

    if (canPlay === "") {
      console.error(`Cannot play type: ${source.type}`);
      source.type = "audio/mp4"; // 必要に応じて変更
      const newCanPlay = audio.canPlayType(source.type);

      if (newCanPlay === "") {
        console.error(`Cannot play type: ${source.type}`);
      } else {
        console.log(`Changed type to: ${source.type}`);
        // ソースタイプが変更された場合、オーディオを再ロード
        audio.load();
      }
    } else {
      console.log(`Can play type: ${source.type}`);
    }

    // すべての他の音声を停止し、そのアイコンを更新
    document.querySelectorAll("audio").forEach((a) => {
      if (a.id !== `audio-${audioId}` && !a.paused) {
        a.pause();
        this.updateIcon(
          document.getElementById(`audio-icon-${a.id.replace("audio-", "")}`),
          false // 他の音声アイコンを「再生」状態に戻す
        );
      } else if (a.id !== `audio-${audioId}` && a.paused) {
        // 再生されていない他の音声のアイコンも再生状態に戻す
        this.updateIcon(
          document.getElementById(`audio-icon-${a.id.replace("audio-", "")}`),
          false
        );
      }
    });

    // 音声が添付されていない場合はここで処理を終了
    if (!audio) {
      return;
    }

    // 音声の再生状態を切り替える
    if (audio.paused) {
      audio
        .play()
        .then(() => {
          this.updateIcon(icon, true);
          this.updateButtonColor(button, true); // クラスの変更を追加
        })
        .catch((error) => {
          console.error("Playback failed:", error);
          alert(`音声の再生に失敗しました: ${error.message}`);
          this.updateIcon(icon, false);
          this.updateButtonColor(button, false); // クラスの変更を追加
        });
    } else {
      audio.pause();
      this.updateIcon(icon, false);
      this.updateButtonColor(button, false); // クラスの変更を追加
    }

    audio.addEventListener("timeupdate", () => {
      this.updateCurrentTimeDisplay(audioId, audio.currentTime);
    });

    audio.addEventListener("ended", () => {
      this.updateCurrentTimeDisplay(audioId, 0);
      this.updateIcon(icon, false);
      this.updateButtonColor(button, false); // クラスの変更を追加
    });
  }

  updateIcon(icon, isPlaying) {
    icon.classList.toggle("fa-play", !isPlaying);
    icon.classList.toggle("fa-pause", isPlaying);
  }

  updateCurrentTimeDisplay(audioId, currentTime) {
    const currentElem = document.getElementById(`current-time-${audioId}`);
    if (currentElem) {
      currentElem.textContent = this.formatTime(currentTime);
    }
  }

  formatTime(time) {
    const minutes = Math.floor(time / 60);
    const seconds = Math.floor(time % 60);
    return `${minutes.toString().padStart(2, "0")}:${seconds
      .toString()
      .padStart(2, "0")}`;
  }

  updateButtonColor(button, isPlaying) {
    if (isPlaying) {
      button.classList.add("text-sky-400-accent");
      button.classList.remove("text-blue-500");
    } else {
      button.classList.remove("text-sky-400-accent");
      button.classList.add("text-blue-500");
    }
  }
}

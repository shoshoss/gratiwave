import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    document.addEventListener(
      "turbo:frame-load",
      this.updateActiveLink.bind(this)
    );
    this.updateActiveLink();
    this.updateUnreadNotifications(); // 初期の未読通知数を設定
  }

  disconnect() {
    document.removeEventListener(
      "turbo:frame-load",
      this.updateActiveLink.bind(this)
    );
  }

  updateActiveLink() {
    const activeLinks = document.querySelectorAll(".active");
    activeLinks.forEach((link) =>
      link.classList.remove(
        "text-blue-500",
        "font-bold",
        "border-b-4",
        "border-sky-400-accent",
        "bg-white",
        "active"
      )
    );

    const links = document.querySelectorAll("a[data-corresponding-link-id]");
    links.forEach((link) => {
      const correspondingLinkId = link.getAttribute(
        "data-corresponding-link-id"
      );
      const correspondingLink = document.getElementById(correspondingLinkId);
      if (window.location.pathname === link.pathname) {
        link.classList.add(
          "text-blue-500",
          "font-bold",
          "border-b-4",
          "border-sky-400-accent",
          "bg-white",
          "active"
        );
        if (correspondingLink) {
          correspondingLink.classList.add("text-blue-500", "active");
        }
      }
    });
  }

  setActive(event) {
    event.preventDefault();

    const target = event.currentTarget;
    const url = new URL(target.href);
    const frame = document.querySelector("turbo-frame#main-content");

    if (frame) {
      frame.src = url.href;
      history.pushState({}, "", url.href);

      frame.addEventListener(
        "turbo:frame-load",
        () => {
          this.updateActiveLink();
          this.updateUnreadNotifications(); // 未読通知数を更新

          const correspondingLinkId = target.getAttribute(
            "data-corresponding-link-id"
          );
          const correspondingLink =
            document.getElementById(correspondingLinkId);
          if (correspondingLink) {
            correspondingLink.classList.add("text-blue-500", "active");
          }

          target.classList.add(
            "text-blue-500",
            "font-bold",
            "border-b-4",
            "border-sky-400-accent",
            "bg-white",
            "active"
          );
          window.scrollTo(0, 0);
        },
        { once: true }
      );
    }
  }

  async updateUnreadNotifications() {
    try {
      const response = await fetch("/notifications/unread_count", {
        cache: "no-store",
      });
      const data = await response.json();
      this.renderUnreadCount(data.unread_count);
    } catch (error) {
      console.error("Failed to fetch unread notifications count:", error);
    }
  }

  renderUnreadCount(count) {
    const unreadCountElement = document.getElementById(
      "unread-notifications-count"
    );
    if (unreadCountElement) {
      unreadCountElement.textContent = count;
      if (count > 0) {
        unreadCountElement.classList.remove("hidden");
      } else {
        unreadCountElement.classList.add("hidden");
      }
    }
  }
}

import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static values = { url: String }

  connect() {
    this.element.addEventListener('click', this.handleClick.bind(this))
  }

  disconnect() {
    this.element.removeEventListener('click', this.handleClick.bind(this))
  }

  handleClick(event) {
    // Check if the clicked element or any of its parents is an interactive element
    const interactiveSelectors = [
      'a',           // Links
      'button',      // Buttons
      'input',       // Input fields
      'textarea',    // Text areas
      'select',      // Select dropdowns
      '[onclick]',   // Elements with onclick handlers
      '[data-dropdown-toggle]', // Dropdown toggles
      '[data-dropdown-target]', // Dropdown targets
      '[data-action]', // Stimulus action elements
      '[data-no-post-click]', // Elements explicitly marked to prevent post navigation
      '.dropdown',   // Dropdown menus
      '.dropdown-menu',
      '.dropdown-content',
      '.youtube-embed',       // YouTube embeds
      '.tiktok-embed-wrapper', // TikTok embeds
      'svg',         // SVG elements (icons)
      'path'         // SVG paths
    ];

    // Check if the clicked element or any parent matches interactive selectors
    for (const selector of interactiveSelectors) {
      if (event.target.closest(selector)) {
        return; // Don't navigate to post, let the interactive element handle the click
      }
    }
    
    // Navigate to the post detail page
    if (this.urlValue) {
      window.location.href = this.urlValue;
    }
  }
}
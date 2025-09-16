import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  connect() {
    // Controller connected
  }

  loadForm() {
    // Only load the form when the modal is actually opened
    if (this.containerTarget.innerHTML === "") {
      fetch('/posts/new')
        .then(response => response.text())
        .then(html => {
          this.containerTarget.innerHTML = html;
        })
        .catch(error => {
          console.error('Error loading post form:', error);
          this.containerTarget.innerHTML = '<p class="text-red-500">Error loading form. Please try again.</p>';
        });
    }
  }

  getCSRFToken() {
    return document.querySelector('meta[name="csrf-token"]').getAttribute('content');
  }
}
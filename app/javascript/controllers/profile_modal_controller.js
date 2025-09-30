import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["form"]

  connect() {
    // Store bound event handler references
    this._handleKeydown = this.handleKeydown.bind(this)
    this._handleSubmitEnd = this.handleSubmitEnd.bind(this)

    // Add event listeners for keyboard events
    document.addEventListener('keydown', this._handleKeydown)

    // Listen for successful form submissions
    document.addEventListener('turbo:submit-end', this._handleSubmitEnd)
  }

  disconnect() {
    // Remove event listeners using stored references
    document.removeEventListener('keydown', this._handleKeydown)
    document.removeEventListener('turbo:submit-end', this._handleSubmitEnd)
  }

  open(event) {
    const modal = document.getElementById('profile-modal')
    if (modal) {
      modal.style.display = 'block'
      document.body.style.overflow = 'hidden'
    }
  }

  close() {
    const modal = document.getElementById('profile-modal')
    modal.style.display = 'none'
    document.body.style.overflow = 'auto'
  }

  stayOpen(event) {
    // Prevent modal from closing when clicking inside the modal content
    event.stopPropagation()
  }

  handleKeydown(event) {
    if (event.key === 'Escape') {
      this.close()
    }
  }

  handleSubmitEnd(event) {
    // Check if the form submission was successful and close modal
    if (event.detail.success && this.hasFormTarget && event.target === this.formTarget) {
      this.close()
      // Refresh the page to show updated username
      setTimeout(() => {
        window.location.reload()
      }, 100)
    }
  }
}

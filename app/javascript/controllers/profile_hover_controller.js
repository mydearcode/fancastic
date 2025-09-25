import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["card"]
  static values = { 
    username: String,
    delay: { type: Number, default: 500 },
    hideDelay: { type: Number, default: 300 }
  }

  connect() {
    this.hoverTimeout = null
    this.hideTimeout = null
    this.card = null
    this.isCardVisible = false
  }

  disconnect() {
    this.clearTimeouts()
    this.hideCard()
  }

  mouseEnter(event) {
    this.clearTimeouts()
    
    // Delay before showing card
    this.hoverTimeout = setTimeout(() => {
      this.showCard(event)
    }, this.delayValue)
  }

  mouseLeave(event) {
    this.clearTimeouts()
    
    // Delay before hiding card
    this.hideTimeout = setTimeout(() => {
      this.hideCard()
    }, this.hideDelayValue)
  }

  cardMouseEnter() {
    // Cancel hide timeout when mouse enters card
    this.clearTimeouts()
  }

  cardMouseLeave() {
    // Hide card when mouse leaves card
    this.hideTimeout = setTimeout(() => {
      this.hideCard()
    }, this.hideDelayValue)
  }

  async showCard(event) {
    if (this.isCardVisible) return
    
    try {
      const response = await fetch(`/api/users/${this.usernameValue}`)
      
      if (!response.ok) {
        if (response.status === 404) {
          return
        }
      }
      
      const userData = await response.json()
      this.createCard(userData, event)
      
    } catch (error) {
      // Silently handle errors
    }
  }

  createCard(userData, event) {
    if (this.card) {
      this.hideCard()
    }

    this.card = document.createElement('div')
    this.card.className = 'profile-hover-card fixed z-50 bg-black border border-gray-700 rounded-xl shadow-2xl p-4 w-80'
    this.card.innerHTML = this.createCardHTML(userData)
    
    // Add event listeners for mouse enter/leave on card
    this.card.addEventListener('mouseenter', () => this.cardMouseEnter())
    this.card.addEventListener('mouseleave', () => this.cardMouseLeave())
    
    // Add follow button event listener
    const followBtn = this.card.querySelector('.follow-btn')
    if (followBtn) {
      followBtn.addEventListener('click', (e) => this.handleFollowClick(e))
    }

    document.body.appendChild(this.card)
    this.positionCard(event)
    
    // Trigger show animation
    setTimeout(() => {
      this.card.classList.add('show')
    }, 10)
    
    this.isCardVisible = true
  }

  createCardHTML(userData) {
    const profilePictureUrl = userData.profile_picture_url || '/default-avatar.png'
    const isCurrentUser = userData.is_current_user
    const isFollowing = userData.is_following
    
    let followButtonHTML = ''
    if (!isCurrentUser) {
      const buttonText = isFollowing ? 'Takipten Çık' : 'Takip Et'
      const buttonClass = isFollowing 
        ? 'bg-transparent border border-gray-600 text-white hover:bg-red-600 hover:border-red-600' 
        : 'bg-blue-600 hover:bg-blue-700 text-white'
      
      followButtonHTML = `
        <button class="follow-btn px-4 py-2 rounded-full text-sm font-medium transition-colors ${buttonClass}"
                data-username="${userData.username}"
                data-following="${isFollowing}">
          ${buttonText}
        </button>
      `
    }

    let teamHTML = ''
    if (userData.team) {
      teamHTML = `
        <div class="flex items-center gap-2 mt-2">
          <div class="w-4 h-4 rounded-full flex-shrink-0" 
               style="background: linear-gradient(135deg, ${userData.team.color_primary}, ${userData.team.color_secondary});">
          </div>
          <span class="text-gray-400 text-sm">${userData.team.name}</span>
        </div>
      `
    }

    return `
      <div class="flex items-start gap-3">
        <!-- Profile Picture (Left) -->
        <div class="flex-shrink-0">
          <img src="${profilePictureUrl}" 
               alt="${userData.username}" 
               class="w-12 h-12 rounded-full object-cover">
        </div>
        
        <!-- Content (Right) -->
        <div class="flex-1 min-w-0">
          <!-- Names and Follow Button Row -->
          <div class="flex items-center justify-between gap-2 mb-1">
            <div class="min-w-0 flex-1">
              <h3 class="font-bold text-white text-sm truncate">${userData.full_name || userData.username}</h3>
              <p class="text-gray-400 text-sm">@${userData.username}</p>
            </div>
            ${followButtonHTML}
          </div>
          
          ${teamHTML}
          
          ${userData.bio ? `<p class="text-gray-300 text-sm mt-2 line-clamp-2">${userData.bio}</p>` : ''}
          
          <div class="flex gap-4 mt-3 text-sm text-gray-400">
            <span><strong class="text-white">${userData.following_count || 0}</strong> Takip</span>
            <span><strong class="text-white followers-count">${userData.followers_count || 0}</strong> Takipçi</span>
          </div>
        </div>
      </div>
    `
  }

  positionCard(event) {
    if (!this.card) return
    
    const rect = this.element.getBoundingClientRect()
    const cardRect = this.card.getBoundingClientRect()
    const viewportWidth = window.innerWidth
    const viewportHeight = window.innerHeight
    
    let left = rect.left + rect.width / 2 - cardRect.width / 2
    let top = rect.bottom + 10
    
    // Adjust horizontal position if card would go off screen
    if (left < 10) {
      left = 10
    } else if (left + cardRect.width > viewportWidth - 10) {
      left = viewportWidth - cardRect.width - 10
    }
    
    // Adjust vertical position if card would go off screen
    if (top + cardRect.height > viewportHeight - 10) {
      top = rect.top - cardRect.height - 10
    }
    
    this.card.style.left = `${left}px`
    this.card.style.top = `${top}px`
  }

  hideCard() {
    if (this.card) {
      this.card.remove()
      this.card = null
      this.isCardVisible = false
    }
  }

  clearTimeouts() {
    if (this.hoverTimeout) {
      clearTimeout(this.hoverTimeout)
      this.hoverTimeout = null
    }
    if (this.hideTimeout) {
      clearTimeout(this.hideTimeout)
      this.hideTimeout = null
    }
  }

  async handleFollowClick(event) {
    event.preventDefault()
    event.stopPropagation()
    
    const button = event.target
    const username = button.dataset.username
    const isFollowing = button.dataset.following === 'true'
    
    if (!username) {
      console.error('Username not found in button dataset')
      return
    }
    
    // Disable button during request
    button.disabled = true
    
    try {
      const method = isFollowing ? 'DELETE' : 'POST'
      const url = `/${username}/follow`
      const response = await fetch(url, {
        method: method,
        headers: {
          'Content-Type': 'application/json',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]').getAttribute('content'),
          'Accept': 'application/json'
        }
      })
      
      if (!response.ok) {
        throw new Error('Follow request failed')
      }
      
      const data = await response.json()
      
      // Update button state
      button.dataset.following = data.following.toString()
      button.textContent = data.following ? 'Takipten Çık' : 'Takip Et'
      
      // Update button classes based on following state
      if (data.following) {
        button.className = 'follow-btn px-4 py-2 rounded-full text-sm font-medium transition-colors bg-transparent border border-gray-600 text-white hover:bg-red-600 hover:border-red-600'
      } else {
        button.className = 'follow-btn px-4 py-2 rounded-full text-sm font-medium transition-colors bg-blue-600 hover:bg-blue-700 text-white'
      }
      
      // Also update followers count if available in the card
      const followersCountElement = this.card.querySelector('.followers-count')
      if (followersCountElement && data.followers_count !== undefined) {
        followersCountElement.textContent = data.followers_count
      }
      
    } catch (error) {
      console.error('Error handling follow:', error)
      // Revert button state on error
      button.dataset.following = isFollowing.toString()
      button.textContent = isFollowing ? 'Takipten Çık' : 'Takip Et'
    } finally {
      button.disabled = false
    }
  }
}
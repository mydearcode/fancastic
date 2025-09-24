import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["textarea", "suggestions"]
  static values = { url: String }

  connect() {
    this.timeout = null
    this.currentRequest = null
    this.mentionStart = -1
    this.currentMention = ""
    this.selectedIndex = -1
    
    // Textarea'ya event listener'lar ekle
    this.textareaTarget.addEventListener('input', this.handleInput.bind(this))
    this.textareaTarget.addEventListener('keydown', this.handleKeydown.bind(this))
    
    // Dışarı tıklandığında önerileri gizle
    document.addEventListener('click', this.handleClickOutside.bind(this))
  }

  disconnect() {
    this.clearTimeout()
    this.abortRequest()
    document.removeEventListener('click', this.handleClickOutside.bind(this))
  }

  handleInput(event) {
    const textarea = event.target
    const cursorPosition = textarea.selectionStart
    const text = textarea.value
    
    // @ veya # karakterinden önceki pozisyonu bul
    let triggerStart = -1
    let triggerChar = null
    
    for (let i = cursorPosition - 1; i >= 0; i--) {
      if (text[i] === '@' || text[i] === '#') {
        // Trigger karakterinden önce boşluk veya satır başı olmalı
        if (i === 0 || text[i - 1] === ' ' || text[i - 1] === '\n') {
          triggerStart = i
          triggerChar = text[i]
          break
        }
      } else if (text[i] === ' ' || text[i] === '\n') {
        // Boşluk bulundu, trigger yok
        break
      }
    }
    
    if (triggerStart !== -1) {
      // Trigger karakterinden sonraki metni al
      const triggerText = text.substring(triggerStart + 1, cursorPosition)
      
      // Sadece harf, rakam ve _ karakterlerine izin ver
      if (/^[a-zA-Z0-9_]*$/.test(triggerText)) {
        this.mentionStart = triggerStart
        this.currentMention = triggerText
        this.triggerChar = triggerChar
        
        if (triggerText.length >= 1) {
          if (triggerChar === '@') {
            this.searchUsers(triggerText)
          } else if (triggerChar === '#') {
            this.searchHashtags(triggerText)
          }
        } else {
          this.hideSuggestions()
        }
      } else {
        this.hideSuggestions()
      }
    } else {
      this.hideSuggestions()
    }
  }

  handleKeydown(event) {
    if (!this.suggestionsVisible()) return
    
    const suggestions = this.suggestionsTarget.querySelectorAll('[data-mention-user]')
    
    switch (event.key) {
      case 'ArrowDown':
        event.preventDefault()
        this.selectedIndex = Math.min(this.selectedIndex + 1, suggestions.length - 1)
        this.updateSelection(suggestions)
        break
        
      case 'ArrowUp':
        event.preventDefault()
        this.selectedIndex = Math.max(this.selectedIndex - 1, -1)
        this.updateSelection(suggestions)
        break
        
      case 'Enter':
      case 'Tab':
        if (this.selectedIndex >= 0 && suggestions[this.selectedIndex]) {
          event.preventDefault()
          if (this.triggerChar === '@') {
            this.selectUser(suggestions[this.selectedIndex].dataset.mentionUser)
          } else if (this.triggerChar === '#') {
            this.selectHashtag(suggestions[this.selectedIndex].dataset.hashtag)
          }
        }
        break
        
      case 'Escape':
        event.preventDefault()
        this.hideSuggestions()
        break
    }
  }

  handleClickOutside(event) {
    if (!this.element.contains(event.target)) {
      this.hideSuggestions()
    }
  }

  searchHashtags(query) {
    this.clearTimeout()
    this.abortRequest()
    
    this.timeout = setTimeout(() => {
      this.performHashtagSearch(query)
    }, 200)
  }

  performHashtagSearch(query) {
    this.abortRequest()
    
    const url = new URL('/search', window.location.origin)
    url.searchParams.set('q', '#' + query)
    url.searchParams.set('tab', 'hashtags')
    url.searchParams.set('hashtag', 'true')
    
    this.currentRequest = fetch(url, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.displayHashtagSuggestions(data.hashtags || [])
    })
    .catch(error => {
      if (error.name !== 'AbortError') {
        console.error('Hashtag search error:', error)
      }
    })
    .finally(() => {
      this.currentRequest = null
    })
  }

  displayHashtagSuggestions(hashtags) {
    if (!hashtags || hashtags.length === 0) {
      this.hideSuggestions()
      return
    }

    let html = '<div class="absolute bg-gray-900 border border-gray-700 rounded-lg shadow-lg z-50 max-h-60 overflow-y-auto min-w-64">'
    
    hashtags.forEach((hashtag, index) => {
      const isSelected = index === this.selectedIndex
      html += `
        <div class="flex items-center p-3 hover:bg-gray-800 cursor-pointer border-b border-gray-700 last:border-b-0 ${isSelected ? 'bg-gray-800' : ''}" 
             data-hashtag="${hashtag.name}"
             data-action="click->mention#selectHashtagFromClick">
          <div class="flex-shrink-0 w-8 h-8 bg-blue-600 rounded-full flex items-center justify-center mr-3">
            <span class="text-sm font-medium text-white">#</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-white truncate">
              #${hashtag.name}
            </p>
            <p class="text-xs text-gray-400 truncate">${hashtag.count || 0} posts</p>
          </div>
        </div>
      `
    })
    
    html += '</div>'
    this.suggestionsTarget.innerHTML = html
    this.showSuggestions()
    this.selectedIndex = -1
  }

  selectHashtagFromClick(event) {
    const hashtag = event.currentTarget.dataset.hashtag
    this.selectHashtag(hashtag)
  }

  selectHashtag(hashtag) {
    const textarea = this.textareaTarget
    const text = textarea.value
    const cursorPosition = textarea.selectionStart
    
    // Hashtag metnini seçilen hashtag ile değiştir
    const beforeHashtag = text.substring(0, this.mentionStart)
    const afterHashtag = text.substring(cursorPosition)
    const newText = beforeHashtag + '#' + hashtag + ' ' + afterHashtag
    
    textarea.value = newText
    
    // Cursor'u doğru pozisyona yerleştir
    const newCursorPosition = this.mentionStart + hashtag.length + 2
    textarea.setSelectionRange(newCursorPosition, newCursorPosition)
    
    // Focus'u textarea'ya geri ver
    textarea.focus()
    
    this.hideSuggestions()
  }

  searchUsers(query) {
    this.clearTimeout()
    this.abortRequest()
    
    this.timeout = setTimeout(() => {
      this.performSearch(query)
    }, 200)
  }

  performSearch(query) {
    this.abortRequest()
    
    const url = new URL('/search', window.location.origin)
    url.searchParams.set('q', query)
    url.searchParams.set('tab', 'people')
    url.searchParams.set('mention', 'true')
    
    this.currentRequest = fetch(url, {
      headers: {
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest'
      }
    })
    .then(response => response.json())
    .then(data => {
      this.displaySuggestions(data.users || [])
    })
    .catch(error => {
      if (error.name !== 'AbortError') {
        console.error('Mention search error:', error)
      }
    })
    .finally(() => {
      this.currentRequest = null
    })
  }

  displaySuggestions(users) {
    if (!users || users.length === 0) {
      this.hideSuggestions()
      return
    }

    let html = '<div class="absolute bg-gray-900 border border-gray-700 rounded-lg shadow-lg z-50 max-h-60 overflow-y-auto min-w-64">'
    
    users.forEach((user, index) => {
      const isSelected = index === this.selectedIndex
      html += `
        <div class="flex items-center p-3 hover:bg-gray-800 cursor-pointer border-b border-gray-700 last:border-b-0 ${isSelected ? 'bg-gray-800' : ''}" 
             data-mention-user="${user.username}"
             data-action="click->mention#selectUserFromClick">
          <div class="flex-shrink-0 w-8 h-8 bg-gray-700 rounded-full flex items-center justify-center mr-3">
            <span class="text-sm font-medium text-white">${user.username.charAt(0).toUpperCase()}</span>
          </div>
          <div class="flex-1 min-w-0">
            <p class="text-sm font-medium text-white truncate">
              ${user.full_name || user.username}
            </p>
            <p class="text-xs text-gray-400 truncate">@${user.username}</p>
          </div>
        </div>
      `
    })
    
    html += '</div>'
    this.suggestionsTarget.innerHTML = html
    this.showSuggestions()
    this.selectedIndex = -1
  }

  selectUserFromClick(event) {
    const username = event.currentTarget.dataset.mentionUser
    this.selectUser(username)
  }

  selectUser(username) {
    const textarea = this.textareaTarget
    const text = textarea.value
    const cursorPosition = textarea.selectionStart
    
    // Mention metnini kullanıcı adıyla değiştir
    const beforeMention = text.substring(0, this.mentionStart)
    const afterMention = text.substring(cursorPosition)
    const newText = beforeMention + '@' + username + ' ' + afterMention
    
    textarea.value = newText
    
    // Cursor'u doğru pozisyona yerleştir
    const newCursorPosition = this.mentionStart + username.length + 2
    textarea.setSelectionRange(newCursorPosition, newCursorPosition)
    
    // Focus'u textarea'ya geri ver
    textarea.focus()
    
    this.hideSuggestions()
  }

  updateSelection(suggestions) {
    suggestions.forEach((suggestion, index) => {
      if (index === this.selectedIndex) {
        suggestion.classList.add('bg-gray-800')
      } else {
        suggestion.classList.remove('bg-gray-800')
      }
    })
  }

  showSuggestions() {
    // Textarea'nın pozisyonuna göre önerileri konumlandır
    const textarea = this.textareaTarget
    const rect = textarea.getBoundingClientRect()
    
    this.suggestionsTarget.style.position = 'fixed'
    this.suggestionsTarget.style.top = `${rect.bottom + window.scrollY}px`
    this.suggestionsTarget.style.left = `${rect.left + window.scrollX}px`
    this.suggestionsTarget.style.width = `${Math.max(rect.width, 256)}px`
    
    this.suggestionsTarget.classList.remove('hidden')
  }

  hideSuggestions() {
    this.suggestionsTarget.classList.add('hidden')
    this.suggestionsTarget.innerHTML = ''
    this.selectedIndex = -1
  }

  suggestionsVisible() {
    return !this.suggestionsTarget.classList.contains('hidden')
  }

  clearTimeout() {
    if (this.timeout) {
      clearTimeout(this.timeout)
      this.timeout = null
    }
  }

  abortRequest() {
    if (this.currentRequest) {
      this.currentRequest.abort()
      this.currentRequest = null
    }
  }
}
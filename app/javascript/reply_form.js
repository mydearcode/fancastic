// Auto-expanding textarea functionality for reply forms
document.addEventListener('DOMContentLoaded', function() {
  initializeReplyForm();
});

// Also initialize when Turbo loads new content
document.addEventListener('turbo:load', function() {
  initializeReplyForm();
});

function initializeReplyForm() {
  const textarea = document.getElementById('reply_textarea');
  const charCount = document.getElementById('char_count');
  
  if (!textarea) return;
  
  // Auto-expand functionality
  function autoExpand() {
    // Reset height to auto to get the correct scrollHeight
    textarea.style.height = 'auto';
    
    // Calculate the number of lines
    const lineHeight = parseInt(window.getComputedStyle(textarea).lineHeight);
    const minRows = parseInt(textarea.dataset.minRows) || 1;
    const maxRows = parseInt(textarea.dataset.maxRows) || 6;
    
    // Calculate new height based on content
    const newHeight = Math.min(
      Math.max(textarea.scrollHeight, lineHeight * minRows),
      lineHeight * maxRows
    );
    
    textarea.style.height = newHeight + 'px';
    
    // Update character count if element exists
    if (charCount) {
      const currentLength = textarea.value.length;
      const maxLength = 280; // Twitter-like character limit
      charCount.textContent = `${currentLength}/${maxLength}`;
      
      // Change color based on character count
      if (currentLength > maxLength * 0.9) {
        charCount.classList.add('text-red-400');
        charCount.classList.remove('text-gray-500', 'text-yellow-400');
      } else if (currentLength > maxLength * 0.7) {
        charCount.classList.add('text-yellow-400');
        charCount.classList.remove('text-gray-500', 'text-red-400');
      } else {
        charCount.classList.add('text-gray-500');
        charCount.classList.remove('text-yellow-400', 'text-red-400');
      }
    }
  }
  
  // Expand on focus (simulate click behavior)
  textarea.addEventListener('focus', function() {
    if (textarea.rows === 1) {
      textarea.rows = 2;
      autoExpand();
    }
  });
  
  // Auto-expand as user types
  textarea.addEventListener('input', autoExpand);
  
  // Handle paste events
  textarea.addEventListener('paste', function() {
    setTimeout(autoExpand, 0);
  });
  
  // Initialize with current content
  autoExpand();
  
  // Handle image upload preview
  const imageInput = document.getElementById('reply_image_input');
  if (imageInput) {
    imageInput.addEventListener('change', function(e) {
      const file = e.target.files[0];
      if (file) {
        // Create preview (you can expand this functionality)
        console.log('Image selected:', file.name);
        
        // You could add image preview functionality here
        // For now, just show that an image is selected
        const imageButton = document.querySelector('button[onclick*="reply_image_input"]');
        if (imageButton) {
          imageButton.classList.add('text-blue-600');
          imageButton.title = `Selected: ${file.name}`;
        }
      }
    });
  }
}

// Handle form submission
document.addEventListener('submit', function(e) {
  if (e.target.closest('form[action*="reply"]')) {
    const textarea = document.getElementById('reply_textarea');
    if (textarea && textarea.value.trim() === '') {
      e.preventDefault();
      textarea.focus();
      return false;
    }
  }
});
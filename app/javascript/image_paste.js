// Image paste and preview functionality for post forms
document.addEventListener('DOMContentLoaded', function() {
  initializeImagePaste();
});

function initializeImagePaste() {
  const textareas = document.querySelectorAll('textarea[data-mention-target="textarea"]');
  
  textareas.forEach(textarea => {
    // Add paste event listener
    textarea.addEventListener('paste', handlePaste);
    
    // Create preview container if it doesn't exist
    createPreviewContainer(textarea);
  });
}

function handlePaste(event) {
  const items = event.clipboardData.items;
  
  for (let i = 0; i < items.length; i++) {
    const item = items[i];
    
    if (item.type.indexOf('image') !== -1) {
      event.preventDefault();
      
      const file = item.getAsFile();
      if (file) {
        handleImageFile(file, event.target);
      }
      break;
    }
  }
}

function handleImageFile(file, textarea) {
  // Validate file size (max 10MB)
  if (file.size > 10 * 1024 * 1024) {
    showError('Image must be less than 10MB');
    return;
  }
  
  // Validate file type
  const allowedTypes = ['image/jpeg', 'image/jpg', 'image/png', 'image/gif', 'image/webp'];
  if (!allowedTypes.includes(file.type)) {
    showError('Please upload a JPEG, PNG, GIF, or WebP image');
    return;
  }
  
  // Find the associated file input
  const form = textarea.closest('form');
  const fileInput = form.querySelector('input[type="file"][accept*="image"]');
  
  if (fileInput) {
    // Get existing files if any
    const existingFiles = Array.from(fileInput.files || []);
    
    // Create a new FileList with existing files plus the pasted file
    const dataTransfer = new DataTransfer();
    existingFiles.forEach(file => dataTransfer.items.add(file));
    dataTransfer.items.add(file);
    fileInput.files = dataTransfer.files;
    
    // Trigger change event to update any existing handlers
    fileInput.dispatchEvent(new Event('change', { bubbles: true }));
    
    // Show preview
    showImagePreview(file, textarea);
    
    // Show success message
    showSuccess('Image pasted successfully!');
  }
}

function createPreviewContainer(textarea) {
  const form = textarea.closest('form');
  let previewContainer = form.querySelector('.image-preview-container');
  
  if (!previewContainer) {
    previewContainer = document.createElement('div');
    previewContainer.className = 'image-preview-container mt-3 hidden';
    
    // Insert after textarea
    textarea.parentNode.insertBefore(previewContainer, textarea.nextSibling);
  }
}

function showImagePreview(file, textarea) {
  const form = textarea.closest('form');
  const previewContainer = form.querySelector('.image-preview-container');
  
  if (!previewContainer) return;
  
  const reader = new FileReader();
  reader.onload = function(e) {
    previewContainer.innerHTML = `
      <div class="relative inline-block">
        <img src="${e.target.result}" 
             class="max-w-full h-auto rounded-lg border border-gray-700 max-h-64 object-cover" 
             alt="Image preview">
        <button type="button" 
                class="absolute top-2 right-2 bg-red-600 hover:bg-red-700 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-bold transition-colors"
                onclick="removeImagePreview(this)">
          ×
        </button>
        <div class="mt-2 text-sm text-gray-400">
          ${file.name} (${formatFileSize(file.size)})
        </div>
      </div>
    `;
    previewContainer.classList.remove('hidden');
  };
  reader.readAsDataURL(file);
}

function removeImagePreview(button) {
  const previewContainer = button.closest('.image-preview-container');
  const form = button.closest('form');
  const fileInput = form.querySelector('input[type="file"][accept*="image"]');
  
  // Clear the file input
  if (fileInput) {
    fileInput.value = '';
    fileInput.dispatchEvent(new Event('change', { bubbles: true }));
  }
  
  // Hide preview
  previewContainer.classList.add('hidden');
  previewContainer.innerHTML = '';
}

function formatFileSize(bytes) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

function showError(message) {
  // Create or update error message
  let errorDiv = document.querySelector('.image-paste-error');
  
  if (!errorDiv) {
    errorDiv = document.createElement('div');
    errorDiv.className = 'image-paste-error fixed top-4 right-4 bg-red-600 text-white px-4 py-2 rounded-lg shadow-lg z-50';
    document.body.appendChild(errorDiv);
  }
  
  errorDiv.textContent = message;
  errorDiv.style.display = 'block';
  
  // Auto-hide after 3 seconds
  setTimeout(() => {
    errorDiv.style.display = 'none';
  }, 3000);
}

function showSuccess(message) {
  // Create or update success message
  let successDiv = document.querySelector('.image-paste-success');
  
  if (!successDiv) {
    successDiv = document.createElement('div');
    successDiv.className = 'image-paste-success fixed top-4 right-4 bg-green-600 text-white px-4 py-2 rounded-lg shadow-lg z-50';
    document.body.appendChild(successDiv);
  }
  
  successDiv.textContent = message;
  successDiv.style.display = 'block';
  
  // Auto-hide after 2 seconds
  setTimeout(() => {
    successDiv.style.display = 'none';
  }, 2000);
}

// Make removeImagePreview globally available
window.removeImagePreview = removeImagePreview;

// Re-initialize when new content is loaded via Turbo
document.addEventListener('turbo:load', initializeImagePaste);
document.addEventListener('turbo:frame-load', initializeImagePaste);
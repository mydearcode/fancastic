// Dropdown toggle functionality
function toggleDropdown(dropdownId) {
  const dropdown = document.getElementById(dropdownId);
  
  // Close all other dropdowns first
  document.querySelectorAll('[id^="post-options-"], [id^="repost-dropdown-"], [id^="conversation-options-"]').forEach(menu => {
    if (menu.id !== dropdownId && !menu.classList.contains('hidden')) {
      menu.classList.add('hidden');
    }
  });
  
  // Toggle the selected dropdown
  dropdown.classList.toggle('hidden');
  
  // Add click outside listener
  setTimeout(() => {
    if (!dropdown.classList.contains('hidden')) {
      document.addEventListener('click', function closeDropdown(e) {
        if (!dropdown.contains(e.target)) {
          dropdown.classList.add('hidden');
          document.removeEventListener('click', closeDropdown);
        }
      });
    }
  }, 10);
}

// Make the function globally available
window.toggleDropdown = toggleDropdown;